// MCP API Edge Function for Taskboi
// Provides REST API for MCP servers authenticated via API keys
// deno-lint-ignore-file no-explicit-any

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
};

// Hash API key using SHA-256
async function hashApiKey(key: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(key);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

// Validate API key and get user_id
async function validateApiKey(
  supabase: ReturnType<typeof createClient<any>>,
  apiKey: string
): Promise<string | null> {
  const keyHash = await hashApiKey(apiKey);

  // Use service role to bypass RLS for key validation
  const { data, error } = await supabase.rpc("update_api_key_last_used", {
    p_key_hash: keyHash,
  });

  if (error || !data) {
    return null;
  }

  return data as string;
}

// Create response helper
function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ error: message }, status);
}

// ============================================
// ROUTE HANDLERS
// ============================================

// GET /projects - List all projects
async function listProjects(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string
): Promise<Response> {
  const { data, error } = await supabase
    .from("projects")
    .select("*")
    .eq("user_id", userId)
    .order("sort_order", { ascending: true });

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ projects: data });
}

// POST /projects - Create a project
async function createProject(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  body: { name: string; color?: string; icon?: string; defaultAssignee?: string; agentWebhookUrl?: string }
): Promise<Response> {
  if (!body.name) return errorResponse("name is required");
  if (
    body.defaultAssignee !== undefined &&
    !["manuel", "hermes"].includes(body.defaultAssignee)
  ) {
    return errorResponse("defaultAssignee must be 'manuel' or 'hermes'");
  }

  // Get max sort order
  const { data: maxOrder } = await supabase
    .from("projects")
    .select("sort_order")
    .eq("user_id", userId)
    .order("sort_order", { ascending: false })
    .limit(1)
    .maybeSingle();

  const sortOrder = ((maxOrder?.sort_order as number) ?? -1) + 1;

  const { data, error } = await supabase
    .from("projects")
    .insert({
      user_id: userId,
      name: body.name,
      color: body.color ?? "#6B7280",
      icon: body.icon ?? "folder",
      sort_order: sortOrder,
      default_assignee: body.defaultAssignee ?? "manuel",
      agent_webhook_url: body.agentWebhookUrl ?? "",
    })
    .select()
    .single();

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ project: data }, 201);
}

// GET /projects/:id - Get a single project
async function getProject(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  projectId: string
): Promise<Response> {
  const { data, error } = await supabase
    .from("projects")
    .select("*")
    .eq("id", projectId)
    .eq("user_id", userId)
    .single();

  if (error) return errorResponse("Project not found", 404);
  return jsonResponse({ project: data });
}

// PATCH /projects/:id - Update a project
async function updateProject(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  projectId: string,
  body: { name?: string; color?: string; icon?: string; defaultAssignee?: string; agentWebhookUrl?: string }
): Promise<Response> {
  const updates: Record<string, unknown> = {};
  if (body.name !== undefined) updates.name = body.name;
  if (body.color !== undefined) updates.color = body.color;
  if (body.icon !== undefined) updates.icon = body.icon;
  if (body.defaultAssignee !== undefined) {
    if (!["manuel", "hermes"].includes(body.defaultAssignee)) {
      return errorResponse("defaultAssignee must be 'manuel' or 'hermes'");
    }
    updates.default_assignee = body.defaultAssignee;
  }
  if (body.agentWebhookUrl !== undefined) updates.agent_webhook_url = body.agentWebhookUrl;

  if (Object.keys(updates).length === 0) {
    return errorResponse("No fields to update");
  }

  const { data, error } = await supabase
    .from("projects")
    .update(updates)
    .eq("id", projectId)
    .eq("user_id", userId)
    .select()
    .single();

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ project: data });
}

