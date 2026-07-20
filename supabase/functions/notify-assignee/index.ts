import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { deliverWebhook } from "./delivery.ts";
import { handleNotify } from "./handler.ts";

Deno.serve(async (req: Request) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const webhookSecret = Deno.env.get("DATABASE_WEBHOOK_SECRET") ?? "";
  if (!supabaseUrl || !serviceRoleKey || webhookSecret.length < 32) {
    return new Response('{"error":"server configuration incomplete"}', {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  try {
    return await handleNotify(req, {
      secret: webhookSecret,
      async loadTask(id) {
        const { data, error } = await supabase.from("tasks").select(
          "id,title,description,assigned_to,priority,project_id,user_id,created_at,updated_at",
        ).eq("id", id).maybeSingle();
        if (error) throw error;
        return data;
      },
      async loadProject(id) {
        const { data, error } = await supabase.from("projects").select(
          "id,user_id,name,agent_webhook_url",
        ).eq("id", id).maybeSingle();
        if (error) throw error;
        return data;
      },
      async loadProfileWebhook(userId) {
        const { data, error } = await supabase.from("profiles").select(
          "agent_webhook_url",
        ).eq("id", userId).maybeSingle();
        if (error) throw error;
        return data?.agent_webhook_url ?? null;
      },
      deliver: (url, payload) => deliverWebhook(url, payload),
      log: (message, fields) => console.error(message, fields ?? {}),
    });
  } catch {
    console.error("notify-assignee request failed");
    return new Response('{"error":"internal server error"}', {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
      },
    });
  }
});
