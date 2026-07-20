# Database migrations

Supabase migrations are applied locally with `supabase db reset` and to the
linked project with `supabase db push`. Do not put `CREATE INDEX CONCURRENTLY`
in a migration: PostgreSQL rejects it when the migration runner uses a
transaction.

## Migration 017 production pre-step

Migration 017 can create its supporting indexes on an empty database, so local
resets need no special handling. On every populated environment, build the
indexes before `supabase db push`:

```bash
read -rsp 'Direct database URL: ' DATABASE_URL; echo
export DATABASE_URL
./scripts/prepare-tenant-ownership-indexes.sh
unset DATABASE_URL
supabase db push
```

Use the direct Postgres connection (port 5432), with its password percent
encoded. Do not use the transaction-pooler endpoint. The script reports only a
cross-tenant relation count, stops without creating indexes if that count is
nonzero, refuses a non-unique/invalid same-named index, and verifies both
concurrent builds before declaring success. It does not apply the migration.

An interrupted concurrent build can leave an invalid index. Confirm it is the
invalid migration index, remove it outside a transaction, and rerun the script:

```sql
SELECT c.relname, i.indisunique, i.indisvalid
FROM pg_index AS i
JOIN pg_class AS c ON c.oid = i.indexrelid
WHERE c.oid IN (
  to_regclass('public.projects_id_user_id_key'),
  to_regclass('public.tasks_id_user_id_key')
);

DROP INDEX CONCURRENTLY IF EXISTS public.projects_id_user_id_key;
DROP INDEX CONCURRENTLY IF EXISTS public.tasks_id_user_id_key;
```

Only run the two `DROP INDEX` statements for indexes reported as invalid. Once
017 succeeds, they are owned by unique constraints under new names and must not
be dropped directly.

## Comment image privacy rollout (migration 018 + guarded finalization)

This change is staged so existing comments and stored images are not rewritten
or lost:

1. Apply all committed migrations normally. Migration 018 adds metadata,
   durable storage cleanup, ownership, size, and quota enforcement while the
   old bucket remains public. There is deliberately no committed migration 019:
   the migration runner cannot stage two committed files.
2. Deploy the `comment-images` Edge Function, then release a compatible client.
   New uploads use opaque IDs. Existing public URL values are authorized against
   their owning comment and exchanged for short-lived signed URLs.
3. After supported clients have upgraded and the function is live, run the
   guarded, one-way operational finalization with the direct database URL:

```bash
read -rsp 'Direct database URL: ' DATABASE_URL; echo
export DATABASE_URL
./scripts/finalize-comment-image-privacy.sh --confirm-compatible-clients-and-function
unset DATABASE_URL
```

The command refuses to run without the explicit confirmation flag, executes the
lockdown and verification in one transaction, and fails unless the bucket is
private and all four legacy policies are absent. The pgTAP suite exercises the
same guarded database function and final private state. Do not leave step 3 as
an open-ended follow-up; it is a required release operation.

Authenticated function traffic reconciles durable cleanup records in bounded
batches. Operators can also trigger a user's reconciliation with
`POST /comment-images?action=reconcile` using that user's valid bearer token.
Failed or ambiguous uploads/deletes retain their metadata or cleanup record and
continue consuming quota until storage deletion is confirmed.

For scheduled/global cleanup (including deleted users), invoke
`POST /comment-images?action=reconcile-global` with the service-role bearer
token from a secret-bearing server or scheduler. It processes at most 100 keys
per call; repeat until `attempted` is zero. Never put this token in a client,
command line argument, log, or source file.
