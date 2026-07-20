-- Add theme mode preference (light/dark/system)
-- This allows users to override system appearance and sync across devices

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS theme_mode TEXT NOT NULL DEFAULT 'system';

COMMENT ON COLUMN public.profiles.theme_mode IS 'User appearance mode preference: system, light, or dark';
