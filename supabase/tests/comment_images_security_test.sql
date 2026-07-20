BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(26);

INSERT INTO auth.users (id, email) VALUES
  ('31000000-0000-4000-8000-000000000001', 'image-one@example.test'),
  ('32000000-0000-4000-8000-000000000002', 'image-two@example.test');

INSERT INTO public.tasks (id, project_id, user_id, title)
SELECT '33000000-0000-4000-8000-000000000003', id,
       '31000000-0000-4000-8000-000000000001', 'Image task'
FROM public.projects WHERE user_id = '31000000-0000-4000-8000-000000000001' AND is_inbox;
INSERT INTO public.tasks (id, project_id, user_id, title)
SELECT '34000000-0000-4000-8000-000000000004', id,
       '32000000-0000-4000-8000-000000000002', 'Other image task'
FROM public.projects WHERE user_id = '32000000-0000-4000-8000-000000000002' AND is_inbox;
INSERT INTO public.comments (id, task_id, user_id, content) VALUES
  ('35000000-0000-4000-8000-000000000005', '33000000-0000-4000-8000-000000000003', '31000000-0000-4000-8000-000000000001', 'Image comment'),
  ('36000000-0000-4000-8000-000000000006', '34000000-0000-4000-8000-000000000004', '32000000-0000-4000-8000-000000000002', 'Other comment');

SELECT throws_ok(
  $$INSERT INTO public.comment_images(comment_id, task_id, user_id, object_key, mime_type, byte_size)
    VALUES ('35000000-0000-4000-8000-000000000005', '34000000-0000-4000-8000-000000000004',
      '31000000-0000-4000-8000-000000000001', 'bad-owner.png', 'image/png', 10)$$,
  '23503', NULL, 'cross-tenant task binding is rejected');

SELECT throws_ok(
  $$INSERT INTO public.comment_images(comment_id, task_id, user_id, object_key, mime_type, byte_size)
    VALUES ('35000000-0000-4000-8000-000000000005', '33000000-0000-4000-8000-000000000003',
      '31000000-0000-4000-8000-000000000001', 'bad.svg', 'image/svg+xml', 10)$$,
  '23514', NULL, 'unsafe MIME is rejected');

SELECT throws_ok(
  $$INSERT INTO public.comment_images(comment_id, task_id, user_id, object_key, mime_type, byte_size)
    VALUES ('35000000-0000-4000-8000-000000000005', '33000000-0000-4000-8000-000000000003',
      '31000000-0000-4000-8000-000000000001', 'large.png', 'image/png', 5242881)$$,
  '23514', NULL, 'per-file limit is rejected');

INSERT INTO public.comment_images(comment_id, task_id, user_id, object_key, mime_type, byte_size)
SELECT '35000000-0000-4000-8000-000000000005', '33000000-0000-4000-8000-000000000003',
  '31000000-0000-4000-8000-000000000001', 'quota/' || n || '.png', 'image/png', 5242880
FROM generate_series(1, 20) AS n;

INSERT INTO public.comment_images(comment_id, task_id, user_id, object_key, mime_type, byte_size)
VALUES ('36000000-0000-4000-8000-000000000006', '34000000-0000-4000-8000-000000000004',
  '32000000-0000-4000-8000-000000000002', 'cascade.png', 'image/png', 123);
DELETE FROM public.comments WHERE id = '36000000-0000-4000-8000-000000000006';
SELECT is((SELECT byte_size FROM public.comment_image_cleanup_queue
           WHERE object_key = 'cascade.png'), 123,
  'cascading comment deletion preserves the actual byte charge');

SELECT throws_ok(
  $$INSERT INTO public.comment_images(comment_id, task_id, user_id, object_key, mime_type, byte_size)
    VALUES ('35000000-0000-4000-8000-000000000005', '33000000-0000-4000-8000-000000000003',
      '31000000-0000-4000-8000-000000000001', 'over-quota.png', 'image/png', 1)$$,
  'P0001', 'comment image quota exceeded', 'per-user quota is enforced');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '31000000-0000-4000-8000-000000000001', true);
SELECT is((SELECT count(*) FROM public.comment_images), 20::bigint,
  'owner can read own image metadata');
SELECT is((SELECT count(*) FROM public.comment_images WHERE user_id = '32000000-0000-4000-8000-000000000002'), 0::bigint,
  'other tenant metadata is hidden');
SELECT throws_ok(
  $$INSERT INTO storage.objects(bucket_id, name, owner_id) VALUES
    ('comment-images', 'direct.png', '31000000-0000-4000-8000-000000000001')$$,
  '42501', NULL, 'direct client storage uploads are denied');

RESET ROLE;
CREATE POLICY "unexpected client image access"
    ON storage.objects FOR SELECT
    USING (true);
SELECT throws_ok(
  $$SELECT public.finalize_comment_image_privacy(false)$$,
  'P0001', 'compatible clients must be explicitly confirmed',
  'privacy finalization requires explicit client confirmation');
SELECT throws_ok(
  $$SELECT public.finalize_comment_image_privacy(true)$$,
  'P0001',
  'ambiguous storage.objects policies require operator remediation: unexpected client image access',
  'broad policies fail closed for explicit operator remediation');
SELECT is((SELECT public FROM storage.buckets WHERE id = 'comment-images'), true,
  'failed finalization is transactional');
DROP POLICY "unexpected client image access" ON storage.objects;
CREATE POLICY "unrelated bucket access"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');
CREATE POLICY "mixed bucket access"
    ON storage.objects FOR ALL
    USING (bucket_id = 'avatars')
    WITH CHECK (bucket_id = 'comment-images');