// DELETE /projects/:id - Delete a project
async function deleteProject(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  projectId: string
): Promise<Response> {
  // Don't allow deleting inbox
  const { data: project } = await supabase
    .from("projects")
    .select("is_inbox")
    .eq("id", projectId)
    .eq("user_id", userId)
    .single();

  if (project?.is_inbox) {
    return errorResponse("Cannot delete inbox project", 400);
  }

  const { error } = await supabase
    .from("projects")
    .delete()
    .eq("id", projectId)
    .eq("user_id", userId);

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ success: true });
}

// GET /projects/inbox - Get inbox project
async function getInboxProject(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string
): Promise<Response> {
  const { data, error } = await supabase
    .from("projects")
    .select("*")
    .eq("user_id", userId)
    .eq("is_inbox", true)
    .single();

  if (error) return errorResponse("Inbox not found", 404);
  return jsonResponse({ project: data });
}

// GET /tasks - List tasks
async function listTasks(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  projectId?: string
): Promise<Response> {
  let query = supabase.from("tasks").select("*").eq("user_id", userId);

  if (projectId) {
    query = query.eq("project_id", projectId);
  }

  const { data, error } = await query
    .order("is_completed", { ascending: true })
    .order("sort_order", { ascending: true });

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ tasks: data });
}

// POST /tasks - Create a task
async function createTask(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  body: {
    projectId: string;
    title: string;
    description?: string;
    dueDate?: string;
    dueTime?: string;
    priority?: number;
    parentId?: string;
    recurrenceRule?: string;
    assignedTo?: string;
  }
): Promise<Response> {
  if (!body.projectId) return errorResponse("projectId is required");
  if (!body.title) return errorResponse("title is required");

  // This client uses the service role and therefore bypasses RLS. Validate
  // tenant-owned references here for a useful response; composite database
  // foreign keys enforce the same invariant for every write path.
  const { data: project, error: projectError } = await supabase
    .from("projects")
    .select("id")
    .eq("id", body.projectId)
    .eq("user_id", userId)
    .maybeSingle();
  if (projectError) return errorResponse(projectError.message, 500);
  if (!project) return errorResponse("Project not found", 404);

  if (body.parentId !== undefined) {
    const { data: parent, error: parentError } = await supabase
      .from("tasks")
      .select("id")
      .eq("id", body.parentId)
      .eq("user_id", userId)
      .maybeSingle();
    if (parentError) return errorResponse(parentError.message, 500);
    if (!parent) return errorResponse("Parent task not found", 404);
  }

  // Validate priority
  const priority = body.priority ?? 0;
  if (priority < 0 || priority > 4) {
    return errorResponse("priority must be between 0 and 4");
  }

  // Validate assignee
  const assignedTo = body.assignedTo ?? "manuel";
  if (!["manuel", "hermes", "claude"].includes(assignedTo)) {
    return errorResponse("assignee must be one of: manuel, hermes, claude");
  }

  // Validate dueTime format (HH:MM) if provided
  if (body.dueTime !== undefined && body.dueTime !== null) {
    if (!/^\d{2}:\d{2}$/.test(body.dueTime)) {
      return errorResponse("dueTime must be in HH:MM format");
    }
  }

  // Get max sort order
  const { data: maxOrder } = await supabase
    .from("tasks")
    .select("sort_order")
    .eq("project_id", body.projectId)
    .order("sort_order", { ascending: false })
    .limit(1)
    .maybeSingle();

  const sortOrder = ((maxOrder?.sort_order as number) ?? -1) + 1;

  const { data, error } = await supabase
    .from("tasks")
    .insert({
      project_id: body.projectId,
      user_id: userId,
      parent_id: body.parentId,
      title: body.title,
      description: body.description,
      due_date: body.dueDate,
      due_time: body.dueTime,
      priority,
      sort_order: sortOrder,
      recurrence_rule: body.recurrenceRule,
      assigned_to: assignedTo,
    })
    .select()
    .single();

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ task: data }, 201);
}

// GET /tasks/:id - Get a single task
async function getTask(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  taskId: string
): Promise<Response> {
  const { data, error } = await supabase
    .from("tasks")
    .select("*")
    .eq("id", taskId)
    .eq("user_id", userId)
    .single();

  if (error) return errorResponse("Task not found", 404);
  return jsonResponse({ task: data });
}

