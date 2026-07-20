-- Store an optional local time (HH:MM) alongside the task due date.
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS due_time TEXT;
