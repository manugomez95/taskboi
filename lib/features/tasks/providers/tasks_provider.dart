import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart' hide Task;
import '../../../core/database/model_converters.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/supabase_serialization.dart';
import '../../auth/providers/auth_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../settings/providers/theme_provider.dart';
import '../data/models/task.dart';
import '../data/models/task_sort_option.dart';

// Re-export the sort option for backward compatibility
export '../data/models/task_sort_option.dart';

/// Keys for different task views
class TaskViewKey {
  static const String today = 'today';
  static const String upcoming = 'upcoming';
  static const String inbox = 'inbox';
  static String project(String projectId) => 'project_$projectId';
}

/// Fetches the user's saved sort preferences before the first task render.
final _sortPreferencesInitialProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  final repository = ref.watch(userPreferencesRepositoryProvider);
  return repository.getSortPreferences();
});

/// Stream provider that watches all sort preferences from Supabase
final _sortPreferencesStreamProvider =
    StreamProvider<Map<String, String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value({});

  final repository = ref.watch(userPreferencesRepositoryProvider);
  return repository.watchSortPreferences();
});

/// Optimistic sort preferences state - used for instant UI updates per view
final _optimisticSortPreferencesProvider =
    StateProvider<Map<String, String>>((ref) => {});

/// Provider to store the current sort option per view with Supabase sync
class TaskSortNotifier extends StateNotifier<TaskSortOption> {
  final Ref _ref;
  final String _viewKey;

  TaskSortNotifier(this._ref, this._viewKey, TaskSortOption initialState)
      : super(initialState);

  Future<void> setSortOption(TaskSortOption option) async {
    // Optimistically update state immediately
    state = option;

    // Update optimistic preferences
    final current =
        Map<String, String>.from(_ref.read(_optimisticSortPreferencesProvider));
    current[_viewKey] = option.name;
    _ref.read(_optimisticSortPreferencesProvider.notifier).state = current;

    // Persist to Supabase
    try {
      final repository = _ref.read(userPreferencesRepositoryProvider);
      await repository.setSortPreferenceForView(_viewKey, option.name);

      // Clear optimistic state after delay to let stream catch up
      Future.delayed(const Duration(milliseconds: 500), () {
        final optimistic = Map<String, String>.from(
            _ref.read(_optimisticSortPreferencesProvider));
        optimistic.remove(_viewKey);
        _ref.read(_optimisticSortPreferencesProvider.notifier).state =
            optimistic;
      });
    } catch (e) {
      // Keep optimistic state on error for UX
    }
  }
}

/// Family provider for per-view task sorting with Supabase persistence
final taskSortNotifierProvider =
    StateNotifierProvider.family<TaskSortNotifier, TaskSortOption, String>(
  (ref, viewKey) {
    // Watch initial fetch, stream, and optimistic state to trigger rebuilds.
    // Use the fetched preferences until the stream emits, avoiding a startup
    // flash where tasks are temporarily sorted with default values.
    final initialPrefs =
        ref.watch(_sortPreferencesInitialProvider).valueOrNull ?? {};
    final streamPrefs =
        ref.watch(_sortPreferencesStreamProvider).valueOrNull ?? initialPrefs;
    final optimisticPrefs = ref.watch(_optimisticSortPreferencesProvider);

    // Determine the current sort option
    final sortName =
        optimisticPrefs[viewKey] ?? streamPrefs[viewKey] ?? 'manual';
    final sortOption = TaskSortOption.values.firstWhere(
      (o) => o.name == sortName,
      orElse: () => TaskSortOption.manual,
    );

    return TaskSortNotifier(ref, viewKey, sortOption);
  },
);

// ============================================
// SHOW COMPLETED TASKS PROVIDERS
// ============================================

/// Fetches the user's saved show-completed preferences before first render.
final _showCompletedPreferencesInitialProvider =
    FutureProvider<Map<String, bool>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  final repository = ref.watch(userPreferencesRepositoryProvider);
  return repository.getShowCompletedPreferences();
});

/// Stream provider that watches all show completed preferences from Supabase
final _showCompletedPreferencesStreamProvider =
    StreamProvider<Map<String, bool>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value({});

  final repository = ref.watch(userPreferencesRepositoryProvider);
  return repository.watchShowCompletedPreferences();
});