// PATCH /tasks/:id - Update a task
async function updateTask(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  taskId: string,
  body: {
    title?: string;
    description?: string;
    dueDate?: string;
    dueTime?: string;
    priority?: number;
    projectId?: string;
    recurrenceRule?: string;
    assignedTo?: string;
  }
): Promise<Response> {
  const updates: Record<string, unknown> = {};
  if (body.title !== undefined) updates.title = body.title;
  if (body.description !== undefined) updates.description = body.description;
  if (body.dueDate !== undefined) updates.due_date = body.dueDate;
  if (body.dueTime !== undefined) {
    if (body.dueTime !== null && !/^\d{2}:\d{2}$/.test(body.dueTime)) {
      return errorResponse("dueTime must be in HH:MM format");
    }
    updates.due_time = body.dueTime;
  }
  if (body.priority !== undefined) {
    if (body.priority < 0 || body.priority > 4) {
      return errorResponse("priority must be between 0 and 4");
    }
    updates.priority = body.priority;
  }
  if (body.projectId !== undefined) updates.project_id = body.projectId;
  if (body.recurrenceRule !== undefined) updates.recurrence_rule = body.recurrenceRule;
  if (body.assignedTo !== undefined) {
    if (!["manuel", "hermes", "claude"].includes(body.assignedTo)) {
      return errorResponse("assignee must be one of: manuel, hermes, claude");
    }
    updates.assigned_to = body.assignedTo;
  }

  if (Object.keys(updates).length === 0) {
    return errorResponse("No fields to update");
  }

  // Validate every destination project because this service-role client
  // bypasses RLS. If the caller did not choose an assignee, inherit the
  // tenant-owned destination project's default.
  if (body.projectId !== undefined) {
    const { data: destProject, error: projError } = await supabase
      .from("projects")
      .select("default_assignee")
      .eq("id", body.projectId)
      .eq("user_id", userId)
      .maybeSingle();

    if (projError) {
      return errorResponse(projError.message, 500);
    }
    if (!destProject) {
      return errorResponse("Destination project not found", 404);
    }
    if (body.assignedTo === undefined && destProject.default_assignee) {
      updates.assigned_to = destProject.default_assignee;
    }
  }

  const { data, error } = await supabase
    .from("tasks")
    .update(updates)
    .eq("id", taskId)
    .eq("user_id", userId)
    .select()
    .single();

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ task: data });
}

// ============================================
// RECURRING OCCURRENCE IDS
// ============================================
// Deterministic UUIDv5 ids for spawned recurring occurrences. These MUST match
// the Flutter app's scheme (lib/features/tasks/providers/tasks_provider.dart —
// _recurringOccurrenceId / _dateKey) so completing a recurring task via the app
// and via this API produces the SAME occurrence id. A duplicate insert then
// collides on the primary key instead of silently creating a second row.

// RFC 4122 URL namespace (== the Dart uuid package's Namespace.url).
const UUID_URL_NAMESPACE = "6ba7b811-9dad-11d1-80b4-00c04fd430c8";

