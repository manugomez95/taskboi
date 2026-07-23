# Taskboi MCP Server

MCP (Model Context Protocol) server for Taskboi - enabling AI assistants to manage your tasks.

## Installation

```bash
npx taskboi-mcp
```

Or install globally:

```bash
npm install -g taskboi-mcp
```

## Setup

### 1. Get your API Key

1. Open the Taskboi app
2. Go to **Settings > API Keys**
3. Click **Generate New Key**
4. Copy the key (it's only shown once!)

### 2. Configure your MCP Client

#### Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "taskboi": {
      "command": "npx",
      "args": ["taskboi-mcp"],
      "env": {
        "TASKBOI_API_KEY": "tk_your_api_key_here",
        "TASKBOI_API_BASE_URL": "https://api.example.invalid/functions/v1/mcp-api"
      }
    }
  }
}
```

#### Cursor

Add to `.cursor/mcp.json`:

```json
{
  "servers": {
    "taskboi": {
      "command": "npx",
      "args": ["taskboi-mcp"],
      "env": {
        "TASKBOI_API_KEY": "tk_your_api_key_here",
        "TASKBOI_API_BASE_URL": "https://api.example.invalid/functions/v1/mcp-api"
      }
    }
  }
}
```

`TASKBOI_API_BASE_URL` is required and has no default. Replace the inert
`example.invalid` URL with the endpoint supplied by your Taskboi operator. It
must be an absolute HTTPS URL whose path is exactly `/functions/v1/mcp-api`,
with no trailing slash, surrounding whitespace, credentials, query, or
fragment. Invalid or missing values stop the server before the API client is
created.

## Available Tools

### Projects

| Tool | Description |
|------|-------------|
| `list_projects` | List all projects |
| `get_inbox` | Get the default Inbox project |
| `get_project` | Get details of a specific project |
| `create_project` | Create a new project |
| `update_project` | Update a project's name, color, or icon |
| `delete_project` | Delete a project (cannot delete Inbox) |

### Tasks

| Tool | Description |
|------|-------------|
| `list_tasks` | List all tasks (optionally filter by project) |
| `get_task` | Get details of a specific task |
| `get_today_tasks` | Get all tasks due today |
| `get_upcoming_tasks` | Get upcoming tasks with due dates |
| `get_subtasks` | Get subtasks of a parent task |
| `create_task` | Create a new task |
| `update_task` | Update a task |
| `complete_task` | Mark a task complete (creates next occurrence for recurring tasks) |
| `uncomplete_task` | Mark a task incomplete |
| `delete_task` | Delete a task |

## Examples

### Create a task

```
Create a task in my Work project called "Review PR" with high priority, due tomorrow
```

### Check today's tasks

```
What tasks do I have due today?
```

### Complete a task

```
Mark the "Review PR" task as complete
```

### Create a recurring task

```
Create a daily task called "Morning standup" in my Work project
```

## Recurrence Rules

The `recurrenceRule` parameter supports RRULE format:

- `FREQ=DAILY` - Every day
- `FREQ=WEEKLY` - Every week
- `FREQ=MONTHLY` - Every month
- `FREQ=YEARLY` - Every year
- `FREQ=WEEKLY;BYDAY=MO,WE,FR` - Every Monday, Wednesday, Friday
- `FREQ=MONTHLY;BYMONTHDAY=15` - Every 15th of the month
- `FREQ=DAILY;INTERVAL=2` - Every 2 days

## Priority Levels

- `0` - No priority
- `1` - Urgent (highest)
- `2` - High
- `3` - Normal
- `4` - Low

## License status

Licensed under the repository's [Apache License 2.0](../LICENSE). Publication
remains subject to the separate dependency, SBOM, and attribution
[release requirement](../docs/RELEASE_BLOCKERS.md).
