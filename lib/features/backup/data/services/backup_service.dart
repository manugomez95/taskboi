import 'package:drift/drift.dart';
import 'package:taskboi_backup_core/taskboi_backup_core.dart';

import '../../../../core/database/database.dart';

/// Service for exporting and importing backup data
class BackupService {
  final AppDatabase _db;
  final BackupArchiveCodec _codec;

  BackupService(this._db,
      {BackupArchiveCodec codec = const BackupArchiveCodec()})
      : _codec = codec;

  /// Exports all user data to a JSON string
  Future<String> exportToJson(String userId) async {
    // Get all projects
    final projects = await _db.getProjects(userId);

    // Get all tasks
    final allTasks = await _db.getTasks(userId);

    // Build nested structure
    final backupProjects = <BackupProject>[];

    for (final project in projects) {
      // Get tasks for this project (top-level only)
      final projectTasks = allTasks
          .where((t) => t.projectId == project.id && t.parentId == null)
          .toList();

      final backupTasks = <BackupTask>[];

      for (final task in projectTasks) {
        final backupTask = await _buildBackupTask(task, allTasks);
        backupTasks.add(backupTask);
      }

      backupProjects.add(BackupProject(
        id: project.id,
        name: project.name,
        color: project.color,
        icon: project.icon ?? 'folder',
        isInbox: project.isInbox,
        sortOrder: project.sortOrder,
        tasks: backupTasks,
      ));
    }

    final backupData = BackupArchive(
      version: BackupArchiveMetadata.currentFormatVersion,
      exportedAt: DateTime.now(),
      appVersion: '1.0.0',
      projects: backupProjects,
    );

    return _codec.encode(backupData);
  }

  /// Builds a backup task with its subtasks and comments
  Future<BackupTask> _buildBackupTask(Task task, List<Task> allTasks) async {
    // Get subtasks
    final subtasks = allTasks.where((t) => t.parentId == task.id).toList();
    final backupSubtasks = <BackupTask>[];

    for (final subtask in subtasks) {
      final backupSubtask = await _buildBackupTask(subtask, allTasks);
      backupSubtasks.add(backupSubtask);
    }

    // Get comments
    final comments = await _db.getComments(task.id);
    final backupComments = comments
        .map((c) => BackupComment(
              id: c.id,
              content: c.content,
              createdAt: c.createdAt ?? DateTime.now(),
            ))
        .toList();

    return BackupTask(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate?.toIso8601String().split('T').first,
      priority: task.priority,
      isCompleted: task.isCompleted,
      completedAt: task.completedAt,
      sortOrder: task.sortOrder,
      recurrenceRule: task.recurrenceRule,
      recurrenceAnchorDate:
          task.recurrenceAnchorDate?.toIso8601String().split('T').first,
      subtasks: backupSubtasks,
      comments: backupComments,
    );
  }

  /// Imports data from a JSON string
  /// Returns the number of projects imported
  Future<ImportResult> importFromJson(String jsonString, String userId) async {
    try {
      final backupData = _codec.decode(jsonString);

      int projectCount = 0;
      int taskCount = 0;

      // Clear existing data first
      await _clearUserData(userId);

      // Import projects and tasks
      for (final project in backupData.projects) {
        await _importProject(project, userId);
        projectCount++;
        taskCount += _countTasks(project.tasks);
      }

      return ImportResult(
        success: true,
        projectCount: projectCount,
        taskCount: taskCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Clears all user data from local database
  Future<void> _clearUserData(String userId) async {
    // Get all tasks to clear their comments
    final tasks = await _db.getTasks(userId);
    for (final task in tasks) {
      final comments = await _db.getComments(task.id);
      for (final comment in comments) {
        await _db.hardDeleteComment(comment.id);
      }
      await _db.hardDeleteTask(task.id);
    }

    // Clear projects
    final projects = await _db.getProjects(userId);
    for (final project in projects) {
      await _db.hardDeleteProject(project.id);
    }
  }

  /// Imports a single project with its tasks
  Future<void> _importProject(BackupProject project, String userId) async {
    final now = DateTime.now();

    await _db.upsertProject(ProjectsCompanion(
      id: Value(project.id),
      userId: Value(userId),
      name: Value(project.name),
      color: Value(project.color),
      icon: Value(project.icon),
      isInbox: Value(project.isInbox),
      sortOrder: Value(project.sortOrder),
      createdAt: Value(now),
      updatedAt: Value(now),
      isPendingSync: const Value(true),
    ));

    // Import tasks
    for (final task in project.tasks) {
      await _importTask(task, project.id, userId, null);
    }
  }

  /// Imports a single task with its subtasks and comments
  Future<void> _importTask(
    BackupTask task,
    String projectId,
    String userId,
    String? parentId,
  ) async {
    final now = DateTime.now();

    DateTime? dueDate;
    if (task.dueDate != null) {
      dueDate = DateTime.tryParse(task.dueDate!);
    }

    DateTime? recurrenceAnchorDate;
    if (task.recurrenceAnchorDate != null) {
      recurrenceAnchorDate = DateTime.tryParse(task.recurrenceAnchorDate!);
    }

    await _db.upsertTask(TasksCompanion(
      id: Value(task.id),
      projectId: Value(projectId),
      userId: Value(userId),
      parentId: Value(parentId),
      title: Value(task.title),
      description: Value(task.description),
      dueDate: Value(dueDate),
      priority: Value(task.priority),
      isCompleted: Value(task.isCompleted),
      completedAt: Value(task.completedAt),
      sortOrder: Value(task.sortOrder),
      recurrenceRule: Value(task.recurrenceRule),
      recurrenceAnchorDate: Value(recurrenceAnchorDate),
      createdAt: Value(now),
      updatedAt: Value(now),
      isPendingSync: const Value(true),
    ));

    // Import comments
    for (final comment in task.comments) {
      await _db.upsertComment(CommentsCompanion(
        id: Value(comment.id),
        taskId: Value(task.id),
        userId: Value(userId),
        content: Value(comment.content),
        createdAt: Value(comment.createdAt),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ));
    }

    // Import subtasks
    for (final subtask in task.subtasks) {
      await _importTask(subtask, projectId, userId, task.id);
    }
  }

  /// Counts total tasks including subtasks
  int _countTasks(List<BackupTask> tasks) {
    int count = 0;
    for (final task in tasks) {
      count++;
      count += _countTasks(task.subtasks);
    }
    return count;
  }
}

/// Result of an import operation
class ImportResult {
  final bool success;
  final int projectCount;
  final int taskCount;
  final String? error;

  ImportResult({
    required this.success,
    this.projectCount = 0,
    this.taskCount = 0,
    this.error,
  });
}