function uuidHexToBytes(uuid: string): Uint8Array {
  const hex = uuid.replace(/-/g, "");
  const bytes = new Uint8Array(16);
  for (let i = 0; i < 16; i++) {
    bytes[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

function bytesToUuid(bytes: Uint8Array): string {
  const hex = Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return (
    `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-` +
    `${hex.slice(16, 20)}-${hex.slice(20, 32)}`
  );
}

// SHA-1 based UUIDv5, byte-for-byte compatible with the Dart uuid package's v5.
async function uuidV5(namespace: string, name: string): Promise<string> {
  const nsBytes = uuidHexToBytes(namespace);
  const nameBytes = new TextEncoder().encode(name);
  const data = new Uint8Array(nsBytes.length + nameBytes.length);
  data.set(nsBytes, 0);
  data.set(nameBytes, nsBytes.length);

  const hashBuffer = await crypto.subtle.digest("SHA-1", data);
  const hash = new Uint8Array(hashBuffer).slice(0, 16);
  hash[6] = (hash[6] & 0x0f) | 0x50; // version 5
  hash[8] = (hash[8] & 0x3f) | 0x80; // RFC 4122 variant
  return bytesToUuid(hash);
}

// Matches _recurringOccurrenceId(seriesId, date) + _dateKey in the Flutter app.
function recurringOccurrenceId(
  seriesId: string,
  occurrenceDate: string,
): Promise<string> {
  return uuidV5(
    UUID_URL_NAMESPACE,
    `taskboi:recurring-occurrence:v1:${seriesId}:${occurrenceDate}`,
  );
}

// POST /tasks/:id/complete - Complete a task
async function completeTask(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  taskId: string
): Promise<Response> {
  // Get the task first to check for recurrence
  const { data: task, error: fetchError } = await supabase
    .from("tasks")
    .select("*")
    .eq("id", taskId)
    .eq("user_id", userId)
    .single();

  if (fetchError) return errorResponse("Task not found", 404);

  // Mark as completed
  const { error: updateError } = await supabase
    .from("tasks")
    .update({
      is_completed: true,
      completed_at: new Date().toISOString(),
    })
    .eq("id", taskId);

  if (updateError) return errorResponse(updateError.message, 500);

  // If recurring, create the next occurrence — idempotently. The occurrence id
  // is a deterministic UUIDv5 (see recurringOccurrenceId) identical to what the
  // Flutter app computes, and we skip creation when the series already has an
  // active (incomplete) occurrence. Together these enforce "one active instance
  // per recurring series" even when a task is completed via both the app and
  // this API.
  let nextTask = null;
  if (task.recurrence_rule && task.due_date) {
    // Use anchor date for calculating next occurrence to preserve the original schedule
    // This ensures rescheduling a single instance doesn't shift all future occurrences
    // Fall back to dueDate for backward compatibility with tasks created before anchor support
    const anchorDate = task.recurrence_anchor_date
      ? new Date(task.recurrence_anchor_date)
      : new Date(task.due_date);

    const nextDueDate = getNextOccurrence(anchorDate, task.recurrence_rule);
    if (nextDueDate) {
      const seriesId = task.recurrence_parent_id ?? taskId;

      // Dedup: reuse an existing active occurrence for this series instead of
      // creating a second one.
      const { data: existingOccurrence } = await supabase
        .from("tasks")
        .select("*")
        .eq("user_id", userId)
        .eq("recurrence_parent_id", seriesId)
        .eq("is_completed", false)
        .limit(1)
        .maybeSingle();

      if (existingOccurrence) {
        nextTask = existingOccurrence;
      } else {
        const occurrenceDate = nextDueDate.toISOString().split("T")[0];
        const occurrenceId = await recurringOccurrenceId(
          seriesId,
          occurrenceDate,
        );

        // Get max sort order
        const { data: maxOrder } = await supabase
          .from("tasks")
          .select("sort_order")
          .eq("project_id", task.project_id)
          .order("sort_order", { ascending: false })
          .limit(1)
          .maybeSingle();

        const sortOrder = ((maxOrder?.sort_order as number) ?? -1) + 1;

        const { data: newTask, error: insertError } = await supabase
          .from("tasks")
          .insert({
            id: occurrenceId,
            project_id: task.project_id,
            user_id: userId,
            title: task.title,
            description: task.description,
            due_date: occurrenceDate,
            priority: task.priority,
            sort_order: sortOrder,
            recurrence_rule: task.recurrence_rule,
            recurrence_anchor_date: occurrenceDate,
            recurrence_parent_id: seriesId,
          })
          .select()
          .single();

        if (insertError) {
          // 23505 = unique violation: the app (or a concurrent request) already
          // created this exact occurrence. Reuse it rather than failing.
          if (insertError.code === "23505") {
            const { data: raced } = await supabase
              .from("tasks")
              .select("*")
              .eq("id", occurrenceId)
              .maybeSingle();
            nextTask = raced;
          } else {
            return errorResponse(insertError.message, 500);
          }
        } else {
          nextTask = newTask;
        }
      }
    }
  }

  return jsonResponse({
    success: true,
    completedTask: { ...task, is_completed: true },
    nextTask,
  });
}

// POST /tasks/:id/uncomplete - Uncomplete a task
async function uncompleteTask(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  taskId: string
): Promise<Response> {
  const { data, error } = await supabase
    .from("tasks")
    .update({
      is_completed: false,
      completed_at: null,
    })
    .eq("id", taskId)
    .eq("user_id", userId)
    .select()
    .single();

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ task: data });
}

// DELETE /tasks/:id - Delete a task
async function deleteTask(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  taskId: string
): Promise<Response> {
  const { error } = await supabase
    .from("tasks")
    .delete()
    .eq("id", taskId)
    .eq("user_id", userId);

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ success: true });
}

