// Taskboi MCP Worker - Remote MCP server with OAuth 2.0 Authorization Code + PKCE

import { TaskboiApiClient } from "./api-client";
import { handleOAuth, OAuthStore, resolveAccessToken, validateOAuthConfiguration, type OAuthEnv } from "./oauth";

export { OAuthStore };

interface McpRequest {
  jsonrpc: string;
  method: string;
  params?: Record<string, unknown>;
  id?: number | string;
}

interface McpResponse {
  jsonrpc: string;
  id?: number | string;
  result?: unknown;
  error?: { code: number; message: string };
}

interface Env extends OAuthEnv {}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    try {
      validateOAuthConfiguration(env);
    } catch (error) {
      console.error("OAuth configuration error", error instanceof Error ? error.message : "unknown");
      return Response.json({ error: "server_error" }, { status: 500, headers: { ...corsHeaders, "Cache-Control": "no-store" } });
    }

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    let oauthResponse: Response | null;
    try {
      oauthResponse = await handleOAuth(request, env);
    } catch (error) {
      console.error("OAuth configuration or storage error", error instanceof Error ? error.message : "unknown");
      return Response.json({ error: "server_error" }, { status: 500, headers: { ...corsHeaders, "Cache-Control": "no-store" } });
    }
    if (oauthResponse) return oauthResponse;

    // Health check
    if (url.pathname === "/" || url.pathname === "/health") {
      return Response.json(
        { status: "ok", name: "Taskboi MCP Server", version: "1.0.0" },
        { headers: corsHeaders }
      );
    }

    // MCP endpoint
    if (url.pathname === "/mcp" && request.method === "POST") {
      if (url.searchParams.has("key")) {
        return Response.json(
          { jsonrpc: "2.0", error: { code: -32600, message: "API keys are not accepted in query strings" } },
          { status: 400, headers: corsHeaders }
        );
      }
      const authHeader = request.headers.get("Authorization");
      const match = authHeader?.match(/^Bearer ([A-Za-z0-9_-]+)$/);
      const authorization = match ? await resolveAccessToken(env, match[1]) : null;
      if (!authorization) {
        const resourceMetadata = `${env.OAUTH_ISSUER}/.well-known/oauth-protected-resource/mcp`;
        return Response.json(
          { jsonrpc: "2.0", error: { code: -32000, message: "Unauthorized" } },
          { status: 401, headers: { ...corsHeaders, "WWW-Authenticate": `Bearer resource_metadata="${resourceMetadata}", scope="mcp"` } }
        );
      }

      try {
        const body = await request.json() as McpRequest;
        const client = new TaskboiApiClient(authorization.apiKey);
        const response = await handleMcpRequest(body, client);
        return Response.json(response, { headers: corsHeaders });
      } catch {
        return Response.json(
          { jsonrpc: "2.0", error: { code: -32700, message: "Parse error" } },
          { status: 400, headers: corsHeaders }
        );
      }
    }

    return Response.json({ error: "Not found" }, { status: 404, headers: corsHeaders });
  },
};

async function handleMcpRequest(req: McpRequest, client: TaskboiApiClient): Promise<McpResponse> {
  const { method, params, id } = req;

  try {
    switch (method) {
      case "initialize":
        return {
          jsonrpc: "2.0",
          id,
          result: {
            protocolVersion: "2024-11-05",
            capabilities: { tools: {} },
            serverInfo: { name: "Taskboi", version: "1.0.0" },
          },
        };

      case "notifications/initialized":
        return { jsonrpc: "2.0", id, result: {} };

      case "tools/list":
        return { jsonrpc: "2.0", id, result: { tools: getToolsList() } };

      case "tools/call":
        const toolResult = await callTool(params as { name: string; arguments: Record<string, unknown> }, client);
        return { jsonrpc: "2.0", id, result: toolResult };

      default:
        return { jsonrpc: "2.0", id, error: { code: -32601, message: `Method not found: ${method}` } };
    }
  } catch (error) {
    return {
      jsonrpc: "2.0",
      id,
      error: { code: -32000, message: error instanceof Error ? error.message : "Unknown error" },
    };
  }
}

