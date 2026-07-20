-- API Keys Table for MCP Authentication
-- Users can generate API keys to authenticate MCP servers

-- ============================================
-- API_KEYS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    key_hash TEXT NOT NULL,                          -- SHA-256 hash of the API key (never store plain key)
    key_prefix TEXT NOT NULL,                        -- First 8 chars for identification (tk_xxxxxxxx)
    name TEXT NOT NULL DEFAULT 'MCP',                -- User-friendly name
    last_used_at TIMESTAMPTZ,                        -- Track last usage
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on api_keys
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

-- API Keys policies - users can only manage their own keys
CREATE POLICY "Users can view their own API keys"
    ON public.api_keys FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own API keys"
    ON public.api_keys FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own API keys"
    ON public.api_keys FOR DELETE
    USING (auth.uid() = user_id);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON public.api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_key_hash ON public.api_keys(key_hash);

-- Function to update last_used_at timestamp (called by Edge Function)
CREATE OR REPLACE FUNCTION public.update_api_key_last_used(p_key_hash TEXT)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    UPDATE public.api_keys
    SET last_used_at = NOW()
    WHERE key_hash = p_key_hash
    RETURNING user_id INTO v_user_id;

    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