/// Optimistic show completed preferences state - used for instant UI updates per view
/// Follows the same pattern as [_optimisticThemeProvider] / [_optimisticLanguageProvider]
final _optimisticShowCompletedPreferencesProvider =
    StateProvider<Map<String, bool>>((ref) => {});

/// Resolved show-completed value for a given view key.
///
/// Uses the same pattern as [themeIdProvider] and [languageIdProvider]:
/// optimistic state > stream value > initial fetch value > default (true).
///
/// NOTE: This is intentionally a plain [Provider], NOT a [StateNotifierProvider].
/// Using [StateNotifierProvider] with [ref.watch] inside the factory causes the
/// entire notifier to be *recreated* whenever the watched dependencies change,
/// creating a race condition:
///   1. User toggles "Show completed" OFF → state = false ✓
///   2. Optimistic map: {viewKey: false}
///   3. Supabase UPDATE sent
///   4. 500ms later: optimistic cleared → {}
///   5. Factory re-runs (optimistic changed)
///   6. Stream may not have emitted yet (network latency!)
///   7. Falls through to initialAsync with OLD data → defaults to true
///   8. New notifier created with state = true → **BUG: completed tasks reappear**
///
/// A plain [Provider] avoids this because it simply re-evaluates on each
/// dependency change without carrying mutable state that can be overwritten.
final showCompletedProvider = Provider.family<bool, String>((ref, viewKey) {
  // 1. Optimistic state takes priority (instant UI feedback)
  final optimistic = ref.watch(_optimisticShowCompletedPreferencesProvider);
  if (optimistic.containsKey(viewKey)) {
    return optimistic[viewKey]!;
  }

  // 2. Stream value (real-time from Supabase)
  final stream = ref.watch(_showCompletedPreferencesStreamProvider);
  if (stream.hasValue) {
    return stream.valueOrNull![viewKey] ?? true;
  }

  // 3. Initial fetch (used until stream emits to avoid startup flash)
  final initial = ref.watch(_showCompletedPreferencesInitialProvider);
  if (initial.hasValue) {
    return initial.valueOrNull![viewKey] ?? true;
  }

  // 4. Default: show completed
  return true;
});

/// Toggle show completed for a view with optimistic update.
/// Call from UI: `onPressed: () => toggleShowCompleted(ref, _viewKey)`
Future<void> toggleShowCompleted(WidgetRef ref, String viewKey) async {
  final current = ref.read(showCompletedProvider(viewKey));
  await setShowCompleted(ref, viewKey, !current);
}

/// Set show completed for a view with optimistic update to Supabase.
Future<void> setShowCompleted(
    WidgetRef ref, String viewKey, bool showCompleted) async {
  // Optimistically update immediately
  final current = Map<String, bool>.from(
      ref.read(_optimisticShowCompletedPreferencesProvider));
  current[viewKey] = showCompleted;
  ref.read(_optimisticShowCompletedPreferencesProvider.notifier).state =
      current;

  // Persist to Supabase
  try {
    final repository = ref.read(userPreferencesRepositoryProvider);
    await repository.setShowCompletedForView(viewKey, showCompleted);

    // Clear optimistic state after delay to let stream catch up
    Future.delayed(const Duration(milliseconds: 500), () {
      final optimistic = Map<String, bool>.from(
          ref.read(_optimisticShowCompletedPreferencesProvider));
      optimistic.remove(viewKey);
      ref.read(_optimisticShowCompletedPreferencesProvider.notifier).state =
          optimistic;
    });
  } catch (e) {
    // Keep optimistic state on error for UX
  }
}

/// Startup gate for task view preferences that can reshuffle visible tasks.
final startupTaskPreferencesProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  await Future.wait([
    ref.watch(_sortPreferencesInitialProvider.future),
    ref.watch(_showCompletedPreferencesInitialProvider.future),
  ]);
});

