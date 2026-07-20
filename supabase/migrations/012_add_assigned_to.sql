-- Add assigned_to column to tasks table
ALTER TABLE public.tasks
ADD COLUMN assigned_to TEXT NOT NULL DEFAULT 'manuel';

-- Add index for filtering by assignee
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks(assigned_to);

-- Add check constraint for valid assignee values
ALTER TABLE public.tasks
ADD CONSTRAINT valid_assignee CHECK (assigned_to IN ('manuel', 'hermes', 'claude'));