// GET /tasks/today - Get tasks due today (including overdue and recurring with no due date)
async function getTodayTasks(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string
): Promise<Response> {
  const today = new Date();
  const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const todayEnd = new Date(todayStart);
  todayEnd.setDate(todayEnd.getDate() + 1);

  // Get tasks due today
  const { data: todayTasks, error: todayError } = await supabase
    .from("tasks")
    .select("*")
    .eq("user_id", userId)
    .gte("due_date", todayStart.toISOString().split("T")[0])
    .lt("due_date", todayEnd.toISOString().split("T")[0])
    .eq("is_completed", false)
    .is("parent_id", null)
    .order("priority", { ascending: false })
    .order("sort_order", { ascending: true });

  if (todayError) return errorResponse(todayError.message, 500);

  // Get overdue tasks (all overdue incomplete tasks, not just recurring)
  const { data: overdueTasks, error: overdueError } = await supabase
    .from("tasks")
    .select("*")
    .eq("user_id", userId)
    .lt("due_date", todayStart.toISOString().split("T")[0])
    .eq("is_completed", false)
    .is("parent_id", null);

  if (overdueError) return errorResponse(overdueError.message, 500);

  // Get recurring tasks with no due date (they should appear every day)
  const { data: recurringNoDueTasks, error: recurringError } = await supabase
    .from("tasks")
    .select("*")
    .eq("user_id", userId)
    .is("due_date", null)
    .not("recurrence_rule", "is", null)
    .eq("is_completed", false)
    .is("parent_id", null);

  if (recurringError) return errorResponse(recurringError.message, 500);

  // Combine and dedupe by id, then sort
  const taskMap = new Map<string, unknown>();
  [...(todayTasks ?? []), ...(overdueTasks ?? []), ...(recurringNoDueTasks ?? [])].forEach(
    (task) => taskMap.set(task.id, task)
  );
  const allTasks = Array.from(taskMap.values()) as Array<{
    id: string;
    priority?: number;
    sort_order?: number;
  }>;
  allTasks.sort((a, b) => {
    const priorityDiff = (b.priority ?? 0) - (a.priority ?? 0);
    if (priorityDiff !== 0) return priorityDiff;
    return (a.sort_order ?? 0) - (b.sort_order ?? 0);
  });

  return jsonResponse({ tasks: allTasks });
}

// GET /tasks/upcoming - Get upcoming tasks
async function getUpcomingTasks(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string
): Promise<Response> {
  const today = new Date();
  const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());

  const { data, error } = await supabase
    .from("tasks")
    .select("*")
    .eq("user_id", userId)
    .gte("due_date", todayStart.toISOString().split("T")[0])
    .eq("is_completed", false)
    .order("due_date", { ascending: true })
    .order("priority", { ascending: false });

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ tasks: data });
}

