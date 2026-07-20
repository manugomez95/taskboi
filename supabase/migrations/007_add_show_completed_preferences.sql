-- Add show_completed_preferences column to profiles table
-- Stores per-view show completed settings as JSONB (e.g., {"today": true, "project_xxx": false})

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS show_completed_preferences JSONB DEFAULT '{}'::jsonb;

-- Add comment for documentation
COMMENT ON COLUMN profiles.show_completed_preferences IS 'Per-view show completed task preferences as JSON map';
