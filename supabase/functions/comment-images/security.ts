export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
export const SIGNED_URL_TTL_SECONDS = 60;

export function commentContainsImage(
  images: unknown,
  requestedImage: string,
): boolean {
  return Array.isArray(images) &&
    images.some((value) => value === requestedImage);
}

export function legacyObjectKey(
  value: string,
  supabaseUrl: string,
  userId: string,
): string | null {
  try {
    const parsed = new URL(value);
    const expected = new URL(supabaseUrl);
    if (
      parsed.origin !== expected.origin || parsed.username || parsed.password
    ) {
      return null;
    }
    const marker = "/storage/v1/object/public/comment-images/";
    if (!parsed.pathname.startsWith(marker)) return null;
    const encodedKey = parsed.pathname.slice(marker.length);
    const key = decodeURIComponent(encodedKey);
    // Legacy clients wrote exactly <authenticated user UUID>/<filename>.
    // Reject encoded separators and all non-canonical or nested variants.
    if (
      encodedKey.includes("%2f") || encodedKey.includes("%2F") ||
      key !== `${userId}/${key.split("/")[1] ?? ""}` ||
      !new RegExp(`^${userId}/[0-9a-f-]+\\.(?:jpe?g|png|gif|webp)$`, "i")
        .test(key)
    ) return null;
    return key;
  } catch {
    return null;
  }
}

export function parseImageContentLength(value: string | null): number {
  if (value === null || !/^[1-9][0-9]*$/.test(value)) {
    throw new RangeError("A valid Content-Length is required");
  }
  const length = Number(value);
  if (!Number.isSafeInteger(length) || length > MAX_IMAGE_BYTES) {
    throw new RangeError("Image exceeds 5 MiB");
  }
  return length;
}

export async function readExactBody(
  body: ReadableStream<Uint8Array> | null,
  expectedLength: number,
): Promise<Uint8Array> {
  if (!body) throw new RangeError("Request body is required");
  const result = new Uint8Array(expectedLength);
  const reader = body.getReader();
  let offset = 0;
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      if (offset + value.length > expectedLength) {
        throw new RangeError("Body exceeds Content-Length");
      }
      result.set(value, offset);
      offset += value.length;
    }
  } finally {
    reader.releaseLock();
  }
  if (offset !== expectedLength) {
    throw new RangeError("Body does not match Content-Length");
  }
  return result;
}

export type SafeImage = { mimeType: string; extension: string };

function ascii(bytes: Uint8Array, start: number, length: number): string {
  return String.fromCharCode(...bytes.slice(start, start + length));
}

export function detectSafeImage(bytes: Uint8Array): SafeImage | null {
  if (
    bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 &&
    bytes[2] === 0xff
  ) {
    return { mimeType: "image/jpeg", extension: "jpg" };
  }
  if (
    bytes.length >= 8 &&
    bytes.slice(0, 8).every((b, i) =>
      b === [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a][i]
    )
  ) {
    return { mimeType: "image/png", extension: "png" };
  }
  if (bytes.length >= 6 && ["GIF87a", "GIF89a"].includes(ascii(bytes, 0, 6))) {
    return { mimeType: "image/gif", extension: "gif" };
  }
  if (
    bytes.length >= 12 && ascii(bytes, 0, 4) === "RIFF" &&
    ascii(bytes, 8, 4) === "WEBP"
  ) {
    return { mimeType: "image/webp", extension: "webp" };
  }
  return null;
}

export function extensionMatches(fileName: string, image: SafeImage): boolean {
  const extension = fileName.split(".").pop()?.toLowerCase();
  return image.mimeType === "image/jpeg"
    ? extension === "jpg" || extension === "jpeg"
    : extension === image.extension;
}

export function safeDownloadName(value: unknown, extension: string): string {
  const base = typeof value === "string"
    ? value.replace(/[^a-zA-Z0-9._-]/g, "_")
    : "comment-image";
  const withoutExtension = base.replace(/\.[^.]*$/, "").slice(0, 80) ||
    "comment-image";
  return `${withoutExtension}.${extension}`;
}

export function requestedCleanupComplete(
  requestedKeys: Iterable<string>,
  remainingMetadataKeys: Iterable<string>,
  remainingQueueKeys: Iterable<string>,
): boolean {
  const remaining = new Set([
    ...remainingMetadataKeys,
    ...remainingQueueKeys,
  ]);
  return [...requestedKeys].every((key) => !remaining.has(key));
}
