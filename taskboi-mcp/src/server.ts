// Taskboi MCP Server

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { TaskboiApiClient } from "./api-client.js";
import { registerProjectTools } from "./tools/projects.js";
import { registerTaskTools } from "./tools/tasks.js";

export async function createServer(): Promise<void> {
  // Get API key from environment
  const apiKey = process.env.TASKBOI_API_KEY;

  if (!apiKey) {
    console.error("Error: TASKBOI_API_KEY environment variable is required");
    console.error("");
    console.error("To get your API key:");
    console.error("1. Open Taskboi app");
    console.error("2. Go to Settings > API Keys");
    console.error("3. Generate a new API key");
    console.error("");
    console.error("Then set it in your MCP client configuration:");
    console.error('  "env": { "TASKBOI_API_KEY": "tk_your_key_here" }');
    process.exit(1);
  }

  // Create API client
  const client = new TaskboiApiClient(apiKey);

  // Create MCP server
  const server = new McpServer({
    name: "Taskboi",
    version: "1.0.0",
  });

  // Register tools
  registerProjectTools(server, client);
  registerTaskTools(server, client);

  // Connect via stdio
  const transport = new StdioServerTransport();
  await server.connect(transport);

  // Handle shutdown
  process.on("SIGINT", async () => {
    await server.close();
    process.exit(0);
  });

  process.on("SIGTERM", async () => {
    await server.close();
    process.exit(0);
  });
}
