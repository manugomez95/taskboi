part of '../taskboi_task_engine.dart';

/// An immutable, framework-free representation of a Taskboi task.
class Task {
  const Task({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.title,
    this.parentId,
    this.description,
    this.dueDate,
    this.dueTime,
    this.priority = 0,
    this.isCompleted = false,
    this.completedAt,
    this.sortOrder = 0,
    this.recurrenceRule,
    this.recurrenceParentId,
    this.recurrenceAnchorDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String userId;
  final String? parentId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? dueTime;
  final int priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final int sortOrder;
  final String? recurrenceRule;
  final String? recurrenceParentId;
  final DateTime? recurrenceAnchorDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isRecurring => recurrenceRule != null;
  bool get isSubtask => parentId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          id == other.id &&
          projectId == other.projectId &&
          userId == other.userId &&
          parentId == other.parentId &&
          title == other.title &&
          description == other.description &&
          dueDate == other.dueDate &&
          dueTime == other.dueTime &&
          priority == other.priority &&
          isCompleted == other.isCompleted &&
          completedAt == other.completedAt &&
          sortOrder == other.sortOrder &&
          recurrenceRule == other.recurrenceRule &&
          recurrenceParentId == other.recurrenceParentId &&
          recurrenceAnchorDate == other.recurrenceAnchorDate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        userId,
        parentId,
        title,
        description,
        dueDate,
        dueTime,
        priority,
        isCompleted,
        completedAt,
        sortOrder,
        recurrenceRule,
        recurrenceParentId,
        recurrenceAnchorDate,
        createdAt,
        updatedAt,
      );
}
