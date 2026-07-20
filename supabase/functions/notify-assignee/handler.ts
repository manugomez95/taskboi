import {
  MAX_REQUEST_BYTES,
  SecurityError,
  timingSafeEqual,
} from "./security.ts";

export interface TaskRecord {
  id: string;
  title: string;
  description: string | null;
  assigned_to: string;
  priority: number;
  project_id: string;
  user_id: string;
  created_at: string;
  updated_at: string;
}
export interface ProjectRecord {
  id: string;
  user_id: string;
  name: string;
  agent_webhook_url: string | null;
}
export interface Dependencies {
  secret: string;
  loadTask(id: string): Promise<TaskRecord | null>;
  loadProject(id: string): Promise<ProjectRecord | null>;
  loadProfileWebhook(userId: string): Promise<string | null>;
  deliver(url: string, payload: unknown): Promise<{ status: number }>;
  log(message: string, fields?: Record<string, unknown>): void;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });

async function readBoundedBody(req: Request): Promise<Uint8Array> {
  if (!req.body) return new Uint8Array();
  const reader = req.body.getReader();
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.length;
      if (length > MAX_REQUEST_BYTES) {
        await reader.cancel("request too large");
        throw new SecurityError("request too large", 413);
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const body = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.length;
  }
  return body;
}

export async function handleNotify(
  req: Request,
  deps: Dependencies,
): Promise<Response> {
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);
  const supplied = req.headers.get("x-taskboi-webhook-secret") ?? "";
  if (!deps.secret || !supplied || !timingSafeEqual(supplied, deps.secret)) {
    return json({ error: "unauthorized" }, 401);
  }
  const contentLengthHeader = req.headers.get("content-length");
  const contentLength = contentLengthHeader === null
    ? null
    : Number(contentLengthHeader);
  if (
    contentLength !== null &&
    (!Number.isSafeInteger(contentLength) || contentLength < 0 ||
      contentLength > MAX_REQUEST_BYTES)
  ) {
    return json({ error: "request too large" }, 413);
  }
  let bytes: Uint8Array;
  try {
    bytes = await readBoundedBody(req);
  } catch (error) {
    if (error instanceof SecurityError && error.status === 413) {
      return json({ error: "request too large" }, 413);
    }
    throw error;
  }
  let incoming: Record<string, unknown>;
  try {
    incoming = JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    return json({ error: "invalid JSON" }, 400);
  }
  if (
    !(["INSERT", "UPDATE"].includes(String(incoming.type))) ||
    incoming.table !== "tasks" ||
    (incoming.schema !== undefined && incoming.schema !== "public")
  ) return json({ error: "invalid database event" }, 400);
  const claimed = incoming.record;
  const taskId = typeof claimed === "object" && claimed !== null
    ? (claimed as Record<string, unknown>).id
    : null;
  if (
    typeof taskId !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(taskId)
  ) return json({ error: "invalid task id" }, 400);

  const task = await deps.loadTask(taskId);
  if (!task) return json({ skipped: true, reason: "task not found" });
  const project = await deps.loadProject(task.project_id);
  if (
    !project || project.id !== task.project_id ||
    project.user_id !== task.user_id
  ) {
    deps.log("Rejected inconsistent task ownership", { task_id: task.id });
    return json({ error: "record ownership mismatch" }, 403);
  }
  if (task.assigned_to === "manuel") {
    return json({ skipped: true, reason: "not assigned to agent" });
  }
  let webhookUrl = project.agent_webhook_url?.trim() ?? "";
  let resolved: "project" | "global" = "project";
  if (!webhookUrl) {
    webhookUrl = (await deps.loadProfileWebhook(task.user_id))?.trim() ?? "";
    resolved = "global";
  }
  if (!webhookUrl) {
    return json({ skipped: true, reason: "no webhook configured" });
  }

  const payload = {
    event: incoming.type === "INSERT" ? "task.assigned" : "task.updated",
    task,
    project: { id: project.id, name: project.name },
    resolved_webhook: resolved,
  };
  try {
    const result = await deps.deliver(webhookUrl, payload);
    if (result.status < 200 || result.status >= 300) {
      deps.log("Webhook returned non-success status", {
        task_id: task.id,
        status: result.status,
      });
      return json({
        success: true,
        notified: false,
        task_id: task.id,
        resolved_webhook: resolved,
      });
    }
    return json({
      success: true,
      notified: true,
      task_id: task.id,
      resolved_webhook: resolved,
    });
  } catch (error) {
    deps.log("Webhook delivery failed", {
      task_id: task.id,
      category: error instanceof SecurityError ? "policy" : "network",
    });
    return json({
      success: true,
      notified: false,
      task_id: task.id,
      resolved_webhook: resolved,
    });
  }
}
