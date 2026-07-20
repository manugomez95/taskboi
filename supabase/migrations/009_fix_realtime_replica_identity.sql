-- Fix Realtime Sync - REPLICA IDENTITY
--
-- Problem: Supabase Realtime with row-level filters (e.g., user_id = X)
-- requires the table to have REPLICA IDENTITY FULL so that all column
-- values are included in change events, not just the primary key.
--
-- Without this, the realtime subscription filter on user_id won't work
-- because the change payload only contains the id column.
--
-- This migration sets REPLICA IDENTITY FULL on all tables that use
-- user_id filtering for realtime subscriptions.

-- Set REPLICA IDENTITY FULL on tasks table
ALTER TABLE public.tasks REPLICA IDENTITY FULL;

-- Set REPLICA IDENTITY FULL on projects table
ALTER TABLE public.projects REPLICA IDENTITY FULL;

-- Set REPLICA IDENTITY FULL on comments table
ALTER TABLE public.comments REPLICA IDENTITY FULL;

-- Note: profiles table doesn't need this as it uses id = auth.uid() for filtering
