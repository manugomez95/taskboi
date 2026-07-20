#!/bin/bash
set -euo pipefail

if [ "${1:-}" != "--confirm-compatible-clients-and-function" ]; then
    echo "Usage: DATABASE_URL=... $0 --confirm-compatible-clients-and-function" >&2
    echo "Run only after the comment-images function and compatible clients are live." >&2
    exit 2
fi
if [ -z "${DATABASE_URL:-}" ]; then
    echo "DATABASE_URL must be the direct PostgreSQL connection URL." >&2
    exit 2
fi

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
BEGIN;
SELECT public.finalize_comment_image_privacy(true);
DO $$
BEGIN
  IF COALESCE((SELECT public FROM storage.buckets WHERE id = 'comment-images'), true) THEN
    RAISE EXCEPTION 'comment-images bucket did not become private';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND permissive = 'PERMISSIVE'
      AND roles && ARRAY['public', 'anon', 'authenticated']::name[]
      AND (
        COALESCE(qual, with_check, '') !~
          'bucket_id = ''[^'']+''::text'
        OR COALESCE(qual, with_check, '') ~
          'bucket_id = ''comment-images''::text'
        OR COALESCE(qual, with_check, '') ~* ' OR | NOT '
      )
  ) THEN
    RAISE EXCEPTION 'a policy may still grant direct comment-images access';
  END IF;
END $$;
COMMIT;
SQL

echo "Comment image storage is private and legacy direct-access policies are absent."
