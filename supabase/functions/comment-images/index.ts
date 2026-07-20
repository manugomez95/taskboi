import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import {
  commentContainsImage,
  detectSafeImage,
  extensionMatches,
  legacyObjectKey,
  parseImageContentLength,
  readExactBody,
  requestedCleanupComplete,
  safeDownloadName,
  SIGNED_URL_TTL_SECONDS,
} from "./security.ts";

const headers = {
  "Content-Type": "application/json",
  "X-Content-Type-Options": "nosniff",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-comment-id, x-file-name, x-client-info",
  "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
};
const respond = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers });

// deno-lint-ignore no-explicit-any
type AdminClient = ReturnType<typeof createClient<any>>;

async function removeAndFinalize(
  admin: AdminClient,
  objectKey: string,
): Promise<boolean> {
  const { error: removeError } = await admin.storage.from("comment-images")
    .remove([objectKey]);
  if (removeError) return false;
  const { data: finalized, error: finishError } = await admin.rpc(
    "finish_comment_image_cleanup",
    { cleaned_object_key: objectKey },
  );
  if (finishError) throw new Error("Unable to finalize image cleanup");
  return finalized === true;
}

async function reconcile(admin: AdminClient, userId?: string, limit = 25) {
  let pendingQuery = admin.from("comment_images").select("object_key")
    .eq("storage_state", "cleanup_pending").limit(limit);
  let queuedQuery = admin.from("comment_image_cleanup_queue")
    .select("object_key").limit(limit);
  if (userId) {
    pendingQuery = pendingQuery.eq("user_id", userId);
    queuedQuery = queuedQuery.eq("user_id", userId);
  }
  const [pendingResult, queuedResult] = await Promise.all([
    pendingQuery,
    queuedQuery,
  ]);
  if (pendingResult.error || queuedResult.error) {
    throw new Error("Unable to select pending image cleanup work");
  }
  const pending = pendingResult.data;
  const queued = queuedResult.data;
  const keys = new Set<string>([
    ...((pending ?? []) as Array<{ object_key: string }>).map((row) =>
      row.object_key
    ),
    ...((queued ?? []) as Array<{ object_key: string }>).map((row) =>
      row.object_key
    ),
  ]);
  let failed = 0;
  for (const key of keys) {
    if (!await removeAndFinalize(admin, key)) failed++;
  }
  return { attempted: keys.size, failed };
}

