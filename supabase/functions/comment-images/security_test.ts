import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import {
  commentContainsImage,
  detectSafeImage,
  extensionMatches,
  legacyObjectKey,
  MAX_IMAGE_BYTES,
  parseImageContentLength,
  readExactBody,
  requestedCleanupComplete,
  safeDownloadName,
  SIGNED_URL_TTL_SECONDS,
} from "./security.ts";

Deno.test("legacy authorization requires exact comment image membership", () => {
  const legacy =
    "https://project.supabase.co/storage/v1/object/public/comment-images/user/image.png";
  assertEquals(commentContainsImage([legacy], legacy), true);
  assertEquals(commentContainsImage([], legacy), false);
  assertEquals(commentContainsImage([`${legacy}?variant=1`], legacy), false);
  assertEquals(commentContainsImage(null, legacy), false);
});

Deno.test("DELETE success requires every requested key to be absent", () => {
  assertEquals(requestedCleanupComplete(["a", "b"], [], []), true);
  assertEquals(requestedCleanupComplete(["a", "b"], ["b"], []), false);
  assertEquals(requestedCleanupComplete(["a", "b"], [], ["a"]), false);
  // Unrelated reconciliation state cannot affect the requested-key verdict.
  assertEquals(requestedCleanupComplete(["a"], ["unrelated"], []), true);
});

Deno.test("detects supported image signatures and matching extensions", () => {
  const jpeg = detectSafeImage(new Uint8Array([0xff, 0xd8, 0xff, 0x00]))!;
  assertEquals(jpeg.mimeType, "image/jpeg");
  assertEquals(extensionMatches("photo.JPEG", jpeg), true);
  assertEquals(extensionMatches("photo.png", jpeg), false);
  assertEquals(
    detectSafeImage(new TextEncoder().encode("<svg><script>")),
    null,
  );
});

Deno.test("legacy keys require exact origin, membership-compatible shape, and owner", () => {
  const base = "https://project.supabase.co";
  const user = "31000000-0000-4000-8000-000000000001";
  const good =
    `${base}/storage/v1/object/public/comment-images/${user}/550e8400-e29b-41d4-a716-446655440000.png`;
  assertEquals(
    legacyObjectKey(good, base, user),
    `${user}/550e8400-e29b-41d4-a716-446655440000.png`,
  );
  assertEquals(
    legacyObjectKey(good.replace(base, "https://victim.example"), base, user),
    null,
  );
  assertEquals(
    legacyObjectKey(
      good.replace(user, "32000000-0000-4000-8000-000000000002"),
      base,
      user,
    ),
    null,
  );
  assertEquals(
    legacyObjectKey(
      `${base}/storage/v1/object/public/comment-images/${user}%2Fvictim.png`,
      base,
      user,
    ),
    null,
  );
  assertEquals(
    legacyObjectKey(
      `${base}/storage/v1/object/public/comment-images/${user}/nested/victim.png`,
      base,
      user,
    ),
    null,
  );
});

Deno.test("requires an exact bounded content length before reading", async () => {
  assertEquals(parseImageContentLength("3"), 3);
  for (
    const invalid of [
      null,
      "",
      "0",
      "3.0",
      "-1",
      "abc",
      `${MAX_IMAGE_BYTES + 1}`,
    ]
  ) {
    try {
      parseImageContentLength(invalid);
      throw new Error("expected length rejection");
    } catch (error) {
      assertEquals(error instanceof RangeError, true);
    }
  }
  const stream = new Blob([new Uint8Array([1, 2, 3])]).stream();
  assertEquals(await readExactBody(stream, 3), new Uint8Array([1, 2, 3]));
  for (const expected of [2, 4]) {
    try {
      await readExactBody(
        new Blob([new Uint8Array([1, 2, 3])]).stream(),
        expected,
      );
      throw new Error("expected mismatch rejection");
    } catch (error) {
      assertEquals(error instanceof RangeError, true);
    }
  }
});

Deno.test("limits, signed URL lifetime, and download names are constrained", () => {
  assertEquals(MAX_IMAGE_BYTES, 5 * 1024 * 1024);
  assertEquals(SIGNED_URL_TTL_SECONDS, 60);
  assertEquals(
    safeDownloadName("../bad\r\nname.html", "png"),
    ".._bad__name.png",
  );
});
