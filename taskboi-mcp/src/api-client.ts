// Taskboi API Client - Calls the Supabase Edge Function

import type {
  Project,
  Task,
  ProjectsResponse,
  ProjectResponse,
  TasksResponse,
  TaskResponse,
  CompleteTaskResponse,
  SuccessResponse,
} from "./types.js";

const API_BASE_URL = "https://qagfzbwvlrmmdyrpuyvi.supabase.co/functions/v1/mcp-api";

export class TaskboiApiClient {
  private apiKey: string;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  private async request<T>(
    method: string,
    path: string,
    body?: Record<string, unknown>
  ): Promise<T> {
    const response = await fetch(`${API_BASE_URL}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    const data = (await response.json()) as T & { error?: string };

    if (!response.ok) {
      throw new Error(data.error || `API error: ${response.status}`);
    }

    return data;
  }

  // ============================================
  // PROJECTS
  // ============================================

  async listProjects(): Promise<Project[]> {
    const response = await this.request<ProjectsResponse>("GET", "/projects");
    return response.projects;
  }

  async getProject(id: string): Promise<Project> {
    const response = await this.request<ProjectResponse>("GET", `/projects/${id}`);
    return response.project;
  }

  async getInboxProject(): Promise<Project> {
    const response = await this.request<ProjectResponse>("GET", "/projects/inbox");
    return response.project;
  }

  async createProject(params: {
    name: string;
    color?: string;
    icon?: string;
    defaultAssignee?: string;
  }): Promise<Project> {
    const response = await this.request<ProjectResponse>("POST", "/projects", params);
    return response.project;
  }

  async updateProject(
    id: string,
    params: {
      name?: string;
      color?: string;
      icon?: string;
      defaultAssignee?: string;
    }
  ): Promise<Project> {
    const response = await this.request<ProjectResponse>("PATCH", `/projects/${id}`, params);
    return response.project;
  }

  async deleteProject(id: string): Promise<void> {
    await this.request<SuccessResponse>("DELETE", `/projects/${id}`);
  }

  // ============================================
  // TASKS
  // ============================================

  async listTasks(projectId?: string): Promise<Task[]> {
    const query = projectId ? `?projectId=${projectId}` : "";
    const response = await this.request<TasksResponse>("GET", `/tasks${query}`);
    return response.tasks;
  }

  async getTask(id: string): Promise<Task> {
    const response = await this.request<TaskResponse>("GET", `/tasks/${id}`);
    return response.task;
  }

  async getTodayTasks(): Promise<Task[]> {
    const response = await this.request<TasksResponse>("GET", "/tasks/today");
    return response.tasks;
  }

  async getUpcomingTasks(): Promise<Task[]> {
    const response = await this.request<TasksResponse>("GET", "/tasks/upcoming");
    return response.tasks;
  }

  async getSubtasks(parentId: string): Promise<Task[]> {
    const response = await this.request<TasksResponse>("GET", `/tasks/${parentId}/subtasks`);
    return response.tasks;
  }

  async createTask(params: {
    projectId: string;
    title: string;
    description?: string;
    dueDate?: string;
    dueTime?: string;
    priority?: number;
    parentId?: string;
    recurrenceRule?: string;
    assignedTo?: string;
  }): Promise<Task> {
    const response = await this.request<TaskResponse>("POST", "/tasks", params);
    return response.task;
  }

  async updateTask(
    id: string,
    params: {
      title?: string;
      description?: string;
      dueDate?: string | null;
      dueTime?: string | null;
      priority?: number;
      projectId?: string;
      recurrenceRule?: string;
      assignedTo?: string;
    }
  ): Promise<Task> {
    const response = await this.request<TaskResponse>("PATCH", `/tasks/${id}`, params);
    return response.task;
  }

  async completeTask(id: string): Promise<CompleteTaskResponse> {
    return await this.request<CompleteTaskResponse>("POST", `/tasks/${id}/complete`);
  }

  async uncompleteTask(id: string): Promise<Task> {
    const response = await this.request<TaskResponse>("POST", `/tasks/${id}/uncomplete`);
    return response.task;
  }

  async deleteTask(id: string): Promise<void> {
    await this.request<SuccessResponse>("DELETE", `/tasks/${id}`);
  }
}