async function reconcileResponse(
  admin: AdminClient,
  userId?: string,
  limit?: number,
) {
  try {
    return respond(await reconcile(admin, userId, limit));
  } catch (error) {
    return respond({ error: (error as Error).message }, 500);
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response(null, { status: 204 });
  const authorization = request.headers.get("Authorization");
  if (!authorization) return respond({ error: "Unauthorized" }, 401);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  // deno-lint-ignore no-explicit-any
  const admin = createClient<any>(url, serviceRoleKey);
  if (
    authorization === `Bearer ${serviceRoleKey}` && request.method === "POST" &&
    new URL(request.url).searchParams.get("action") === "reconcile-global"
  ) {
    return await reconcileResponse(admin, undefined, 100);
  }
  const anon = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: { user }, error: authError } = await anon.auth.getUser();
  if (authError || !user) return respond({ error: "Unauthorized" }, 401);

  // DELETE must durably queue its requested keys before unrelated cleanup can
  // fail. Other authenticated traffic incrementally drains durable work.
  if (request.method !== "DELETE") {
    try {
      await reconcile(admin, user.id);
    } catch (error) {
      return respond({ error: (error as Error).message }, 500);
    }
  }

  if (
    request.method === "POST" &&
    new URL(request.url).searchParams.get("action") === "reconcile"
  ) {
    return await reconcileResponse(admin, user.id);
  }

  if (request.method === "POST") {
    const commentId = request.headers.get("x-comment-id");
    const fileName = request.headers.get("x-file-name") ?? "";
    if (!commentId) return respond({ error: "x-comment-id is required" }, 400);
    let contentLength: number;
    try {
      contentLength = parseImageContentLength(
        request.headers.get("content-length"),
      );
    } catch (error) {
      return respond({ error: (error as Error).message }, 413);
    }

    let bytes: Uint8Array;
    try {
      bytes = await readExactBody(request.body, contentLength);
    } catch (error) {
      return respond({ error: (error as Error).message }, 400);
    }
    const image = detectSafeImage(bytes);
    if (!image || !extensionMatches(fileName, image)) {
      return respond({
        error: "File content and extension must be JPEG, PNG, GIF, or WebP",
      }, 415);
    }

    const { data: comment, error: commentError } = await admin.from("comments")
      .select("id, task_id").eq("id", commentId).eq("user_id", user.id)
      .maybeSingle();
    if (commentError) {
      return respond({ error: "Unable to authorize comment" }, 500);
    }
    if (!comment) return respond({ error: "Comment not found" }, 404);

    const imageId = crypto.randomUUID();
    const objectKey =
      `${user.id}/${comment.task_id}/${comment.id}/${crypto.randomUUID()}.${image.extension}`;
    const { error: metadataError } = await admin.from("comment_images").insert({
      id: imageId,
      comment_id: comment.id,
      task_id: comment.task_id,
      user_id: user.id,
      object_key: objectKey,
      mime_type: image.mimeType,
      byte_size: bytes.length,
    });
    if (metadataError) {
      const quota = metadataError.message.includes("quota exceeded");
      return respond({
        error: quota
          ? "Comment image quota exceeded"
          : "Unable to reserve image",
      }, quota ? 413 : 500);
    }

    const { error: uploadError } = await admin.storage.from("comment-images")
      .upload(objectKey, bytes, { contentType: image.mimeType, upsert: false });
    if (uploadError) {
      // The storage API can fail after accepting bytes. Preserve quota and the
      // object key until a confirmed delete is followed by metadata cleanup.
      const { data: transitioned, error: transitionError } = await admin.from(
        "comment_images",
      ).update({
        storage_state: "cleanup_pending",
      }).eq("id", imageId).select("id");
      if (transitionError || transitioned?.length !== 1) {
        return respond({ error: "Unable to queue failed upload cleanup" }, 500);
      }
      try {
        await reconcile(admin, user.id);
      } catch (error) {
        return respond({ error: (error as Error).message }, 500);
      }
      return respond({ error: "Unable to store image" }, 500);
    }
    return respond({ id: imageId }, 201);
  }

  if (request.method === "DELETE") {
    const requestUrl = new URL(request.url);
    const imageId = requestUrl.searchParams.get("id");
    const commentId = requestUrl.searchParams.get("commentId");
    const legacyUrl = requestUrl.searchParams.get("legacyUrl");
    if ((!imageId && !commentId) || (legacyUrl && !commentId)) {
      return respond({ error: "id or commentId is required" }, 400);
    }
    let query = admin.from("comment_images").select("id, object_key")
      .eq("user_id", user.id);
    query = imageId
      ? query.eq("id", imageId)
      : query.eq("comment_id", commentId!);
    const { data: images, error } = await query;
    if (error) return respond({ error: "Unable to authorize images" }, 500);
    if (imageId && !images?.length) {
      return respond({ error: "Image not found" }, 404);
    }

    // Legacy comments contain public URLs rather than metadata IDs. Authorize
    // them against the owning comment, then durably queue their object keys.
    const commentResult = commentId
      ? await admin.from("comments").select("images").eq("id", commentId)
        .eq("user_id", user.id).maybeSingle()
      : { data: null, error: null };
    if (commentResult.error) {
      return respond({ error: "Unable to authorize legacy images" }, 500);
    }
    const comment = commentResult.data;
    if (legacyUrl && !commentContainsImage(comment?.images, legacyUrl)) {
      return respond({ error: "Legacy image not found" }, 404);
    }
    const legacyValues = legacyUrl
      ? [legacyUrl]
      : ((comment?.images ?? []) as string[]);
    const legacyKeys: string[] = [];
    for (const value of legacyValues) {
      const key = legacyObjectKey(value, url, user.id);
      if (key) legacyKeys.push(key);
    }
    if (legacyUrl && !legacyKeys.length) {
      return respond({ error: "Legacy image not found" }, 404);
    }
    if (legacyKeys.length) {
      const { error: queueError } = await admin.rpc(
        "queue_legacy_comment_image_cleanup",
        { legacy_object_keys: legacyKeys, legacy_user_id: user.id },
      );
      if (queueError) return respond({ error: "Unable to queue images" }, 409);
    }

    const ids = (images ?? []).map((image) => image.id);
    if (ids.length) {
      const { data: transitioned, error: transitionError } = await admin.from(
        "comment_images",
      ).update({
        storage_state: "cleanup_pending",
      }).in("id", ids).select("id");
      if (transitionError || transitioned?.length !== ids.length) {
        return respond({ error: "Unable to queue images" }, 500);
      }
    }
    let result;
    try {
      result = await reconcile(admin, user.id);
    } catch (error) {
      return respond({ error: (error as Error).message }, 500);
    }
    const requestedKeys = new Set([
      ...(images ?? []).map((image) => image.object_key),
      ...legacyKeys,
    ]);
    if (requestedKeys.size === 0) {
      return respond({ deleted: true, ...result });
    }
    const [remainingMetadata, remainingQueue] = await Promise.all([
      admin.from("comment_images").select("object_key").in(
        "object_key",
        [...requestedKeys],
      ),
      admin.from("comment_image_cleanup_queue").select("object_key").in(
        "object_key",
        [...requestedKeys],
      ),
    ]);
    if (remainingMetadata.error || remainingQueue.error) {
      return respond({ error: "Unable to verify image cleanup" }, 500);
    }
    const remainingRequestedKeys = new Set([
      ...(remainingMetadata.data ?? []).map((row) => row.object_key),
      ...(remainingQueue.data ?? []).map((row) => row.object_key),
    ]);
    // Reconciliation is bounded and can include unrelated work. Only the
    // durable state of every key requested by this DELETE determines success.
    const deleted = requestedCleanupComplete(
      requestedKeys,
      remainingRequestedKeys,
      [],
    );
    return respond(
      { deleted, ...result },
      deleted ? 200 : 202,
    );
  }

  if (request.method === "GET") {
    const requestUrl = new URL(request.url);
    const imageId = requestUrl.searchParams.get("id");
    const legacyUrl = requestUrl.searchParams.get("legacyUrl");
    const commentId = requestUrl.searchParams.get("commentId");
    if ((!imageId && !legacyUrl) || !commentId) {
      return respond({ error: "image and commentId are required" }, 400);
    }
    let objectKey: string | null = null;
    if (imageId) {
      const { data: image, error: imageError } = await admin.from(
        "comment_images",
      ).select(
        "object_key",
      )
        .eq("id", imageId).eq("comment_id", commentId).eq("user_id", user.id)
        .maybeSingle();
      if (imageError) {
        return respond({ error: "Unable to authorize image" }, 500);
      }
      objectKey = image?.object_key ?? null;
    } else {
      const { data: comment, error: commentError } = await admin.from(
        "comments",
      ).select("images")
        .eq("id", commentId).eq("user_id", user.id).contains("images", [
          legacyUrl,
        ]).maybeSingle();
      if (commentError) {
        return respond({ error: "Unable to authorize legacy image" }, 500);
      }
      if (comment) objectKey = legacyObjectKey(legacyUrl!, url, user.id);
    }
    if (!objectKey || objectKey.includes("..")) {
      return respond({ error: "Image not found" }, 404);
    }
    const extension = objectKey.split(".").pop()!;
    const download = requestUrl.searchParams.get("download") === "true";
    const options = download
      ? {
        download: safeDownloadName(
          requestUrl.searchParams.get("name"),
          extension,
        ),
      }
      : undefined;
    const { data, error } = await admin.storage.from("comment-images")
      .createSignedUrl(objectKey, SIGNED_URL_TTL_SECONDS, options);
    if (error || !data) {
      return respond({ error: "Unable to sign image URL" }, 500);
    }
    return respond({ url: data.signedUrl, expiresIn: SIGNED_URL_TTL_SECONDS });
  }

  return respond({ error: "Method not allowed" }, 405);
});
