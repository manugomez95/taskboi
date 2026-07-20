// Project Tools for Taskboi MCP Server

import { z } from "zod";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { TaskboiApiClient } from "../api-client.js";

export function registerProjectTools(server: McpServer, client: TaskboiApiClient): void {
  // List all projects
  server.tool(
    "list_projects",
    "List all projects in your Taskboi workspace",
    {},
    async () => {
      try {
        const projects = await client.listProjects();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ projects }, null, 2),
            },
          ],
        };
      } catch (error) {
        return {
          content: [
            {
              type: "text",
              text: `Error: ${error instanceof Error ? error.message : "Unknown error"}`,
            },
          ],
          isError: true,
        };
      }
    }
  );

  // Get inbox project
  server.tool(
    "get_inbox",
    "Get the default Inbox project",
    {},
    async () => {
      try {
        const project = await client.getInboxProject();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ project }, null, 2),
            },
          ],
        };
      } catch (error) {
        return {
          content: [
            {
              type: "text",
              text: `Error: ${error instanceof Error ? error.message : "Unknown error"}`,
            },
          ],
          isError: true,
        };
      }
    }
  );

  // Get a specific project
  server.tool(
    "get_project",
    "Get details of a specific project",
    {
      id: z.string().uuid().describe("The project ID"),
    },
    async ({ id }) => {
      try {
        const project = await client.getProject(id);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ project }, null, 2),
            },
          ],
        };
      } catch (error) {
        return {
          content: [
            {
              type: "text",
              text: `Error: ${error instanceof Error ? error.message : "Unknown error"}`,
            },
          ],
          isError: true,
        };
      }
    }
  );

  // Create a project
  server.tool(
    "create_project",
    "Create a new project",
    {
      name: z.string().min(1).describe("The project name"),
      color: z
        .string()
        .regex(/^#[0-9A-Fa-f]{6}$/)
        .optional()
        .describe("Hex color code (e.g., #6366F1)"),
      icon: z.string().optional().describe("Icon name (e.g., folder, star, work)"),
      defaultAssignee: z
        .string()
        .optional()
        .describe("Default assignee for new tasks in this project: manuel or hermes"),
    },
    async ({ name, color, icon, defaultAssignee }) => {
      try {
        const project = await client.createProject({ name, color, icon, defaultAssignee });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ success: true, project }, null, 2),
            },
          ],
        };
      } catch (error) {
        return {
          content: [
            {
              type: "text",
              text: `Error: ${error instanceof Error ? error.message : "Unknown error"}`,
            },
          ],
          isError: true,
        };
      }
    }
  );

  // Update a project
  server.tool(
    "update_project",
    "Update an existing project",
    {
      id: z.string().uuid().describe("The project ID"),
      name: z.string().min(1).optional().describe("New project name"),
      color: z
        .string()
        .regex(/^#[0-9A-Fa-f]{6}$/)
        .optional()
        .describe("New hex color code"),
      icon: z.string().optional().describe("New icon name"),
      defaultAssignee: z
        .string()
        .optional()
        .describe("Default assignee for new tasks in this project: manuel or hermes"),
    },
    async ({ id, name, color, icon, defaultAssignee }) => {
      try {
        const project = await client.updateProject(id, { name, color, icon, defaultAssignee });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ success: true, project }, null, 2),
            },
          ],
        };
      } catch (error) {
        return {
          content: [
            {
              type: "text",
              text: `Error: ${error instanceof Error ? error.message : "Unknown error"}`,
            },
          ],
          isError: true,
        };
      }
    }
  );

  // Delete a project
  server.tool(
    "delete_project",
    "Delete a project (cannot delete Inbox)",
    {
      id: z.string().uuid().describe("The project ID to delete"),
    },
    async ({ id }) => {
      try {
        await client.deleteProject(id);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ success: true, message: "Project deleted" }, null, 2),
            },
          ],
        };
      } catch (error) {
        return {
          content: [
            {
              type: "text",
              text: `Error: ${error instanceof Error ? error.message : "Unknown error"}`,
            },
          ],
          isError: true,
        };
      }
    }
  );
}
