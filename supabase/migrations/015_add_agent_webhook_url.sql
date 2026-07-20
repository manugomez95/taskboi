-- Add agent_webhook_url column to profiles table (global webhook)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS agent_webhook_url TEXT DEFAULT '';

-- Add agent_webhook_url column to projects table (per-project override)
ALTER TABLE projects ADD COLUMN IF NOT EXISTS agent_webhook_url TEXT DEFAULT '';