// GET /tasks/mine - Get my tasks (assigned to the given agent)
async function getMyTasks(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string
): Promise<Response> {
  const assignee = "hermes";
  const { data, error } = await supabase
    .from("tasks")
    .select("*")
    .eq("user_id", userId)
    .eq("assigned_to", assignee)
    .eq("is_completed", false)
    .order("priority", { ascending: false })
    .order("sort_order", { ascending: true });

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ tasks: data });
}

// GET /tasks/by-assignee?assignee=xxx - Get tasks by assignee
async function getTasksByAssignee(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  assignee: string
): Promise<Response> {
  if (!["manuel", "hermes", "claude"].includes(assignee)) {
    return errorResponse("assignee must be one of: manuel, hermes, claude");
  }
  const { data, error } = await supabase
    .from("tasks")
    .select("*")
    .eq("user_id", userId)
    .eq("assigned_to", assignee)
    .order("is_completed", { ascending: true })
    .order("sort_order", { ascending: true });

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ tasks: data });
}

// GET /tasks/:id/subtasks - Get subtasks
async function getSubtasks(
  supabase: ReturnType<typeof createClient<any>>,
  userId: string,
  parentId: string
): Promise<Response> {
  const { data, error } = await supabase
    .from("tasks")
    .select("*")
    .eq("user_id", userId)
    .eq("parent_id", parentId)
    .order("sort_order", { ascending: true });

  if (error) return errorResponse(error.message, 500);
  return jsonResponse({ tasks: data });
}

// ============================================
// RECURRENCE HELPER
// ============================================

// Calculate a single next occurrence from a given date
function getNextOccurrenceSingle(currentDate: Date, rule: string): Date | null {
  const parts = rule.split(";");
  const ruleMap: Record<string, string> = {};
  for (const part of parts) {
    const [key, value] = part.split("=");
    ruleMap[key] = value;
  }

  const freq = ruleMap["FREQ"];
  const interval = parseInt(ruleMap["INTERVAL"] ?? "1", 10);
  const nextDate = new Date(currentDate);

  switch (freq) {
    case "DAILY":
      nextDate.setDate(nextDate.getDate() + interval);
      break;
    case "WEEKLY": {
      const byDay = ruleMap["BYDAY"];
      if (byDay) {
        const days = byDay.split(",");
        const dayMap: Record<string, number> = {
          SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6,
        };
        const currentDayIndex = nextDate.getDay();
        const targetDays = days.map((d) => dayMap[d]).sort((a, b) => a - b);

        // Find next occurrence
        let found = false;
        for (const targetDay of targetDays) {
          if (targetDay > currentDayIndex) {
            nextDate.setDate(nextDate.getDate() + (targetDay - currentDayIndex));
            found = true;
            break;
          }
        }
        if (!found) {
          // Move to next week's first target day
          const daysUntilNextWeek = 7 - currentDayIndex + targetDays[0];
          nextDate.setDate(nextDate.getDate() + daysUntilNextWeek);
        }
      } else {
        nextDate.setDate(nextDate.getDate() + 7 * interval);
      }
      break;
    }
    case "MONTHLY": {
      const byMonthDay = ruleMap["BYMONTHDAY"];
      if (byMonthDay) {
        const targetDay = parseInt(byMonthDay, 10);
        nextDate.setMonth(nextDate.getMonth() + interval);
        nextDate.setDate(targetDay);
      } else {
        nextDate.setMonth(nextDate.getMonth() + interval);
      }
      break;
    }
    case "YEARLY":
      nextDate.setFullYear(nextDate.getFullYear() + interval);
      break;
    default:
      return null;
  }

  return nextDate;
}

// Calculate the next occurrence that is strictly after today
// This ensures overdue recurring tasks are scheduled for tomorrow, not today
function getNextOccurrence(anchorDate: Date, rule: string): Date | null {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  let nextDate: Date | null = anchorDate;
  do {
    nextDate = getNextOccurrenceSingle(nextDate!, rule);
  } while (nextDate !== null && nextDate <= today);

  return nextDate;
}

