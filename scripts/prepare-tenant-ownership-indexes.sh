#!/usr/bin/env bash

# Required before migration 017 on a populated database. PostgreSQL forbids
# CREATE INDEX CONCURRENTLY inside a transaction, so this is intentionally an
# explicit operator step and is never called by the deploy script.

set -euo pipefail

if [ "$#" -ne 0 ]; then
    echo "Usage: DATABASE_URL=<percent-encoded-direct-database-url> $0" >&2
    exit 64
fi

if [ -z "${DATABASE_URL:-}" ]; then
    echo "DATABASE_URL is required" >&2
    exit 64
fi

if ! command -v psql >/dev/null 2>&1; then
    echo "psql is required" >&2
    exit 69
fi

invalid_count=$(psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -Atqc "
SELECT COUNT(*) FROM (
    SELECT 1 FROM public.tasks t JOIN public.projects p ON p.id = t.project_id WHERE p.user_id <> t.user_id
    UNION ALL
    SELECT 1 FROM public.tasks t JOIN public.tasks p ON p.id = t.parent_id WHERE p.user_id <> t.user_id
    UNION ALL
    SELECT 1 FROM public.tasks t JOIN public.tasks p ON p.id = t.recurrence_parent_id WHERE p.user_id <> t.user_id
    UNION ALL
    SELECT 1 FROM public.comments c JOIN public.tasks t ON t.id = c.task_id WHERE t.user_id <> c.user_id
) invalid_relations")

if ! [[ "$invalid_count" =~ ^[0-9]+$ ]]; then
    echo "Preflight did not return a count; refusing to continue" >&2
    exit 1
fi
if [ "$invalid_count" -ne 0 ]; then
    echo "Preflight failed: $invalid_count cross-tenant relation(s); no indexes were created" >&2
    exit 1
fi

for index_name in projects_id_user_id_key tasks_id_user_id_key; do
    index_state=$(psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -Atqc "
SELECT CASE
    WHEN to_regclass('public.${index_name}') IS NULL THEN 'missing'
    WHEN EXISTS (
        SELECT 1 FROM pg_index
        WHERE indexrelid = 'public.${index_name}'::regclass
          AND indisunique AND indisvalid
    ) THEN 'ready'
    ELSE 'invalid'
END")
    if [ "$index_state" = invalid ]; then
        echo "$index_name exists but is not a valid unique index; refusing to continue" >&2
        exit 1
    fi
done

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c \
    'CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS projects_id_user_id_key ON public.projects (id, user_id)'
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c \
    'CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS tasks_id_user_id_key ON public.tasks (id, user_id)'

ready_count=$(psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -Atqc "
SELECT COUNT(*) FROM pg_index
WHERE indexrelid IN (
    'public.projects_id_user_id_key'::regclass,
    'public.tasks_id_user_id_key'::regclass
) AND indisunique AND indisvalid")

if [ "$ready_count" -ne 2 ]; then
    echo "Concurrent index preparation did not produce two valid unique indexes" >&2
    exit 1
fi

echo "Tenant ownership preflight passed and both indexes are ready."
echo "Next: supabase db push"
