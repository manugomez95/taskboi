import assert from "node:assert/strict";
import test from "node:test";
import {
  createPinnedHttpsRequest,
  deliverWebhook,
  readHeaders,
  type RequestOnce,
} from "./delivery.ts";
import {
  type Dependencies,
  handleNotify,
  type ProjectRecord,
  type TaskRecord,
} from "./handler.ts";
import {
  isPublicIp,
  MAX_OUTGOING_PAYLOAD_BYTES,
  MAX_REQUEST_BYTES,
  MAX_RESPONSE_BYTES,
  SecurityError,
  timingSafeEqual,
  validateWebhookUrl,
} from "./security.ts";

const task: TaskRecord = {
  id: "11111111-1111-4111-8111-111111111111",
  title: "Canonical title",
  description: null,
  assigned_to: "hermes",
  priority: 2,
  project_id: "22222222-2222-4222-8222-222222222222",
  user_id: "33333333-3333-4333-8333-333333333333",
  created_at: "2026-01-01T00:00:00Z",
  updated_at: "2026-01-01T00:00:00Z",
};
const project: ProjectRecord = {
  id: task.project_id,
  user_id: task.user_id,
  name: "Owned",
  agent_webhook_url: "https://hooks.example.com/task",
};

function deps(overrides: Partial<Dependencies> = {}): Dependencies {
  return {
    secret: "database-only-secret",
    loadTask: async () => task,
    loadProject: async () => project,
    loadProfileWebhook: async () => null,
    deliver: async () => ({ status: 204 }),
    log: () => {},
    ...overrides,
  };
}
function request(
  secret = "database-only-secret",
  record: Record<string, unknown> = { id: task.id },
): Request {
  return new Request("https://function.example/notify-assignee", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-taskboi-webhook-secret": secret,
    },
    body: JSON.stringify({
      type: "INSERT",
      table: "tasks",
      schema: "public",
      record,
    }),
  });
}

test("rejects forged requests, including ordinary bearer JWTs", async () => {
  const forged = new Request("https://function.example", {
    method: "POST",
    headers: { authorization: "Bearer user-jwt" },
    body: "{}",
  });
  assert.equal((await handleNotify(forged, deps())).status, 401);
  assert.equal(
    (await handleNotify(request("wrong-secret"), deps())).status,
    401,
  );
});

test("compares webhook secrets without accepting length or encoding tricks", () => {
  assert.equal(timingSafeEqual("same-secret", "same-secret"), true);
  assert.equal(timingSafeEqual("same-secret", "same-secret-longer"), false);
  assert.equal(timingSafeEqual("", ""), true);
  assert.equal(timingSafeEqual("é", "e\u0301"), false);
});

test("bounds declared and streamed request bodies", async () => {
  const declared = request();
  declared.headers.set("content-length", String(MAX_REQUEST_BYTES + 1));
  assert.equal((await handleNotify(declared, deps())).status, 413);

  const streamed = new Request("https://function.example", {
    method: "POST",
    headers: { "x-taskboi-webhook-secret": "database-only-secret" },
    body: new ReadableStream({
      start(controller) {
        controller.enqueue(new Uint8Array(MAX_REQUEST_BYTES));
        controller.enqueue(new Uint8Array(1));
        controller.close();
      },
    }),
  });
  assert.equal((await handleNotify(streamed, deps())).status, 413);
});

test("reloads canonical fields and rejects cross-tenant ownership", async () => {
  let delivered: unknown;
  const response = await handleNotify(
    request(undefined, {
      id: task.id,
      user_id: "attacker",
      project_id: "attacker-project",
      title: "Spoofed",
    }),
    deps({
      deliver: async (_url, payload) => {
        delivered = payload;
        return { status: 200 };
      },
    }),
  );
  assert.equal(response.status, 200);
  assert.equal(
    (delivered as { task: TaskRecord }).task.title,
    "Canonical title",
  );
  assert.equal((delivered as { task: TaskRecord }).task.user_id, task.user_id);
  const denied = await handleNotify(
    request(),
    deps({
      loadProject: async () => ({
        ...project,
        user_id: "44444444-4444-4444-8444-444444444444",
      }),
    }),
  );
  assert.equal(denied.status, 403);
  const wrongProject = await handleNotify(
    request(),
    deps({
      loadProject: async () => ({ ...project, id: task.id }),
    }),
  );
  assert.equal(wrongProject.status, 403);
});

test("rejects malformed, credentialed, non-HTTPS, nonstandard-port and internal URLs", () => {
  for (
    const url of [
      "not a url",
      "http://example.com",
      "https://user:pass@example.com",
      "https://example.com:8443",
      "https://localhost/x",
      "https://127.0.0.1",
      "https://169.254.169.254/latest/meta-data",
      "https://10.0.0.1",
      "https://[::1]/",
      "https://[fe80::1]/",
      "https://[fc00::1]/",
    ]
  ) {
    assert.throws(() => validateWebhookUrl(url), SecurityError, url);
  }
  for (
    const ip of [
      "0.0.0.0",
      "100.64.0.1",
      "172.16.0.1",
      "192.168.1.1",
      "224.0.0.1",
      "240.0.0.1",
      "::",
      "::1",
      "ff02::1",
      "2001:db8::1",
      "::ffff:127.0.0.1",
    ]
  ) assert.equal(isPublicIp(ip), false, ip);
});

test("validates every redirect target and blocks redirect to metadata", async () => {
  const once: RequestOnce = async () => ({
    status: 302,
    headers: new Headers({
      location: "https://169.254.169.254/latest/meta-data",
    }),
  });
  await assert.rejects(
    deliverWebhook("https://hooks.example.com/start", {}, {
      resolve: async () => ["93.184.216.34"],
      requestOnce: once,
    }),
    SecurityError,
  );
});

