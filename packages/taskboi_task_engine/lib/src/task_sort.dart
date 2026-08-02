part of '../taskboi_task_engine.dart';

/// Supported deterministic task orderings.
enum TaskSortOption { manual, priority, dueDate, title, createdAt }

/// Returns a stably sorted copy of [tasks].
List<Task> sortTasks(List<Task> tasks, TaskSortOption option) {
  final indexed = <({int index, Task task})>[
    for (var index = 0; index < tasks.length; index++)
      (index: index, task: tasks[index]),
  ];
  indexed.sort((a, b) {
    final comparison = _compareTasks(a.task, b.task, option);
    return comparison == 0 ? a.index.compareTo(b.index) : comparison;
  });
  return [for (final entry in indexed) entry.task];
}

int _compareTasks(Task a, Task b, TaskSortOption option) {
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
