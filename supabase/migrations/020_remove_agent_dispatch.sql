-- Remove the retired fixed-assignee and agent webhook dispatch schema.
-- Existing task and project records remain intact; only dispatch metadata is
-- discarded.

DROP INDEX IF EXISTS public.idx_tasks_assigned_to;
DROP INDEX IF EXISTS public.idx_projects_default_assignee;

ALTER TABLE public.tasks
  DROP COLUMN IF EXISTS assigned_to;

ALTER TABLE public.projects
  DROP COLUMN IF EXISTS default_assignee,
  DROP COLUMN IF EXISTS agent_webhook_url;

ALTER TABLE public.profiles
  DROP COLUMN IF EXISTS agent_webhook_url;