// ============================================
// MAIN HANDLER
// ============================================

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Get API key from header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return errorResponse("Missing or invalid Authorization header", 401);
    }
    const apiKey = authHeader.slice(7);

    // Create Supabase client with service role for key validation
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Validate API key and get user_id
    const userId = await validateApiKey(supabase, apiKey);
    if (!userId) {
      return errorResponse("Invalid API key", 401);
    }

    // Parse URL and route
    const url = new URL(req.url);
    const path = url.pathname.replace(/^\/mcp-api/, "");
    const segments = path.split("/").filter(Boolean);
    const method = req.method;

    // Parse body for POST/PATCH requests
    let body: Record<string, unknown> = {};
    if (method === "POST" || method === "PATCH") {
      try {
        body = await req.json();
      } catch {
        // No body or invalid JSON
      }
    }

    // Route handling
    // Projects
    if (segments[0] === "projects") {
      if (segments.length === 1) {
        if (method === "GET") return await listProjects(supabase, userId);
        if (method === "POST") return await createProject(supabase, userId, body as { name: string; color?: string; icon?: string; defaultAssignee?: string });
      }
      if (segments[1] === "inbox" && method === "GET") {
        return await getInboxProject(supabase, userId);
      }
      if (segments.length === 2) {
        const projectId = segments[1];
        if (method === "GET") return await getProject(supabase, userId, projectId);
        if (method === "PATCH") return await updateProject(supabase, userId, projectId, body as { name?: string; color?: string; icon?: string; defaultAssignee?: string });
        if (method === "DELETE") return await deleteProject(supabase, userId, projectId);
      }
    }

    // Tasks
    if (segments[0] === "tasks") {
      if (segments.length === 1) {
        if (method === "GET") {
          const projectId = url.searchParams.get("projectId") ?? undefined;
          return await listTasks(supabase, userId, projectId);
        }
        if (method === "POST") {
          return await createTask(supabase, userId, body as {
            projectId: string;
            title: string;
            description?: string;
            dueDate?: string;
            dueTime?: string;
            priority?: number;
            parentId?: string;
            recurrenceRule?: string;
            assignedTo?: string;
          });
        }
      }
      if (segments[1] === "today" && method === "GET") {
        return await getTodayTasks(supabase, userId);
      }
      if (segments[1] === "upcoming" && method === "GET") {
        return await getUpcomingTasks(supabase, userId);
      }
      if (segments[1] === "mine" && method === "GET") {
        return await getMyTasks(supabase, userId);
      }
      if (segments[1] === "by-assignee" && method === "GET") {
        const assignee = url.searchParams.get("assignee") || "hermes";
        return await getTasksByAssignee(supabase, userId, assignee);
      }
      if (segments.length === 2) {
        const taskId = segments[1];
        if (method === "GET") return await getTask(supabase, userId, taskId);
        if (method === "PATCH") return await updateTask(supabase, userId, taskId, body as {
          title?: string;
          description?: string;
          dueDate?: string;
          dueTime?: string;
          priority?: number;
          projectId?: string;
          recurrenceRule?: string;
          assignedTo?: string;
        });
        if (method === "DELETE") return await deleteTask(supabase, userId, taskId);
      }
      if (segments.length === 3) {
        const taskId = segments[1];
        if (segments[2] === "complete" && method === "POST") {
          return await completeTask(supabase, userId, taskId);
        }
        if (segments[2] === "uncomplete" && method === "POST") {
          return await uncompleteTask(supabase, userId, taskId);
        }
        if (segments[2] === "subtasks" && method === "GET") {
          return await getSubtasks(supabase, userId, taskId);
        }
      }
    }

    return errorResponse("Not found", 404);
  } catch (error) {
    console.error("Error:", error);
    return errorResponse("Internal server error", 500);
  }
});
