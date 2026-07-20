-- Add the private-image metadata foundation without breaking released clients.
-- Existing comments.images values are intentionally untouched for rollout
-- compatibility and are signed by the Edge Function after authorization.

CREATE TABLE public.comment_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comment_id UUID NOT NULL REFERENCES public.comments(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    object_key TEXT NOT NULL UNIQUE,
    mime_type TEXT NOT NULL CHECK (mime_type IN
        ('image/jpeg', 'image/png', 'image/gif', 'image/webp')),
    byte_size INTEGER NOT NULL CHECK (byte_size > 0 AND byte_size <= 5242880),
    storage_state TEXT NOT NULL DEFAULT 'ready'
        CHECK (storage_state IN ('ready', 'cleanup_pending')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT comment_images_task_owner_fkey
        FOREIGN KEY (task_id, user_id)
        REFERENCES public.tasks(id, user_id) ON DELETE CASCADE
);

CREATE FUNCTION public.enforce_comment_image_ownership()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.comments
        WHERE id = NEW.comment_id AND task_id = NEW.task_id AND user_id = NEW.user_id
    ) THEN
        RAISE EXCEPTION USING ERRCODE = '23503',
            MESSAGE = 'comment image must belong to its comment task and owner';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_comment_image_ownership_before_write
    BEFORE INSERT OR UPDATE ON public.comment_images
    FOR EACH ROW EXECUTE FUNCTION public.enforce_comment_image_ownership();

CREATE INDEX comment_images_user_id_idx ON public.comment_images(user_id);
CREATE INDEX comment_images_comment_id_idx ON public.comment_images(comment_id);

-- A row survives any cascading metadata deletion until its storage object has
-- been removed. byte_size remains chargeable, so a failed delete cannot free
-- quota while leaving an object behind.
CREATE TABLE public.comment_image_cleanup_queue (
    object_key TEXT PRIMARY KEY,
    user_id UUID NOT NULL,
    byte_size INTEGER NOT NULL CHECK (byte_size >= 0 AND byte_size <= 5242880),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_attempt_at TIMESTAMPTZ
);

ALTER TABLE public.comment_image_cleanup_queue ENABLE ROW LEVEL SECURITY;

-- object_key is globally exclusive across live metadata and cleanup work.
-- Both sides take the same transaction advisory lock so the invariant also
-- holds under concurrent legacy cleanup and uploads.
CREATE FUNCTION public.enforce_comment_image_key_available()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(hashtextextended(NEW.object_key, 0));
    IF EXISTS (SELECT 1 FROM public.comment_image_cleanup_queue
               WHERE object_key = NEW.object_key) THEN
        RAISE EXCEPTION USING ERRCODE = '23505',
            MESSAGE = 'comment image object key is pending cleanup';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_comment_image_key_available_before_write
    BEFORE INSERT OR UPDATE OF object_key ON public.comment_images
    FOR EACH ROW EXECUTE FUNCTION public.enforce_comment_image_key_available();

CREATE FUNCTION public.enforce_cleanup_key_not_live()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(hashtextextended(NEW.object_key, 0));
    IF EXISTS (SELECT 1 FROM public.comment_images
               WHERE object_key = NEW.object_key) THEN
        RAISE EXCEPTION USING ERRCODE = '23505',
            MESSAGE = 'cleanup object key belongs to live metadata';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_cleanup_key_not_live_before_write
    BEFORE INSERT OR UPDATE OF object_key ON public.comment_image_cleanup_queue
    FOR EACH ROW EXECUTE FUNCTION public.enforce_cleanup_key_not_live();

CREATE FUNCTION public.queue_deleted_comment_image()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(hashtextextended(OLD.object_key, 0));
    INSERT INTO public.comment_image_cleanup_queue(object_key, user_id, byte_size)
    VALUES (OLD.object_key, OLD.user_id, OLD.byte_size)
    ON CONFLICT (object_key) DO NOTHING;
    RETURN OLD;
END;
$$;

CREATE TRIGGER queue_comment_image_before_delete
    AFTER DELETE ON public.comment_images
    FOR EACH ROW EXECUTE FUNCTION public.queue_deleted_comment_image();

