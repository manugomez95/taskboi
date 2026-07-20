ALTER TABLE public.projects
ADD COLUMN default_assignee TEXT NOT NULL DEFAULT 'manuel';

CREATE INDEX IF NOT EXISTS idx_projects_default_assignee ON public.projects(default_assignee);

ALTER TABLE public.projects
ADD CONSTRAINT valid_default_assignee CHECK (default_assignee IN ('manuel', 'hermes'));
