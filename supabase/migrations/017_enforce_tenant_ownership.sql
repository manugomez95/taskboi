-- Enforce tenant ownership across relationships that clients can supply.
--
-- Supabase CLI migrations may execute in a transaction, so CREATE INDEX
-- CONCURRENTLY is deliberately not used here. Empty databases (including
-- `supabase db reset`) build the indexes below. Populated environments must run
-- scripts/prepare-tenant-ownership-indexes.sh before applying this migration.

DO $preflight$
DECLARE
    invalid_relation_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO invalid_relation_count
    FROM (
        SELECT 1
        FROM public.tasks AS task
        JOIN public.projects AS project ON project.id = task.project_id
        WHERE project.user_id <> task.user_id
        UNION ALL
        SELECT 1
        FROM public.tasks AS task
        JOIN public.tasks AS parent ON parent.id = task.parent_id
        WHERE parent.user_id <> task.user_id
        UNION ALL
        SELECT 1
        FROM public.tasks AS task
        JOIN public.tasks AS recurrence_parent
          ON recurrence_parent.id = task.recurrence_parent_id
        WHERE recurrence_parent.user_id <> task.user_id
        UNION ALL
        SELECT 1
        FROM public.comments AS comment
        JOIN public.tasks AS task ON task.id = comment.task_id
        WHERE task.user_id <> comment.user_id
    ) AS invalid_relations;

    IF invalid_relation_count <> 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = '23514',
            MESSAGE = format(
                'tenant ownership preflight failed: %s cross-tenant relation(s)',
                invalid_relation_count
            );
    END IF;
END
$preflight$;

-- A normal index build is acceptable on a fresh database. Refuse to do one on
-- populated tables: production indexes must be prepared concurrently outside
-- this transaction-managed migration.
DO $indexes$
BEGIN
    IF to_regclass('public.projects_id_user_id_key') IS NULL THEN
        IF EXISTS (SELECT 1 FROM public.projects LIMIT 1) THEN
            RAISE EXCEPTION
                'projects_id_user_id_key is missing; run scripts/prepare-tenant-ownership-indexes.sh before this migration';
        END IF;
        CREATE UNIQUE INDEX projects_id_user_id_key
            ON public.projects (id, user_id);
    END IF;

    IF to_regclass('public.tasks_id_user_id_key') IS NULL THEN
        IF EXISTS (SELECT 1 FROM public.tasks LIMIT 1) THEN
            RAISE EXCEPTION
                'tasks_id_user_id_key is missing; run scripts/prepare-tenant-ownership-indexes.sh before this migration';
        END IF;
        CREATE UNIQUE INDEX tasks_id_user_id_key
            ON public.tasks (id, user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_index
        WHERE indexrelid = 'public.projects_id_user_id_key'::regclass
          AND indisunique AND indisvalid
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_index
        WHERE indexrelid = 'public.tasks_id_user_id_key'::regclass
          AND indisunique AND indisvalid
    ) THEN
        RAISE EXCEPTION 'tenant ownership indexes must be valid and unique';
    END IF;
END
$indexes$;

ALTER TABLE public.projects
    ADD CONSTRAINT projects_id_user_id_unique
    UNIQUE USING INDEX projects_id_user_id_key;

ALTER TABLE public.tasks
    ADD CONSTRAINT tasks_id_user_id_unique
    UNIQUE USING INDEX tasks_id_user_id_key;

-- NOT VALID keeps constraint installation short. Validation is staged after
-- all constraints exist; new writes are enforced immediately.
ALTER TABLE public.tasks
    ADD CONSTRAINT tasks_project_owner_fkey
        FOREIGN KEY (project_id, user_id)
        REFERENCES public.projects (id, user_id)
        ON DELETE CASCADE NOT VALID,
    ADD CONSTRAINT tasks_parent_owner_fkey
        FOREIGN KEY (parent_id, user_id)
        REFERENCES public.tasks (id, user_id)
        ON DELETE CASCADE NOT VALID,
    ADD CONSTRAINT tasks_recurrence_parent_owner_fkey
        FOREIGN KEY (recurrence_parent_id, user_id)
        REFERENCES public.tasks (id, user_id)
        ON DELETE SET NULL (recurrence_parent_id) NOT VALID;

ALTER TABLE public.comments
    ADD CONSTRAINT comments_task_owner_fkey
        FOREIGN KEY (task_id, user_id)
        REFERENCES public.tasks (id, user_id)
        ON DELETE CASCADE NOT VALID;

ALTER TABLE public.tasks VALIDATE CONSTRAINT tasks_project_owner_fkey;
ALTER TABLE public.tasks VALIDATE CONSTRAINT tasks_parent_owner_fkey;
ALTER TABLE public.tasks VALIDATE CONSTRAINT tasks_recurrence_parent_owner_fkey;
ALTER TABLE public.comments VALIDATE CONSTRAINT comments_task_owner_fkey;

COMMENT ON CONSTRAINT tasks_project_owner_fkey ON public.tasks IS
    'A task and its project must belong to the same user.';
COMMENT ON CONSTRAINT tasks_parent_owner_fkey ON public.tasks IS
    'A subtask and its parent must belong to the same user.';
COMMENT ON CONSTRAINT tasks_recurrence_parent_owner_fkey ON public.tasks IS
    'A recurring occurrence and its series parent must belong to the same user.';
COMMENT ON CONSTRAINT comments_task_owner_fkey ON public.comments IS
    'A comment and its task must belong to the same user.';