/// Applies sorting to a list of tasks based on the selected sort option
List<Task> applySorting(List<Task> tasks, TaskSortOption sortOption) {
  final sorted = List<Task>.from(tasks);

  switch (sortOption) {
    case TaskSortOption.manual:
      sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      break;
    case TaskSortOption.priority:
      // Higher priority (4=urgent) comes first
      sorted.sort((a, b) => b.priority.compareTo(a.priority));
      break;
    case TaskSortOption.dueDate:
      // Tasks with due dates come first, sorted by date then time
      sorted.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        final dateCompare = a.dueDate!.compareTo(b.dueDate!);
        if (dateCompare != 0) return dateCompare;
        // Same date: compare by time (tasks with no time sort after tasks with time)
        if (a.dueTime == null && b.dueTime == null) return 0;
        if (a.dueTime == null) return 1;
        if (b.dueTime == null) return -1;
        return a.dueTime!.compareTo(b.dueTime!);
      });
      break;
    case TaskSortOption.title:
      sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case TaskSortOption.createdAt:
      // Newest first
      sorted.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      break;
  }

  return sorted;
}

// Stream from local Drift database - tasks for a specific project
final _localTasksStreamProvider =
    StreamProvider.family<List<Task>, String?>((ref, projectId) {
  final db = ref.watch(appDatabaseProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  if (projectId != null) {
    return db.watchTasks(projectId).map((driftTasks) {
      return ModelConverters.tasksFromDrift(driftTasks);
    });
  } else {
    return db.watchAllTasks(user.id).map((driftTasks) {
      return ModelConverters.tasksFromDrift(driftTasks);
    });
  }
});

// Holds IDs of tasks pending deletion (for optimistic UI with undo)
final _pendingDeletionProvider = StateProvider<Set<String>>((ref) => {});

// Holds IDs of tasks pending completion (for optimistic UI - prevents flicker from realtime sync)
final _pendingCompletionProvider = StateProvider<Set<String>>((ref) => {});

/// Applies the optimistic task mutations shared by every task-list view.
///
/// Pending deletions disappear immediately. Pending completions remain in the
/// result as completed tasks so presentation code can move them between its
/// incomplete and completed sections without a stale-data flash.
List<Task> applyOptimisticTaskOverlay(
  List<Task> tasks, {
  required Set<String> pendingDeletion,
  required Set<String> pendingCompletion,
}) {
  return tasks
      .where((task) => !pendingDeletion.contains(task.id))
      .map(
        (task) => pendingCompletion.contains(task.id) && !task.isCompleted
            ? task.copyWith(isCompleted: true)
            : task,
      )
      .toList();
}

AsyncValue<List<Task>> _applyOptimisticTaskOverlay(
  AsyncValue<List<Task>> tasks, {
  required Set<String> pendingDeletion,
  required Set<String> pendingCompletion,
}) {
  return tasks.whenData(
    (value) => applyOptimisticTaskOverlay(
      value,
      pendingDeletion: pendingDeletion,
      pendingCompletion: pendingCompletion,
    ),
  );
}

// Main tasks stream provider - reads from local DB and applies optimistic state.
// Note: Sorting is applied per-view in the UI layer using taskSortNotifierProvider
final tasksStreamProvider =
    Provider.family<AsyncValue<List<Task>>, String?>((ref, projectId) {
  final pendingDeletion = ref.watch(_pendingDeletionProvider);
  final pendingCompletion = ref.watch(_pendingCompletionProvider);
  final stream = ref.watch(_localTasksStreamProvider(projectId));

  return _applyOptimisticTaskOverlay(
    stream,
    pendingDeletion: pendingDeletion,
    pendingCompletion: pendingCompletion,
  );
});

// Inbox tasks from local DB
final _localInboxTasksStreamProvider = StreamProvider<List<Task>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final inbox = await ref.watch(inboxProjectProvider.future);

  if (inbox == null) {
    yield [];
    return;
  }

  yield* db.watchTasks(inbox.id).map((driftTasks) {
    return ModelConverters.tasksFromDrift(driftTasks);
  });
});

final inboxTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final pendingDeletion = ref.watch(_pendingDeletionProvider);
  final pendingCompletion = ref.watch(_pendingCompletionProvider);
  final stream = ref.watch(_localInboxTasksStreamProvider);
  return _applyOptimisticTaskOverlay(
    stream,
    pendingDeletion: pendingDeletion,
    pendingCompletion: pendingCompletion,
  );
});

// Today's tasks from local DB
final _localTodayTasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return db.watchTasksDueToday(user.id).map((driftTasks) {
    return ModelConverters.tasksFromDrift(driftTasks);
  });
});

final todayTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final pendingDeletion = ref.watch(_pendingDeletionProvider);
  final pendingCompletion = ref.watch(_pendingCompletionProvider);
  final stream = ref.watch(_localTodayTasksStreamProvider);
  return _applyOptimisticTaskOverlay(
    stream,
    pendingDeletion: pendingDeletion,
    pendingCompletion: pendingCompletion,
  );
});

// Upcoming tasks from local DB
final _localUpcomingTasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return db.watchUpcomingTasks(user.id).map((driftTasks) {
    return ModelConverters.tasksFromDrift(driftTasks);
  });
});

final upcomingTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final pendingDeletion = ref.watch(_pendingDeletionProvider);
  final pendingCompletion = ref.watch(_pendingCompletionProvider);
  final stream = ref.watch(_localUpcomingTasksStreamProvider);
  return _applyOptimisticTaskOverlay(
    stream,
    pendingDeletion: pendingDeletion,
    pendingCompletion: pendingCompletion,
  );
});

// Subtasks from local DB
final subtasksProvider =
    FutureProvider.family<List<Task>, String>((ref, parentId) async {
  final db = ref.watch(appDatabaseProvider);
  final pendingDeletion = ref.watch(_pendingDeletionProvider);

  final driftTasks =
      await db.watchSubtasks(parentId).first; // Get current value
  final tasks = ModelConverters.tasksFromDrift(driftTasks);
  return tasks.where((t) => !pendingDeletion.contains(t.id)).toList();
});

// Subtasks stream from local DB
final _localSubtasksStreamProvider =
    StreamProvider.family<List<Task>, String>((ref, parentId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSubtasks(parentId).map((driftTasks) {
    return ModelConverters.tasksFromDrift(driftTasks);
  });
});

final subtasksStreamProvider =
    Provider.family<AsyncValue<List<Task>>, String>((ref, parentId) {
  final pendingDeletion = ref.watch(_pendingDeletionProvider);
  final pendingCompletion = ref.watch(_pendingCompletionProvider);
  final stream = ref.watch(_localSubtasksStreamProvider(parentId));
  return stream.whenData((tasks) {
    return tasks.where((task) {
      if (pendingDeletion.contains(task.id)) return false;
      if (pendingCompletion.contains(task.id) && !task.isCompleted) {
        return false;
      }
      return true;
    }).toList();
  });
});

// Provider to fetch a single task by ID (used for parent task lookup)
final taskProvider = FutureProvider.family<Task?, String>((ref, taskId) async {
  final db = ref.watch(appDatabaseProvider);
  final driftTask = await db.getTask(taskId);
  if (driftTask == null) return null;
  return ModelConverters.taskFromDrift(driftTask);
});

class TasksNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final SyncService _syncService;
  final String? _userId;
  final Ref _ref;

  TasksNotifier(this._db, this._syncService, this._userId, this._ref)
      : super(const AsyncValue.data(null));

  void _processPendingOperationsInBackground() {
    unawaited(_processPendingOperationsSafely());
  }

  Future<void> _processPendingOperationsSafely() async {
    try {
      await _syncService.processPendingOperations();
    } catch (_) {
      // Individual operation failures are recorded by SyncService. This only
      // consumes unexpected outer errors so optimistic mutations stay local
      // and the periodic/resume triggers can retry them later.
    }
  }

  Future<Task?> createTask({
    String? id,
    required String projectId,
    required String title,
    String? description,
    DateTime? dueDate,
    String? dueTime,
    int priority = 0,
    String? parentId,
    String? recurrenceRule,
    String? recurrenceParentId,
    DateTime? recurrenceAnchorDate,
  }) async {
    if (_userId == null) return null;

    state = const AsyncValue.loading();
    try {
      // Generate ID locally
      final taskId = id ?? const Uuid().v4();
      final now = DateTime.now();

      final existingTask = await _db.getTask(taskId);
      if (existingTask != null && !existingTask.isDeleted) {
        state = const AsyncValue.data(null);
        return ModelConverters.taskFromDrift(existingTask);
      }

      // Get max sort order
      final existingTasks = await _db.watchTasks(projectId).first;
      final maxSortOrder = existingTasks.isEmpty
          ? -1
          : existingTasks
              .map((t) => t.sortOrder)
              .reduce((a, b) => a > b ? a : b);

      // For recurring tasks, set the anchor date to track the original schedule
      // This ensures rescheduling a single instance doesn't shift future occurrences
      final anchorDate =
          recurrenceAnchorDate ?? (recurrenceRule != null ? dueDate : null);

      final task = Task(
        id: taskId,
        projectId: projectId,
        userId: _userId,
        parentId: parentId,
        title: title,
        description: description,
        dueDate: dueDate,
        dueTime: dueTime,
        priority: priority,
        isCompleted: false,
        sortOrder: maxSortOrder + 1,
        recurrenceRule: recurrenceRule,
        recurrenceParentId: recurrenceParentId,
        recurrenceAnchorDate: anchorDate,
        createdAt: now,
        updatedAt: now,
      );

      // Write to local DB immediately
      await _db.upsertTask(TasksCompanion(
        id: Value(taskId),
        projectId: Value(projectId),
        userId: Value(_userId),
        parentId: Value(parentId),
        title: Value(title),
        description: Value(description),
        dueDate: Value(dueDate),
        dueTime: Value(dueTime),
        priority: Value(priority),
        isCompleted: const Value(false),
        sortOrder: Value(maxSortOrder + 1),
        recurrenceRule: Value(recurrenceRule),
        recurrenceParentId: Value(recurrenceParentId),
        recurrenceAnchorDate: Value(anchorDate),
        createdAt: Value(now),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
        isDeleted: const Value(false),
      ));

      // Queue sync operation
      await _syncService.queueCreate(
        SyncEntityType.task,
        taskId,
        task.toJson(),
      );

      // Optimistic mutations must not wait for the whole queue (each remote
      // operation can take up to the network timeout). The queued CREATE is
      // durable and will also be retried on the periodic/resume triggers.
      _processPendingOperationsInBackground();

      state = const AsyncValue.data(null);
      return task;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateTask({
    required String id,
    String? title,
    String? description,
    bool updateDescription = false,
    DateTime? dueDate,
    bool updateDueDate = false,
    String? dueTime,
    bool updateDueTime = false,
    int? priority,
    String? projectId,
    String? recurrenceRule,
    bool updateRecurrenceRule = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();

      // Build update payload
      final updates = <String, dynamic>{
        'id': id,
        'updated_at': utcIso(now),
      };
      if (title != null) updates['title'] = title;
      // Empty string or explicit null means clear the description.
      if (description != null || updateDescription) {
        updates['description'] =
            description == null || description.isEmpty ? null : description;
      }
      if (dueDate != null || updateDueDate) {
        updates['due_date'] = dateOnly(dueDate);
      }
      if (dueTime != null || updateDueTime) {
        updates['due_time'] = dueTime;
      }
      if (priority != null) updates['priority'] = priority;
      if (projectId != null) updates['project_id'] = projectId;
      if (recurrenceRule != null || updateRecurrenceRule) {
        updates['recurrence_rule'] = recurrenceRule;
      }

      // Update local DB
      await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          title: title != null ? Value(title) : const Value.absent(),
          // Empty string or explicit null means clear the description.
          description: description != null || updateDescription
              ? Value(description == null || description.isEmpty
                  ? null
                  : description)
              : const Value.absent(),
          dueDate: dueDate != null || updateDueDate
              ? Value(dueDate)
              : const Value.absent(),
          dueTime: dueTime != null || updateDueTime
              ? Value(dueTime)
              : const Value.absent(),
          priority: priority != null ? Value(priority) : const Value.absent(),
          projectId:
              projectId != null ? Value(projectId) : const Value.absent(),
          recurrenceRule: recurrenceRule != null || updateRecurrenceRule
              ? Value(recurrenceRule)
              : const Value.absent(),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );

      // Queue sync operation
      await _syncService.queueUpdate(SyncEntityType.task, id, updates);

      _processPendingOperationsInBackground();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reschedules a task to a new due date, or clears the due date if null
  Future<void> rescheduleTask(String id, DateTime? dueDate) async {
    try {
      final now = DateTime.now();

      // Build update payload - explicitly include due_date even if null
      final updates = <String, dynamic>{
        'id': id,
        'due_date': dateOnly(dueDate),
        'due_time': null,
        'updated_at': utcIso(now),
      };

      // Update local DB
      await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          dueDate: Value(dueDate),
          dueTime: const Value(null),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );

      // Queue sync operation
      await _syncService.queueUpdate(SyncEntityType.task, id, updates);

      _processPendingOperationsInBackground();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeTask(String id) async {
    final now = DateTime.now();

    // Get the task to check for recurrence
    final driftTask = await _db.getTask(id);
    if (driftTask == null) return;
    if (driftTask.isCompleted) return;

    final task = ModelConverters.taskFromDrift(driftTask);

    // Update local DB
    final updatedRows = await (_db.update(_db.tasks)
          ..where((t) => t.id.equals(id) & t.isCompleted.equals(false)))
        .write(
      TasksCompanion(
        isCompleted: const Value(true),
        completedAt: Value(now),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );
    if (updatedRows == 0) return;

    // Queue sync
    await _syncService.queueUpdate(SyncEntityType.task, id, {
      'id': id,
      'is_completed': true,
      'completed_at': utcIso(now),
      'updated_at': utcIso(now),
    });

    // Handle recurring tasks - create next occurrence
    if (task.isRecurring && task.recurrenceRule != null) {
      final today = DateTime(now.year, now.month, now.day);

      // Use anchor date for calculating next occurrence to preserve the original schedule
      // This ensures rescheduling a single instance doesn't shift all future occurrences
      // Fall back to dueDate for backward compatibility with tasks created before anchor support
      final anchorDate = task.recurrenceAnchorDate ?? task.dueDate ?? now;

      // Calculate the next occurrence from the anchor date
      // Keep advancing until we find a date that's strictly after today
      // This ensures overdue tasks are scheduled for tomorrow, not today
      DateTime? nextAnchorDate = anchorDate;
      do {
        nextAnchorDate = RecurrenceRule.getNextOccurrence(
          nextAnchorDate!,
          task.recurrenceRule!,
        );
      } while (nextAnchorDate != null && !nextAnchorDate.isAfter(today));

      if (nextAnchorDate != null) {
        final seriesId = task.recurrenceParentId ?? task.id;
        final occurrenceId = _recurringOccurrenceId(
          recurrenceParentId: seriesId,
          dueDate: nextAnchorDate,
        );
        final hasNextOccurrence = await _hasIncompleteRecurringOccurrence(
          projectId: task.projectId,
          recurrenceRule: task.recurrenceRule!,
          recurrenceParentId: seriesId,
          dueDate: nextAnchorDate,
        );

        if (!hasNextOccurrence) {
          await createTask(
            id: occurrenceId,
            projectId: task.projectId,
            title: task.title,
            description: task.description,
            dueDate: nextAnchorDate,
            priority: task.priority,
            parentId: task.parentId,
            recurrenceRule: task.recurrenceRule,
            recurrenceParentId: seriesId,
            recurrenceAnchorDate: nextAnchorDate,
          );
        }
      }
    }

    _processPendingOperationsInBackground();
  }

  Future<bool> _hasIncompleteRecurringOccurrence({
    required String projectId,
    required String recurrenceRule,
    required String recurrenceParentId,
    required DateTime dueDate,
  }) async {
    final userId = _userId;
    if (userId == null) return false;

    final startOfDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final existing = await (_db.select(_db.tasks)
          ..where((t) =>
              t.userId.equals(userId) &
              t.projectId.equals(projectId) &
              t.isDeleted.equals(false) &
              t.isCompleted.equals(false) &
              t.recurrenceRule.equals(recurrenceRule) &
              t.recurrenceParentId.equals(recurrenceParentId) &
              t.dueDate.isBiggerOrEqualValue(startOfDay) &
              t.dueDate.isSmallerThanValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();

    return existing != null;
  }

  String _recurringOccurrenceId({
    required String recurrenceParentId,
    required DateTime dueDate,
  }) {
    final occurrenceDate = _dateKey(dueDate);
    return const Uuid().v5(
      Namespace.url.value,
      'taskboi:recurring-occurrence:v1:$recurrenceParentId:$occurrenceDate',
    );
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> uncompleteTask(String id) async {
    final now = DateTime.now();

    // Load the task first so we can undo any side effects of its completion.
    final driftTask = await _db.getTask(id);
    if (driftTask == null) return;
    final task = ModelConverters.taskFromDrift(driftTask);

    // Update local DB
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: const Value(false),
        completedAt: const Value(null),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );

    // Queue sync
    await _syncService.queueUpdate(SyncEntityType.task, id, {
      'id': id,
      'is_completed': false,
      'completed_at': null,
      'updated_at': utcIso(now),
    });

    // Completing a recurring task spawns the next occurrence (see
    // completeTask). Re-opening it must remove that spawned occurrence,
    // otherwise the series ends up with two incomplete instances (e.g. the
    // due-null template plus a dated occurrence) that both surface in the
    // Today view as duplicates.
    if (task.isRecurring && task.recurrenceRule != null) {
      final seriesId = task.recurrenceParentId ?? task.id;
      await _removeIncompleteSeriesOccurrences(
        seriesId: seriesId,
        excludingId: task.id,
      );
    }

    _processPendingOperationsInBackground();
  }

  /// Soft-deletes every *other* incomplete instance of the same recurring
  /// series. Used to reverse the occurrence that [completeTask] spawns, so a
  /// series never has more than one active (incomplete) instance at a time.
  Future<void> _removeIncompleteSeriesOccurrences({
    required String seriesId,
    required String excludingId,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    // Match only spawned occurrences (recurrenceParentId == seriesId), never
    // the series root itself, and never the instance being re-opened.
    final occurrences = await (_db.select(_db.tasks)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              t.isCompleted.equals(false) &
              t.id.isNotIn([excludingId]) &
              t.recurrenceParentId.equals(seriesId)))
        .get();

    for (final occ in occurrences) {
      await _db.softDeleteTask(occ.id);
      await _syncService.queueDelete(SyncEntityType.task, occ.id);
    }
  }

  Future<void> toggleComplete(Task task) async {
    if (task.isCompleted) {
      await uncompleteTask(task.id);
    } else {
      await completeTask(task.id);
    }
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    try {
      // Soft delete in local DB
      await _db.softDeleteTask(id);

      // Queue sync operation
      await _syncService.queueDelete(SyncEntityType.task, id);

      _processPendingOperationsInBackground();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Mark a task as pending deletion (hides from UI immediately)
  void markPendingDeletion(String taskId) {
    final current = _ref.read(_pendingDeletionProvider);
    _ref.read(_pendingDeletionProvider.notifier).state = {...current, taskId};
  }

  /// Clear pending deletion status (task reappears if not actually deleted)
  void clearPendingDeletion(String taskId) {
    final current = _ref.read(_pendingDeletionProvider);
    _ref.read(_pendingDeletionProvider.notifier).state =
        current.where((id) => id != taskId).toSet();
  }

  /// Mark a task as pending completion (hides from incomplete list immediately)
  void markPendingCompletion(String taskId) {
    final current = _ref.read(_pendingCompletionProvider);
    _ref.read(_pendingCompletionProvider.notifier).state = {...current, taskId};
  }

  /// Clear pending completion status
  void clearPendingCompletion(String taskId) {
    final current = _ref.read(_pendingCompletionProvider);
    _ref.read(_pendingCompletionProvider.notifier).state =
        current.where((id) => id != taskId).toSet();
  }

  /// Move a task to a different project with undo support
  Future<String?> moveTaskToProject({
    required String taskId,
    required String newProjectId,
  }) async {
    try {
      final driftTask = await _db.getTask(taskId);
      if (driftTask == null) return null;

      final previousProjectId = driftTask.projectId;
      final now = DateTime.now();

      // Update local DB
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          projectId: Value(newProjectId),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );

      // Queue sync
      await _syncService.queueUpdate(SyncEntityType.task, taskId, {
        'id': taskId,
        'project_id': newProjectId,
        'updated_at': utcIso(now),
      });

      _processPendingOperationsInBackground();

      return previousProjectId;
    } catch (e) {
      return null;
    }
  }

  Future<void> reorderTasks(
      List<Task> reorderedTasks, String? projectId) async {
    final now = DateTime.now();

    // Update sort orders in local DB
    for (int i = 0; i < reorderedTasks.length; i++) {
      final task = reorderedTasks[i];
      await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(
          sortOrder: Value(i),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );

      // Queue sync for each task
      await _syncService.queueUpdate(
        SyncEntityType.task,
        task.id,
        {'id': task.id, 'sort_order': i, 'updated_at': utcIso(now)},
      );
    }

    _processPendingOperationsInBackground();
  }
}

final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  final userId = ref.watch(currentUserProvider)?.id;

  return TasksNotifier(db, syncService, userId, ref);
});