-- Comment mutations are the durable source of cleanup intent. Once an image
-- reference is removed (or its comment is deleted), queue both opaque-image
-- metadata and legacy object keys in the same database transaction. Clients
-- may then request eager cleanup, but correctness never depends on that call.
CREATE FUNCTION public.queue_removed_comment_image_references()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE old_value TEXT;
DECLARE legacy_key TEXT;
DECLARE remaining_images TEXT[] := CASE WHEN TG_OP = 'DELETE' THEN '{}'::TEXT[]
                                        ELSE COALESCE(NEW.images, '{}'::TEXT[]) END;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        DELETE FROM public.comment_images
        WHERE comment_id = OLD.id
          AND id::TEXT = ANY(COALESCE(OLD.images, '{}'::TEXT[]))
          AND NOT (id::TEXT = ANY(remaining_images));
    END IF;

    FOREACH old_value IN ARRAY COALESCE(OLD.images, '{}'::TEXT[]) LOOP
        CONTINUE WHEN old_value = ANY(remaining_images);
        legacy_key := split_part(old_value, '/storage/v1/object/public/comment-images/', 2);
        IF legacy_key ~ ('^' || OLD.user_id::TEXT || '/[^/]+$') THEN
            INSERT INTO public.comment_image_cleanup_queue(object_key, user_id, byte_size)
            VALUES (legacy_key, OLD.user_id, 0)
            ON CONFLICT (object_key) DO NOTHING;
        END IF;
    END LOOP;
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

CREATE TRIGGER queue_removed_comment_image_references_after_update
    AFTER UPDATE OF images ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.queue_removed_comment_image_references();
CREATE TRIGGER queue_removed_comment_image_references_before_delete
    BEFORE DELETE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.queue_removed_comment_image_references();