function getToolsList() {
  return [
    { name: "list_projects", description: "List all projects in your Taskboi workspace", inputSchema: { type: "object", properties: {}, required: [] } },
    { name: "get_inbox", description: "Get the default Inbox project", inputSchema: { type: "object", properties: {}, required: [] } },
    { name: "get_project", description: "Get details of a specific project", inputSchema: { type: "object", properties: { id: { type: "string", description: "The project ID" } }, required: ["id"] } },
    { name: "create_project", description: "Create a new project", inputSchema: { type: "object", properties: { name: { type: "string", description: "The project name" }, color: { type: "string", description: "Hex color code (e.g., #6366F1)" }, icon: { type: "string", description: "Icon name (e.g., folder, star, work)" }, defaultAssignee: { type: "string", description: "Default assignee for new tasks: manuel or hermes" } }, required: ["name"] } },
    { name: "update_project", description: "Update an existing project", inputSchema: { type: "object", properties: { id: { type: "string", description: "The project ID" }, name: { type: "string" }, color: { type: "string" }, icon: { type: "string" }, defaultAssignee: { type: "string", description: "Default assignee for new tasks: manuel or hermes" } }, required: ["id"] } },
    { name: "delete_project", description: "Delete a project (cannot delete Inbox)", inputSchema: { type: "object", properties: { id: { type: "string", description: "The project ID" } }, required: ["id"] } },
    { name: "list_tasks", description: "List all tasks, optionally filtered by project", inputSchema: { type: "object", properties: { projectId: { type: "string", description: "Filter by project ID" } }, required: [] } },
    { name: "get_task", description: "Get details of a specific task", inputSchema: { type: "object", properties: { id: { type: "string", description: "The task ID" } }, required: ["id"] } },
    { name: "get_today_tasks", description: "Get all tasks due today", inputSchema: { type: "object", properties: {}, required: [] } },
    { name: "get_upcoming_tasks", description: "Get all upcoming tasks with due dates", inputSchema: { type: "object", properties: {}, required: [] } },
    { name: "get_subtasks", description: "Get all subtasks of a parent task", inputSchema: { type: "object", properties: { parentId: { type: "string", description: "The parent task ID" } }, required: ["parentId"] } },
    { name: "get_my_tasks", description: "Get all tasks assigned to the current agent (hermes)", inputSchema: { type: "object", properties: {}, required: [] } },
    { name: "get_tasks_by_assignee", description: "Get all tasks assigned to a specific person or agent", inputSchema: { type: "object", properties: { assignee: { type: "string", description: "The assignee name (manuel, hermes, or claude)" } }, required: ["assignee"] } },
    { name: "create_task", description: "Create a new task", inputSchema: { type: "object", properties: { projectId: { type: "string" }, title: { type: "string" }, description: { type: "string" }, dueDate: { type: "string" }, dueTime: { type: "string", description: "Due time in HH:MM format (24-hour). Omit for no specific time." }, priority: { type: "number" }, parentId: { type: "string" }, recurrenceRule: { type: "string" }, assignedTo: { type: "string", description: "Assignee: manuel, hermes, or claude" } }, required: ["projectId", "title"] } },
    { name: "update_task", description: "Update an existing task. Omitted fields are left unchanged; to remove the due date, pass clearDueDate: true.", inputSchema: { type: "object", properties: { id: { type: "string" }, title: { type: "string" }, description: { type: "string" }, dueDate: { type: "string", description: "New due date in YYYY-MM-DD format" }, clearDueDate: { type: "boolean", description: "Set to true to remove the task's due date" }, dueTime: { type: "string", description: "New due time in HH:MM format (24-hour). Pass null to remove the time." }, priority: { type: "number" }, projectId: { type: "string" }, recurrenceRule: { type: "string" }, assignedTo: { type: "string", description: "Assignee: manuel, hermes, or claude" } }, required: ["id"] } },
    { name: "complete_task", description: "Mark a task as complete", inputSchema: { type: "object", properties: { id: { type: "string", description: "The task ID" } }, required: ["id"] } },
    { name: "uncomplete_task", description: "Mark a completed task as incomplete", inputSchema: { type: "object", properties: { id: { type: "string", description: "The task ID" } }, required: ["id"] } },
    { name: "delete_task", description: "Delete a task", inputSchema: { type: "object", properties: { id: { type: "string", description: "The task ID" } }, required: ["id"] } },
  ];
}

// Drop null/undefined args: for PATCH-style tools an absent field means
// "leave unchanged", but a forwarded null would wipe the column.
function dropNullish(obj: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(Object.entries(obj).filter(([, v]) => v != null));
}

async function callTool(params: { name: string; arguments: Record<string, unknown> }, client: TaskboiApiClient) {
  const { name, arguments: args } = params;
  const json = (data: unknown) => ({ content: [{ type: "text", text: JSON.stringify(data, null, 2) }] });
  const err = (e: unknown) => ({ content: [{ type: "text", text: `Error: ${e instanceof Error ? e.message : "Unknown"}` }], isError: true });

  try {
    switch (name) {
      case "list_projects": return json({ projects: await client.listProjects() });
      case "get_inbox": return json({ project: await client.getInboxProject() });
      case "get_project": return json({ project: await client.getProject(args.id as string) });
      case "create_project": return json({ success: true, project: await client.createProject(args as any) });
      case "update_project": { const { id, ...u } = args; return json({ success: true, project: await client.updateProject(id as string, dropNullish(u)) }); }
      case "delete_project": await client.deleteProject(args.id as string); return json({ success: true, message: "Project deleted" });
      case "list_tasks": return json({ tasks: await client.listTasks(args.projectId as string | undefined) });
      case "get_task": return json({ task: await client.getTask(args.id as string) });
      case "get_today_tasks": { const t = await client.getTodayTasks(); return json({ tasks: t, count: t.length }); }
      case "get_upcoming_tasks": { const t = await client.getUpcomingTasks(); return json({ tasks: t, count: t.length }); }
      case "get_subtasks": { const t = await client.getSubtasks(args.parentId as string); return json({ tasks: t, count: t.length }); }
      case "get_my_tasks": { const t = await client.getMyTasks(); return json({ tasks: t, count: t.length }); }
      case "get_tasks_by_assignee": { const t = await client.getTasksByAssignee(args.assignee as string); return json({ tasks: t, count: t.length }); }
      case "create_task": return json({ success: true, task: await client.createTask(args as any) });
      case "update_task": {
        const { id, clearDueDate, ...rest } = args;
        const u = dropNullish(rest);
        // Clearing the due date must be explicit: the API treats a null
        // dueDate as "clear", and models sometimes send null meaning "no change".
        if (clearDueDate === true) u.dueDate = null;
        return json({ success: true, task: await client.updateTask(id as string, u) });
      }
      case "complete_task": { const r = await client.completeTask(args.id as string); return json({ success: true, completedTask: r.completedTask, nextTask: r.nextTask }); }
      case "uncomplete_task": return json({ success: true, task: await client.uncompleteTask(args.id as string) });
      case "delete_task": await client.deleteTask(args.id as string); return json({ success: true, message: "Task deleted" });
      default: return err(new Error(`Unknown tool: ${name}`));
    }
  } catch (e) { return err(e); }
}
