import {
  DELIVERY_TIMEOUT_MS,
  MAX_OUTGOING_PAYLOAD_BYTES,
  MAX_REDIRECTS,
  MAX_RESPONSE_BYTES,
  resolvePublicAddresses,
  SecurityError,
  validateWebhookUrl,
} from "./security.ts";

interface RawResponse {
  status: number;
  headers: Headers;
}
export type RequestOnce = (
  url: URL,
  address: string,
  body: Uint8Array,
  signal: AbortSignal,
) => Promise<RawResponse>;

interface NetworkTransport {
  connect(options: Deno.ConnectOptions): Promise<Deno.TcpConn>;
  startTls(
    conn: Deno.TcpConn,
    options: Deno.StartTlsOptions,
  ): Promise<Deno.TlsConn>;
}

async function writeAll(
  conn: Pick<Deno.TlsConn, "write">,
  data: Uint8Array,
): Promise<void> {
  let offset = 0;
  while (offset < data.length) {
    offset += await conn.write(data.subarray(offset));
  }
}

export async function readHeaders(
  conn: Pick<Deno.TlsConn, "read">,
): Promise<{ status: number; headers: Headers }> {
  const decoder = new TextDecoder();
  let data = new Uint8Array();
  const buffer = new Uint8Array(4096);
  const maxHeaderBytes = 16 * 1024;
  while (data.length <= maxHeaderBytes) {
    const count = await conn.read(buffer);
    if (count === null) break;
    const next = new Uint8Array(data.length + count);
    next.set(data);
    next.set(buffer.subarray(0, count), data.length);
    data = next;
    const text = decoder.decode(data);
    const end = text.indexOf("\r\n\r\n");
    if (end >= 0) {
      if (end > maxHeaderBytes) {
        throw new SecurityError("webhook response headers too large", 502);
      }
      const lines = text.slice(0, end).split("\r\n");
      const match = lines.shift()?.match(/^HTTP\/1\.[01] (\d{3})(?: |$)/);
      if (!match) throw new SecurityError("invalid webhook response", 502);
      const headers = new Headers();
      for (const line of lines) {
        const colon = line.indexOf(":");
        if (colon <= 0) {
          throw new SecurityError("invalid webhook response headers", 502);
        }
        headers.append(
          line.slice(0, colon).trim(),
          line.slice(colon + 1).trim(),
        );
      }
      const contentLength = headers.get("content-length");
      if (
        contentLength &&
        (!/^\d+$/.test(contentLength) ||
          Number(contentLength) > MAX_RESPONSE_BYTES)
      ) throw new SecurityError("webhook response too large", 502);
      return { status: Number(match[1]), headers };
    }
  }
  throw new SecurityError(
    "webhook response headers too large or incomplete",
    502,
  );
}

export function createPinnedHttpsRequest(
  transport: NetworkTransport = {
    connect: (options) => Deno.connect(options),
    startTls: (conn, options) => Deno.startTls(conn, options),
  },
): RequestOnce {
  return async (url, address, body, signal) => {
    if (signal.aborted) {
      throw new DOMException("Delivery timed out", "AbortError");
    }
    let tcp: Deno.TcpConn | undefined;
    let conn: Deno.TlsConn | undefined;
    const abort = () => {
      const tlsToClose = conn;
      const tcpToClose = tcp;
      conn = undefined;
      tcp = undefined;
      try {
        tlsToClose?.close();
      } catch { /* already closed */ }
      try {
        tcpToClose?.close();
      } catch { /* TLS may already own/close the TCP resource */ }
    };
    signal.addEventListener("abort", abort, { once: true });
    try {
      tcp = await transport.connect({
        hostname: address,
        port: 443,
        transport: "tcp",
      });
      if (signal.aborted) {
        tcp.close();
        throw new DOMException("Delivery timed out", "AbortError");
      }
      const tls = await transport.startTls(tcp, { hostname: url.hostname });
      conn = tls;
      if (signal.aborted) {
        abort();
        throw new DOMException("Delivery timed out", "AbortError");
      }
      const path = `${url.pathname}${url.search}`;
      const head = new TextEncoder().encode(
        `POST ${
          path || "/"
        } HTTP/1.1\r\nHost: ${url.host}\r\nContent-Type: application/json\r\nContent-Length: ${body.length}\r\nConnection: close\r\nUser-Agent: taskboi-webhook/1\r\n\r\n`,
      );
      await writeAll(tls, head);
      await writeAll(tls, body);
      return await readHeaders(tls);
    } finally {
      signal.removeEventListener("abort", abort);
      abort();
    }
  };
}

export const pinnedHttpsRequest = createPinnedHttpsRequest();

function utf8ByteLength(value: string): number {
  let bytes = 0;
  for (const character of value) {
    const codePoint = character.codePointAt(0)!;
    bytes += codePoint <= 0x7f
      ? 1
      : codePoint <= 0x7ff
      ? 2
      : codePoint <= 0xffff
      ? 3
      : 4;
    if (bytes > MAX_OUTGOING_PAYLOAD_BYTES) return bytes;
  }
  return bytes;
}

function serializePayload(payload: unknown): Uint8Array {
  const serialized = JSON.stringify(payload);
  if (serialized === undefined) {
    throw new SecurityError("webhook payload is not JSON serializable", 500);
  }
  if (utf8ByteLength(serialized) > MAX_OUTGOING_PAYLOAD_BYTES) {
    throw new SecurityError("webhook payload too large", 413);
  }
  return new TextEncoder().encode(serialized);
}

export async function deliverWebhook(
  rawUrl: string,
  payload: unknown,
  options: {
    requestOnce?: RequestOnce;
    resolve?: (hostname: string) => Promise<string[]>;
    timeoutMs?: number;
  } = {},
): Promise<{ status: number; redirects: number }> {
  const requestOnce = options.requestOnce ?? pinnedHttpsRequest;
  const resolve = options.resolve ?? resolvePublicAddresses;
  const body = serializePayload(payload);
  let url = validateWebhookUrl(rawUrl);
  const controller = new AbortController();
  const work = async () => {
    for (let redirects = 0; redirects <= MAX_REDIRECTS; redirects++) {
      const addresses = await resolve(url.hostname.replace(/^\[|\]$/g, ""));
      if (
        !addresses.length ||
        addresses.some((address) => !validateResolved(address))
      ) {
        throw new SecurityError(
          "webhook DNS did not resolve exclusively to public addresses",
        );
      }
      const response = await requestOnce(
        url,
        addresses[0],
        body,
        controller.signal,
      );
      if (![301, 302, 303, 307, 308].includes(response.status)) {
        return { status: response.status, redirects };
      }
      if (redirects === MAX_REDIRECTS) {
        throw new SecurityError("too many webhook redirects", 502);
      }
      const location = response.headers.get("location");
      if (!location) {
        throw new SecurityError("webhook redirect missing location", 502);
      }
      url = validateWebhookUrl(new URL(location, url).href);
    }
    throw new SecurityError("too many webhook redirects", 502);
  };
  const timeout = setTimeout(
    () => controller.abort(),
    options.timeoutMs ?? DELIVERY_TIMEOUT_MS,
  );
  try {
    const result = await work();
    if (controller.signal.aborted) {
      throw new SecurityError("webhook delivery timed out", 504);
    }
    return result;
  } catch (error) {
    if (controller.signal.aborted) {
      throw new SecurityError("webhook delivery timed out", 504);
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

import { isPublicIp } from "./security.ts";
function validateResolved(address: string): boolean {
  return isPublicIp(address);
}