CREATE FUNCTION public.queue_legacy_comment_image_cleanup(
    legacy_object_keys TEXT[], legacy_user_id UUID
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE legacy_object_key TEXT;
BEGIN
    FOREACH legacy_object_key IN ARRAY legacy_object_keys LOOP
        PERFORM pg_advisory_xact_lock(hashtextextended(legacy_object_key, 0));
        IF EXISTS (SELECT 1 FROM public.comment_images
                   WHERE object_key = legacy_object_key) THEN
            RAISE EXCEPTION USING ERRCODE = '23505',
                MESSAGE = 'legacy cleanup key belongs to live metadata';
        END IF;
        INSERT INTO public.comment_image_cleanup_queue(object_key, user_id, byte_size)
        VALUES (legacy_object_key, legacy_user_id, 0)
        ON CONFLICT (object_key) DO NOTHING;
    END LOOP;
END;
$$;
REVOKE ALL ON FUNCTION public.queue_legacy_comment_image_cleanup(TEXT[], UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.queue_legacy_comment_image_cleanup(TEXT[], UUID) TO service_role;

CREATE FUNCTION public.finish_comment_image_cleanup(cleaned_object_key TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE removed_count INTEGER;
BEGIN
    DELETE FROM public.comment_images WHERE object_key = cleaned_object_key;
    DELETE FROM public.comment_image_cleanup_queue WHERE object_key = cleaned_object_key;
    GET DIAGNOSTICS removed_count = ROW_COUNT;
    RETURN removed_count > 0 OR NOT EXISTS (
        SELECT 1 FROM public.comment_images WHERE object_key = cleaned_object_key
    );
END;
$$;
REVOKE ALL ON FUNCTION public.finish_comment_image_cleanup(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.finish_comment_image_cleanup(TEXT) TO service_role;

ALTER TABLE public.comment_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own comment image metadata"
    ON public.comment_images FOR SELECT
    USING (auth.uid() = user_id);

-- Serialize quota accounting per user. Only the service-role Edge Function can
-- insert metadata; this trigger remains the final server-side quota backstop.
CREATE FUNCTION public.enforce_comment_image_quota()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    used_bytes BIGINT;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtextextended(NEW.user_id::text, 0));
    SELECT COALESCE(SUM(byte_size), 0) INTO used_bytes
    FROM (
        SELECT byte_size FROM public.comment_images WHERE user_id = NEW.user_id
        UNION ALL
        SELECT byte_size FROM public.comment_image_cleanup_queue WHERE user_id = NEW.user_id
    ) AS charged_objects;
    IF used_bytes + NEW.byte_size > 104857600 THEN
        RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'comment image quota exceeded';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_comment_image_quota_before_insert
    BEFORE INSERT ON public.comment_images
    FOR EACH ROW EXECUTE FUNCTION public.enforce_comment_image_quota();

-- Privacy is an explicit post-client operation because the migration runner
-- cannot stop between committed files. The guarded script invokes this exact
-- function after compatible clients are confirmed in production.
CREATE FUNCTION public.finalize_comment_image_privacy(compatible_clients_confirmed BOOLEAN)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, storage AS $$
DECLARE
    policy_to_drop RECORD;
    ambiguous_policies TEXT;
BEGIN
    IF compatible_clients_confirmed IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'compatible clients must be explicitly confirmed';
    END IF;
    IF to_regclass('public.comment_images') IS NULL THEN
        RAISE EXCEPTION 'comment image security foundation is not installed';
    END IF;
    -- The four policies below were created by migration 014 and are the only
    -- policies this finalizer owns. Anything broad or otherwise ambiguous may
    -- grant this bucket, but deleting it could break an unrelated bucket. Stop
    -- transactionally and make the operator remediate it explicitly instead.
    SELECT string_agg(p.policyname, ', ' ORDER BY p.policyname)
    INTO ambiguous_policies
    FROM pg_policies p
    WHERE p.schemaname = 'storage' AND p.tablename = 'objects'
      AND p.permissive = 'PERMISSIVE'
      AND p.roles && ARRAY['public', 'anon', 'authenticated']::name[]
      AND NOT (
          p.policyname IN (
              'Users can upload comment images',
              'Anyone can view comment images',
              'Users can update their own comment images',
              'Users can delete their own comment images'
          )
          AND EXISTS (
              SELECT 1 FROM unnest(ARRAY[p.qual, p.with_check]) expression
              WHERE expression IS NOT NULL
          )
          AND NOT EXISTS (
              SELECT 1 FROM unnest(ARRAY[p.qual, p.with_check]) expression
              WHERE expression IS NOT NULL
                AND (expression !~ 'bucket_id = ''comment-images''::text'
                     OR expression ~* ' OR | NOT ')
          )
      )
      -- Every USING and WITH CHECK expression is classified independently.
      -- A simple equality to another bucket is demonstrably unrelated; one
      -- restrictive expression must never hide a permissive second one.
      AND EXISTS (
          SELECT 1 FROM unnest(ARRAY[p.qual, p.with_check]) expression
          WHERE expression IS NOT NULL
            AND NOT (
                expression ~ 'bucket_id = ''[^'']+''::text'
                AND expression !~ 'bucket_id = ''comment-images''::text'
                AND expression !~* ' OR | NOT '
            )
      );
    IF ambiguous_policies IS NOT NULL THEN
        RAISE EXCEPTION 'ambiguous storage.objects policies require operator remediation: %',
            ambiguous_policies;
    END IF;

    FOR policy_to_drop IN
        SELECT p.policyname FROM pg_policies p
        WHERE p.schemaname = 'storage' AND p.tablename = 'objects'
          AND p.permissive = 'PERMISSIVE'
          AND p.roles && ARRAY['public', 'anon', 'authenticated']::name[]
          AND p.policyname IN (
              'Users can upload comment images',
              'Anyone can view comment images',
              'Users can update their own comment images',
              'Users can delete their own comment images'
          )
          AND EXISTS (
              SELECT 1 FROM unnest(ARRAY[p.qual, p.with_check]) expression
              WHERE expression IS NOT NULL
          )
          AND NOT EXISTS (
              SELECT 1 FROM unnest(ARRAY[p.qual, p.with_check]) expression
              WHERE expression IS NOT NULL
                AND (expression !~ 'bucket_id = ''comment-images''::text'
                     OR expression ~* ' OR | NOT ')
          )
    LOOP
        EXECUTE format('DROP POLICY %I ON storage.objects', policy_to_drop.policyname);
    END LOOP;

    UPDATE storage.buckets
    SET public = false,
        file_size_limit = 5242880,
        allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    WHERE id = 'comment-images';
    IF NOT FOUND THEN RAISE EXCEPTION 'comment-images bucket is missing'; END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.finalize_comment_image_privacy(BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.finalize_comment_image_privacy(BOOLEAN) TO service_role;
