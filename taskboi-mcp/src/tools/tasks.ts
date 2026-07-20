// Task Tools for Taskboi MCP Server

import { z } from "zod";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { TaskboiApiClient } from "../api-client.js";

export function registerTaskTools(server: McpServer, client: TaskboiApiClient): void {
  // List tasks
  server.tool(
    "list_tasks",
    "List all tasks, optionally filtered by project",
    {
      projectId: z.string().uuid().optional().describe("Filter by project ID"),
    },
    async ({ projectId }) => {
      try {
        const tasks = await client.listTasks(projectId);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ tasks }, null, 2),
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

  // Get a specific task
  server.tool(
    "get_task",
    "Get details of a specific task",
    {
      id: z.string().uuid().describe("The task ID"),
    },
    async ({ id }) => {
      try {
        const task = await client.getTask(id);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ task }, null, 2),
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

  // Get today's tasks
  server.tool(
    "get_today_tasks",
    "Get all tasks due today (including overdue recurring tasks)",
    {},
    async () => {
      try {
        const tasks = await client.getTodayTasks();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ tasks, count: tasks.length }, null, 2),
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

  // Get upcoming tasks
  server.tool(
    "get_upcoming_tasks",
    "Get all upcoming tasks with due dates",
    {},
    async () => {
      try {
        const tasks = await client.getUpcomingTasks();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ tasks, count: tasks.length }, null, 2),
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

  // Get subtasks
  server.tool(
    "get_subtasks",
    "Get all subtasks of a parent task",
    {
      parentId: z.string().uuid().describe("The parent task ID"),
    },
    async ({ parentId }) => {
      try {
        const tasks = await client.getSubtasks(parentId);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ tasks, count: tasks.length }, null, 2),
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

  // Create a task
  server.tool(
    "create_task",
    "Create a new task",
    {
      projectId: z.string().uuid().describe("The project ID to add the task to"),
      title: z.string().min(1).describe("The task title"),
      description: z.string().optional().describe("Task description"),
      dueDate: z
        .string()
        .regex(/^\d{4}-\d{2}-\d{2}$/)
        .optional()
        .describe("Due date in YYYY-MM-DD format"),
      dueTime: z
        .string()
        .regex(/^\d{2}:\d{2}$/)
        .optional()
        .describe("Due time in HH:MM format (24-hour). Omit for no specific time."),
      priority: z
        .coerce
        .number()
        .int()
        .min(0)
        .max(4)
        .optional()
        .describe("Priority: 0=none, 1=urgent, 2=high, 3=normal, 4=low"),
      parentId: z.string().uuid().optional().describe("Parent task ID for subtasks"),
      recurrenceRule: z
        .string()
        .optional()
        .describe(
          "Recurrence rule (RRULE format): FREQ=DAILY, FREQ=WEEKLY, FREQ=MONTHLY, FREQ=YEARLY, or with options like FREQ=WEEKLY;BYDAY=MO,WE,FR"
        ),
      assignedTo: z
        .string()
        .optional()
        .describe("Assignee: manuel, hermes, or claude"),
    },
    async ({ projectId, title, description, dueDate, dueTime, priority, parentId, recurrenceRule, assignedTo }) => {
      try {
        const task = await client.createTask({
          projectId,
          title,
          description,
          dueDate,
          dueTime,
          priority: priority ?? 0,
          parentId,
          recurrenceRule,
          assignedTo,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ success: true, task }, null, 2),
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

  // Update a task
  server.tool(
    "update_task",
    "Update an existing task. Omitted fields are left unchanged; to remove the due date, pass clearDueDate: true.",
    {
      id: z.string().uuid().describe("The task ID"),
      title: z.string().min(1).optional().describe("New task title"),
      description: z.string().optional().describe("New description"),
      dueDate: z
        .string()
        .regex(/^\d{4}-\d{2}-\d{2}$/)
        .optional()
        .describe("New due date in YYYY-MM-DD format"),
      clearDueDate: z
        .boolean()
        .optional()
        .describe("Set to true to remove the task's due date"),
      dueTime: z
        .string()
        .regex(/^\d{2}:\d{2}$/)
        .nullable()
        .optional()
        .describe("New due time in HH:MM format (24-hour). Pass null to remove the time."),
      priority: z
        .coerce
        .number()
        .int()
        .min(0)
        .max(4)
        .optional()
        .describe("New priority: 0=none, 1=urgent, 2=high, 3=normal, 4=low"),
      projectId: z.string().uuid().optional().describe("Move to a different project"),
      recurrenceRule: z.string().optional().describe("New recurrence rule"),
      assignedTo: z
        .string()
        .optional()
        .describe("Assignee: manuel, hermes, or claude. When moving a task to a different project without specifying this, the task inherits the destination project's default_assignee."),
    },
    async ({ id, title, description, dueDate, clearDueDate, dueTime, priority, projectId, recurrenceRule, assignedTo }) => {
      try {
        const task = await client.updateTask(id, {
          title,
          description,
          // The API clears the date on an explicit null; require the flag so
          // an accidental null from a model can't wipe it.
          dueDate: clearDueDate === true ? null : dueDate,
          dueTime,
          priority,
          projectId,
          recurrenceRule,
          assignedTo,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ success: true, task }, null, 2),
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

  // Complete a task
  server.tool(
    "complete_task",
    "Mark a task as complete. For recurring tasks, this also creates the next occurrence.",
    {
      id: z.string().uuid().describe("The task ID to complete"),
    },
    async ({ id }) => {
      try {
        const result = await client.completeTask(id);
        const response: Record<string, unknown> = {
          success: true,
          completedTask: result.completedTask,
        };
        if (result.nextTask) {
          response.nextTask = result.nextTask;
          response.message = "Task completed and next occurrence created";
        } else {
          response.message = "Task completed";
        }
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(response, null, 2),
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

  // Uncomplete a task
  server.tool(
    "uncomplete_task",
    "Mark a completed task as incomplete",
    {
      id: z.string().uuid().describe("The task ID to uncomplete"),
    },
    async ({ id }) => {
      try {
        const task = await client.uncompleteTask(id);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ success: true, task }, null, 2),
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

  // Delete a task
  server.tool(
    "delete_task",
    "Delete a task",
    {
      id: z.string().uuid().describe("The task ID to delete"),
    },
    async ({ id }) => {
      try {
        await client.deleteTask(id);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ success: true, message: "Task deleted" }, null, 2),
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
