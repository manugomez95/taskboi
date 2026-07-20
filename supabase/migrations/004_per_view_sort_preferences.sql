-- Add per-view sort preferences as JSONB
-- This allows users to have different sort preferences for each view (today, upcoming, inbox, per-project)

-- Add sort_preferences JSONB column (keeps existing sort_preference for backward compatibility)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS sort_preferences JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.profiles.sort_preferences IS 'Per-view sort preferences as JSON object. Keys: today, upcoming, inbox, project_{id}. Values: manual, priority, dueDate, title, createdAt';