SELECT throws_ok(
  $$SELECT public.finalize_comment_image_privacy(true)$$,
  'P0001',
  'ambiguous storage.objects policies require operator remediation: mixed bucket access',
  'a comment-images expression is not masked by another bucket restriction');
SELECT is((SELECT count(*) FROM pg_policies
           WHERE schemaname = 'storage' AND tablename = 'objects'
             AND policyname IN ('mixed bucket access', 'unrelated bucket access')),
          2::bigint,
  'failed finalization does not harm mixed or unrelated policies');
DROP POLICY "mixed bucket access" ON storage.objects;
SELECT public.finalize_comment_image_privacy(true);
SELECT is((SELECT public FROM storage.buckets WHERE id = 'comment-images'), false,
  'comment image bucket is private after committed migrations');
SELECT is((SELECT count(*) FROM pg_policies
           WHERE schemaname = 'storage' AND tablename = 'objects'
             AND permissive = 'PERMISSIVE'
             AND policyname IN (
               'Users can upload comment images', 'Anyone can view comment images',
               'Users can update their own comment images',
               'Users can delete their own comment images')), 0::bigint,
  'finalization removes only the owned comment-images policies');
SELECT is((SELECT count(*) FROM pg_policies
           WHERE schemaname = 'storage' AND tablename = 'objects'
             AND policyname = 'unrelated bucket access'), 1::bigint,
  'finalization preserves unrelated bucket policies');
SELECT is((SELECT count(*) FROM pg_policies
           WHERE schemaname = 'storage' AND tablename = 'objects'
             AND permissive = 'PERMISSIVE'
             AND roles && ARRAY['public', 'anon', 'authenticated']::name[]
             AND COALESCE(qual, with_check, '') ~
                 'bucket_id = ''comment-images''::text'), 0::bigint,
  'no remaining policy directly grants comment-images access');

SELECT throws_ok(
  $$SELECT public.queue_legacy_comment_image_cleanup(
      ARRAY['quota/2.png'], '31000000-0000-4000-8000-000000000001')$$,
  '23505', 'legacy cleanup key belongs to live metadata',
  'legacy zero-byte cleanup cannot collide with live metadata');

DELETE FROM public.comment_images WHERE object_key = 'quota/1.png';
SELECT is((SELECT count(*) FROM public.comment_image_cleanup_queue
           WHERE object_key = 'quota/1.png'), 1::bigint,
  'metadata deletion durably queues storage cleanup');
SELECT is((SELECT byte_size FROM public.comment_image_cleanup_queue
           WHERE object_key = 'quota/1.png'), 5242880,
  'cascading metadata deletion preserves the actual byte charge');
SELECT throws_ok(
  $$INSERT INTO public.comment_images(comment_id, task_id, user_id, object_key, mime_type, byte_size)
    VALUES ('35000000-0000-4000-8000-000000000005', '33000000-0000-4000-8000-000000000003',
      '31000000-0000-4000-8000-000000000001', 'still-over-quota.png', 'image/png', 1)$$,
  'P0001', 'comment image quota exceeded',
  'queued cleanup continues consuming quota');

SELECT public.finish_comment_image_cleanup('quota/1.png');
SELECT is((SELECT count(*) FROM public.comment_image_cleanup_queue
           WHERE object_key = 'quota/1.png'), 0::bigint,
  'confirmed storage cleanup releases its durable quota record');

SELECT public.queue_legacy_comment_image_cleanup(
  ARRAY['reserved-key.png'], '31000000-0000-4000-8000-000000000001');
SELECT throws_ok(
  $$INSERT INTO public.comment_images(comment_id, task_id, user_id, object_key, mime_type, byte_size)
    VALUES ('35000000-0000-4000-8000-000000000005', '33000000-0000-4000-8000-000000000003',
      '31000000-0000-4000-8000-000000000001', 'reserved-key.png', 'image/png', 1)$$,
  '23505', 'comment image object key is pending cleanup',
  'live metadata cannot reuse a queued object key');

UPDATE public.comments SET images = ARRAY[
  'https://project.supabase.co/storage/v1/object/public/comment-images/31000000-0000-4000-8000-000000000001/legacy.png'
] WHERE id = '35000000-0000-4000-8000-000000000005';
INSERT INTO public.comment_images(id, comment_id, task_id, user_id, object_key, mime_type, byte_size)
VALUES ('37000000-0000-4000-8000-000000000007',
  '35000000-0000-4000-8000-000000000005', '33000000-0000-4000-8000-000000000003',
  '31000000-0000-4000-8000-000000000001', 'referenced.png', 'image/png', 10);
UPDATE public.comments SET images = ARRAY[
  '37000000-0000-4000-8000-000000000007',
  'https://project.supabase.co/storage/v1/object/public/comment-images/31000000-0000-4000-8000-000000000001/legacy.png'
] WHERE id = '35000000-0000-4000-8000-000000000005';
UPDATE public.comments SET images = '{}' WHERE id = '35000000-0000-4000-8000-000000000005';
SELECT is((SELECT count(*) FROM public.comment_image_cleanup_queue
           WHERE object_key = 'referenced.png'), 1::bigint,
  'persisting opaque reference removal durably queues cleanup');
SELECT is((SELECT count(*) FROM public.comment_image_cleanup_queue
           WHERE object_key = '31000000-0000-4000-8000-000000000001/legacy.png'), 1::bigint,
  'persisting legacy reference removal durably queues cleanup');
SELECT is((SELECT count(*) FROM public.comment_images
           WHERE id = '37000000-0000-4000-8000-000000000007'), 0::bigint,
  'removed opaque metadata is no longer live');

SELECT * FROM finish();
ROLLBACK;
