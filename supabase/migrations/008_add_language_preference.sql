-- Add language preference
-- This allows users to override system locale and sync across devices

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS language TEXT NOT NULL DEFAULT 'system';

COMMENT ON COLUMN public.profiles.language IS 'User language preference: system (use device locale), en, es, etc.';
