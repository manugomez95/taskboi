-- Add recurrence_anchor_date column to tasks
-- This tracks the original schedule for recurring tasks, ensuring that
-- rescheduling a single instance doesn't shift all future occurrences

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS recurrence_anchor_date DATE;

-- Backfill existing recurring tasks with their current due_date as anchor
-- This ensures backward compatibility for tasks created before this migration
UPDATE public.tasks
SET recurrence_anchor_date = due_date
WHERE recurrence_rule IS NOT NULL AND recurrence_anchor_date IS NULL;
