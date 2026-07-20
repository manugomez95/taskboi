import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/comments/data/models/comment.dart' as models;
import '../../features/projects/data/models/project.dart' as models;
import '../../features/tasks/data/models/task.dart' as models;
import 'database.dart';

/// Converts between Drift entities and Freezed models
class ModelConverters {
  // ==================== Projects ====================

  /// Convert Drift Project entity to Freezed Project model
  static models.Project projectFromDrift(Project entity) {
    return models.Project(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      color: entity.color,
      icon: entity.icon,
      isInbox: entity.isInbox,
      sortOrder: entity.sortOrder,
      defaultAssignee: entity.defaultAssignee,
      agentWebhookUrl: entity.agentWebhookUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert Freezed Project model to Drift ProjectsCompanion for insert/update
  static ProjectsCompanion projectToDrift(models.Project model,
      {bool isPendingSync = false, bool isDeleted = false}) {
    return ProjectsCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      name: Value(model.name),
      color: Value(model.color),
      icon: Value(model.icon),
      isInbox: Value(model.isInbox),
      sortOrder: Value(model.sortOrder),
      defaultAssignee: Value(model.defaultAssignee),
      agentWebhookUrl: Value(model.agentWebhookUrl),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
      isPendingSync: Value(isPendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  /// Convert list of Drift Projects to Freezed models
  static List<models.Project> projectsFromDrift(List<Project> entities) {
    return entities.map(projectFromDrift).toList();
  }

  // ==================== Tasks ====================

  /// Convert Drift Task entity to Freezed Task model
  static models.Task taskFromDrift(Task entity) {
    return models.Task(
      id: entity.id,
      projectId: entity.projectId,
      userId: entity.userId,
      parentId: entity.parentId,
      title: entity.title,
      description: entity.description,
      dueDate: entity.dueDate,
      dueTime: entity.dueTime,
      priority: entity.priority,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      sortOrder: entity.sortOrder,
      recurrenceRule: entity.recurrenceRule,
      recurrenceParentId: entity.recurrenceParentId,
      recurrenceAnchorDate: entity.recurrenceAnchorDate,
      assignedTo: entity.assignedTo,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert Freezed Task model to Drift TasksCompanion for insert/update
  static TasksCompanion taskToDrift(models.Task model,
      {bool isPendingSync = false, bool isDeleted = false}) {
    return TasksCompanion(
      id: Value(model.id),
      projectId: Value(model.projectId),
      userId: Value(model.userId),
      parentId: Value(model.parentId),
      title: Value(model.title),
      description: Value(model.description),
      dueDate: Value(model.dueDate),
      dueTime: Value(model.dueTime),
      priority: Value(model.priority),
      isCompleted: Value(model.isCompleted),
      completedAt: Value(model.completedAt),
      sortOrder: Value(model.sortOrder),
      recurrenceRule: Value(model.recurrenceRule),
      recurrenceParentId: Value(model.recurrenceParentId),
      recurrenceAnchorDate: Value(model.recurrenceAnchorDate),
      assignedTo: Value(model.assignedTo),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
      isPendingSync: Value(isPendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  /// Convert list of Drift Tasks to Freezed models
  static List<models.Task> tasksFromDrift(List<Task> entities) {
    return entities.map(taskFromDrift).toList();
  }

  // ==================== Comments ====================

  /// Convert Drift Comment entity to Freezed Comment model
  static models.Comment commentFromDrift(Comment entity) {
    return models.Comment(
      id: entity.id,
      taskId: entity.taskId,
      userId: entity.userId,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      images: _parseImages(entity.images),
    );
  }

  /// Convert Freezed Comment model to Drift CommentsCompanion for insert/update
  static CommentsCompanion commentToDrift(models.Comment model,
      {bool isPendingSync = false, bool isDeleted = false}) {
    return CommentsCompanion(
      id: Value(model.id),
      taskId: Value(model.taskId),
      userId: Value(model.userId),
      content: Value(model.content),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
      images: Value(jsonEncode(model.images)),
      isPendingSync: Value(isPendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  /// Parse images from the Drift TEXT column.
  /// Stored as a JSON-encoded string like '["url1","url2"]' or '[]'.
  static List<String> _parseImages(String? raw) {
    if (raw == null || raw.isEmpty || raw == '[]') return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {
      // Malformed JSON — treat as empty
    }
    return [];
  }

  /// Convert list of Drift Comments to Freezed models
  static List<models.Comment> commentsFromDrift(List<Comment> entities) {
    return entities.map(commentFromDrift).toList();
  }
}
