export const MAX_REQUEST_BYTES = 16 * 1024;
export const MAX_OUTGOING_PAYLOAD_BYTES = 64 * 1024;
export const MAX_RESPONSE_BYTES = 64 * 1024;
export const MAX_REDIRECTS = 3;
export const DELIVERY_TIMEOUT_MS = 5_000;

export class SecurityError extends Error {
  constructor(message: string, public status = 400) {
    super(message);
  }
}

export function timingSafeEqual(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const left = encoder.encode(a);
  const right = encoder.encode(b);
  let difference = left.length ^ right.length;
  const length = Math.max(left.length, right.length);
  for (let i = 0; i < length; i++) {
    difference |= (left[i % (left.length || 1)] ?? 0) ^
      (right[i % (right.length || 1)] ?? 0);
  }
  return difference === 0;
}

function ipv4Bytes(value: string): number[] | null {
  const parts = value.split(".");
  if (parts.length !== 4 || parts.some((part) => !/^\d{1,3}$/.test(part))) {
    return null;
  }
  const bytes = parts.map(Number);
  return bytes.every((byte, i) => byte <= 255 && String(byte) === parts[i])
    ? bytes
    : null;
}

function expandIpv6(value: string): number[] | null {
  let address = value.toLowerCase().split("%")[0];
  const embedded = address.match(/(?:^|:)(\d+\.\d+\.\d+\.\d+)$/)?.[1];
  if (embedded) {
    const bytes = ipv4Bytes(embedded);
    if (!bytes) return null;
    address = address.slice(0, -embedded.length) +
      `${((bytes[0] << 8) | bytes[1]).toString(16)}:${
        ((bytes[2] << 8) | bytes[3]).toString(16)
      }`;
  }
  if ((address.match(/::/g) ?? []).length > 1) return null;
  const halves = address.split("::");
  const left = halves[0] ? halves[0].split(":") : [];
  const right = halves[1] ? halves[1].split(":") : [];
  const missing = 8 - left.length - right.length;
  if (
    (halves.length === 1 && missing !== 0) ||
    (halves.length === 2 && missing < 1)
  ) return null;
  const words = [...left, ...Array(missing).fill("0"), ...right];
  if (
    words.length !== 8 || words.some((word) => !/^[0-9a-f]{1,4}$/.test(word))
  ) return null;
  return words.map((word) => Number.parseInt(word, 16));
}

export function isPublicIp(address: string): boolean {
  const v4 = ipv4Bytes(address);
  if (v4) {
    const [a, b, c] = v4;
    return !(
      a === 0 || a === 10 || a === 127 ||
      (a === 100 && b >= 64 && b <= 127) ||
      (a === 169 && b === 254) ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 0) || (a === 192 && b === 168) ||
      (a === 198 && (b === 18 || b === 19)) ||
      (a === 198 && b === 51 && c === 100) ||
      (a === 203 && b === 0 && c === 113) ||
      (a === 192 && b === 88 && c === 99) ||
      a >= 224
    );
  }
  const v6 = expandIpv6(address);
  if (!v6) return false;
  const [first, second, third, fourth, fifth, sixth] = v6;
  if (
    first === 0 && second === 0 && third === 0 && fourth === 0 && fifth === 0 &&
    sixth === 0xffff
  ) {
    return isPublicIp(
      `${v6[6] >> 8}.${v6[6] & 255}.${v6[7] >> 8}.${v6[7] & 255}`,
    );
  }
  const globalUnicast = (first & 0xe000) === 0x2000;
  return globalUnicast && !(
    v6.every((word) => word === 0) || v6.slice(0, 7).every((word) =>
      word === 0
    ) ||
    (first & 0xfe00) === 0xfc00 || (first & 0xffc0) === 0xfe80 ||
    (first & 0xff00) === 0xff00 || (first === 0x2001 && second === 0x0db8) ||
    (first === 0x2001 && second === 0) ||
    (first === 0x2001 && second === 2) ||
    (first === 0x2001 && (second & 0xfff0) === 0x0010) ||
    (first === 0x2001 && (second & 0xfff0) === 0x0020) ||
    first === 0x2002 || (first === 0x3fff && (second & 0xf000) === 0)
  );
}

export function validateWebhookUrl(raw: string): URL {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new SecurityError("invalid webhook URL");
  }
  if (url.protocol !== "https:") {
    throw new SecurityError("webhook URL must use HTTPS");
  }
  if (url.username || url.password) {
    throw new SecurityError("webhook URL must not contain credentials");
  }
  if (url.port && url.port !== "443") {
    throw new SecurityError("webhook URL must use port 443");
  }
  if (!url.hostname || url.hostname.endsWith(".")) {
    throw new SecurityError("invalid webhook hostname");
  }
  const hostname = url.hostname.replace(/^\[|\]$/g, "").toLowerCase();
  if (
    hostname === "localhost" || hostname.endsWith(".localhost") ||
    hostname.endsWith(".local")
  ) throw new SecurityError("webhook hostname is not public");
  if (
    (ipv4Bytes(hostname) || hostname.includes(":")) && !isPublicIp(hostname)
  ) throw new SecurityError("webhook address is not public");
  return url;
}

export async function resolvePublicAddresses(
  hostname: string,
): Promise<string[]> {
  const literal = hostname.replace(/^\[|\]$/g, "");
  if (ipv4Bytes(literal) || literal.includes(":")) {
    return isPublicIp(literal) ? [literal] : [];
  }
  const results = await Promise.allSettled([
    Deno.resolveDns(literal, "A"),
    Deno.resolveDns(literal, "AAAA"),
  ]);
  const addresses = results.flatMap((result) =>
    result.status === "fulfilled" ? result.value : []
  );
  if (!addresses.length || addresses.some((address) => !isPublicIp(address))) {
    throw new SecurityError(
      "webhook DNS did not resolve exclusively to public addresses",
    );
  }
  return [...new Set(addresses)];
}