test("re-resolves and pins every public redirect destination", async () => {
  const resolved: string[] = [];
  const contacted: string[] = [];
  const result = await deliverWebhook("https://one.example/start", {}, {
    resolve: async (hostname) => {
      resolved.push(hostname);
      return hostname === "one.example" ? ["93.184.216.34"] : ["142.250.74.78"];
    },
    requestOnce: async (url, address) => {
      contacted.push(`${url.hostname}|${address}`);
      return url.hostname === "one.example"
        ? {
          status: 307,
          headers: new Headers({ location: "https://two.example/final" }),
        }
        : { status: 204, headers: new Headers() };
    },
  });
  assert.deepEqual(result, { status: 204, redirects: 1 });
  assert.deepEqual(resolved, ["one.example", "two.example"]);
  assert.deepEqual(contacted, [
    "one.example|93.184.216.34",
    "two.example|142.250.74.78",
  ]);
});

test("rejects oversized canonical task payloads before DNS or network", async () => {
  let resolved = false;
  let requested = false;
  await assert.rejects(
    deliverWebhook("https://hooks.example/task", {
      event: "task.updated",
      task: { ...task, description: "x".repeat(MAX_OUTGOING_PAYLOAD_BYTES) },
      project: { id: project.id, name: project.name },
      resolved_webhook: "project",
    }, {
      resolve: async () => {
        resolved = true;
        return ["93.184.216.34"];
      },
      requestOnce: async () => {
        requested = true;
        return { status: 204, headers: new Headers() };
      },
    }),
    /payload too large/,
  );
  assert.equal(resolved, false);
  assert.equal(requested, false);
});

test("rejects private DNS answers and enforces the delivery deadline", async () => {
  let settled = false;
  await assert.rejects(
    deliverWebhook("https://hooks.example/task", {}, {
      resolve: async () => ["93.184.216.34", "127.0.0.1"],
      requestOnce: async () => ({ status: 204, headers: new Headers() }),
    }),
    /exclusively to public addresses/,
  );
  await assert.rejects(
    deliverWebhook("https://hooks.example/task", {}, {
      timeoutMs: 1,
      resolve: async () => ["93.184.216.34"],
      requestOnce: async (_url, _address, _body, signal) =>
        await new Promise((_resolve, reject) => {
          signal.addEventListener(
            "abort",
            () => {
              settled = true;
              reject(new DOMException("aborted", "AbortError"));
            },
            { once: true },
          );
        }),
    }),
    /delivery timed out/,
  );
  assert.equal(settled, true);
});

test("abort closes raw TCP while TLS establishment is pending", async () => {
  let tcpClosed = 0;
  let rejectTls!: (error: Error) => void;
  const tcp = {
    close() {
      tcpClosed++;
      rejectTls(new Error("TCP closed"));
    },
  } as unknown as Deno.TcpConn;
  const requestOnce = createPinnedHttpsRequest({
    connect: async () => tcp,
    startTls: async () =>
      await new Promise<Deno.TlsConn>((_resolve, reject) => {
        rejectTls = reject;
      }),
  });
  const controller = new AbortController();
  const pending = requestOnce(
    new URL("https://hooks.example/task"),
    "93.184.216.34",
    new Uint8Array(),
    controller.signal,
  );
  await Promise.resolve();
  controller.abort();
  await assert.rejects(pending, /TCP closed/);
  assert.equal(tcpClosed, 1);
});

test("abort closes both TLS and raw TCP connections and settles I/O", async () => {
  let tcpClosed = 0;
  let tlsClosed = 0;
  let rejectRead!: (error: Error) => void;
  let markReadStarted!: () => void;
  const readStarted = new Promise<void>((resolve) => markReadStarted = resolve);
  const tcp = { close: () => tcpClosed++ } as unknown as Deno.TcpConn;
  const tls = {
    close() {
      tlsClosed++;
      rejectRead(new Error("TLS closed"));
    },
    write: async (data: Uint8Array) => data.length,
    read: async () =>
      await new Promise<number | null>((_resolve, reject) => {
        rejectRead = reject;
        markReadStarted();
      }),
  } as unknown as Deno.TlsConn;
  const requestOnce = createPinnedHttpsRequest({
    connect: async () => tcp,
    startTls: async () => tls,
  });
  const controller = new AbortController();
  const pending = requestOnce(
    new URL("https://hooks.example/task"),
    "93.184.216.34",
    new Uint8Array(),
    controller.signal,
  );
  await readStarted;
  controller.abort();
  await assert.rejects(pending, /TLS closed/);
  assert.equal(tlsClosed, 1);
  assert.equal(tcpClosed, 1);
});

test("pins the validated public DNS address used for a valid delivery", async () => {
  let contacted = "";
  const once: RequestOnce = async (url, address) => {
    contacted = `${url.hostname}|${address}`;
    return { status: 204, headers: new Headers() };
  };
  const result = await deliverWebhook("https://hooks.example.com/task", {
    ok: true,
  }, { resolve: async () => ["93.184.216.34"], requestOnce: once });
  assert.deepEqual(result, { status: 204, redirects: 0 });
  assert.equal(contacted, "hooks.example.com|93.184.216.34");
});

test("rejects oversized responses without reading or logging their bodies", async () => {
  const response = new TextEncoder().encode(
    `HTTP/1.1 200 OK\r\nContent-Length: ${MAX_RESPONSE_BYTES + 1}\r\n\r\n`,
  );
  let read = false;
  const conn = {
    read: async (buffer: Uint8Array) => {
      if (read) return null;
      read = true;
      buffer.set(response);
      return response.length;
    },
  };
  await assert.rejects(readHeaders(conn), /response too large/);
});
