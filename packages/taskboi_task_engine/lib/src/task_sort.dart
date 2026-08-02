part of '../taskboi_task_engine.dart';

/// Supported deterministic task orderings.
enum TaskSortOption { manual, priority, dueDate, title, createdAt }

/// The task fields used by [compareTaskSortKeys].
class TaskSortKey {
  const TaskSortKey({
    required this.title,
    required this.dueDate,
    required this.dueTime,
    required this.priority,
    required this.sortOrder,
    required this.createdAt,
  });

  final String title;
  final DateTime? dueDate;
  final String? dueTime;
  final int priority;
  final int sortOrder;
  final DateTime? createdAt;
}

/// Compares two task sort keys using [option]. Equal keys compare as zero.
int compareTaskSortKeys(TaskSortKey a, TaskSortKey b, TaskSortOption option) {
  switch (option) {
    case TaskSortOption.manual:
      return a.sortOrder.compareTo(b.sortOrder);
    case TaskSortOption.priority:
      return b.priority.compareTo(a.priority);
    case TaskSortOption.dueDate:
      final date = _compareNullable(a.dueDate, b.dueDate);
      return date != 0 ? date : _compareNullable(a.dueTime, b.dueTime);
    case TaskSortOption.title:
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    case TaskSortOption.createdAt:
      if (a.createdAt == null) return b.createdAt == null ? 0 : 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
  }
}

int _compareNullable<T extends Comparable<T>>(T? a, T? b) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
