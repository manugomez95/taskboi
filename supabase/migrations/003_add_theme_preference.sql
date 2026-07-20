-- Add user preferences to profiles table
-- This allows users to sync their preferences across devices

-- Theme preference
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS theme TEXT NOT NULL DEFAULT 'default';

COMMENT ON COLUMN public.profiles.theme IS 'User selected theme identifier (e.g., default, blue, green, purple)';

-- Sort preference for task lists
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS sort_preference TEXT NOT NULL DEFAULT 'manual';

COMMENT ON COLUMN public.profiles.sort_preference IS 'User selected task sort option (manual, priority, dueDate, title, createdAt)';
