import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/connectivity/connectivity_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/delayed_reorderable_listener.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../projects/providers/projects_provider.dart';
import '../../data/models/task.dart';
import '../../providers/tasks_provider.dart';
import '../widgets/quick_add_task_sheet.dart';
import '../widgets/task_tile.dart';
import '../widgets/undo_snackbar.dart';

List<Task> mergeExitingTaskSnapshots(
  Iterable<Task> sourceTasks,
  Iterable<Task> exitingSnapshots,
) {
  final snapshotsById = {
    for (final snapshot in exitingSnapshots) snapshot.id: snapshot,
  };
  final mergedTasks = <Task>[];
  final addedIds = <String>{};

  for (final task in sourceTasks) {
    if (addedIds.add(task.id)) {
      mergedTasks.add(snapshotsById.remove(task.id) ?? task);
    }
  }
  for (final snapshot in snapshotsById.values) {
    if (addedIds.add(snapshot.id)) {
      mergedTasks.add(snapshot);
    }
  }

  return mergedTasks;
}

class TaskListScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final TaskFilter filter;

  const TaskListScreen({
    super.key,
    this.projectId,
    this.filter = TaskFilter.all,
  });

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final MenuController _sortMenuController = MenuController();
  final Map<String, Task> _exitingTasks = {};

  /// Get the view key for the current screen (used for per-view sort persistence)
  String get _viewKey {
    switch (widget.filter) {
      case TaskFilter.today:
        return TaskViewKey.today;
      case TaskFilter.upcoming:
        return TaskViewKey.upcoming;
      case TaskFilter.all:
        if (widget.projectId != null) {
          return TaskViewKey.project(widget.projectId!);
        }
        return TaskViewKey.inbox;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(context, ref),
        automaticallyImplyLeading: false,
        actions: [
          // Show refresh button on web since pull-to-refresh doesn't work well
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _onRefresh(ref),
              tooltip: 'Refresh',
            ),
          _buildSortMenuButton(context, ref),
        ],
      ),
      body: _buildTaskList(context, ref),
      floatingActionButton:
          widget.filter == TaskFilter.all || widget.filter == TaskFilter.today
              ? FloatingActionButton(
                  onPressed: () => _showAddTaskDialog(context, ref),
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }

  Widget _buildSortMenuButton(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentSort = ref.watch(taskSortNotifierProvider(_viewKey));
    final showCompleted = ref.watch(showCompletedProvider(_viewKey));
    final isUpcoming = widget.filter == TaskFilter.upcoming;

    return MenuAnchor(
      controller: _sortMenuController,
      menuChildren: [
        // Sort options
        ...TaskSortOption.values.map((option) {
          final isSelected = option == currentSort;
          return MenuItemButton(
            leadingIcon: Icon(
              _getSortIcon(option),
              size: 20,
            ),
            trailingIcon: isSelected ? const Icon(Icons.check, size: 18) : null,
            onPressed: () {
              _sortMenuController.close();
              ref
                  .read(taskSortNotifierProvider(_viewKey).notifier)
                  .setSortOption(option);
            },
            child: Text(
              option.localizedLabel(l10n),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        }),
        // Show completed toggle (not applicable for upcoming view)
        if (!isUpcoming) ...[
          const Divider(height: 8),
          MenuItemButton(
            leadingIcon: Icon(
              showCompleted ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
            ),
            onPressed: () {
              toggleShowCompleted(ref, _viewKey);
            },
            child: Text(l10n.showCompleted),
          ),
        ],
      ],
      child: IconButton(
        icon: const Icon(Icons.sort, size: 20),
        onPressed: () => _sortMenuController.open(),
        tooltip: l10n.sortTasks,
      ),
    );
  }

  IconData _getSortIcon(TaskSortOption option) {
    switch (option) {
      case TaskSortOption.manual:
        return Icons.drag_handle;
      case TaskSortOption.priority:
        return Icons.flag;
      case TaskSortOption.dueDate:
        return Icons.calendar_today;
      case TaskSortOption.title:
        return Icons.sort_by_alpha;
      case TaskSortOption.createdAt:
        return Icons.access_time;
    }
  }

  Widget _buildTitle(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.filter) {
      case TaskFilter.today:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.today),
            Text(
              DateFormat('EEE, MMM d').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        );
      case TaskFilter.upcoming:
        return Text(l10n.upcoming);
      case TaskFilter.all:
        if (widget.projectId != null) {
          final projectAsync = ref.watch(projectProvider(widget.projectId!));
          return projectAsync.when(
            data: (project) => Text(project?.name ?? l10n.project),
            loading: () => Text(l10n.loading),
            error: (_, __) => Text(l10n.project),
          );
        }
        return Text(l10n.inbox);
    }
  }

  Widget _buildTaskList(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      child: switch (widget.filter) {
        TaskFilter.today => _buildTodayTasks(context, ref),
        TaskFilter.upcoming => _buildUpcomingTasks(context, ref),
        TaskFilter.all => _buildProjectTasks(context, ref),
      },
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      // Can't refresh while offline
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final syncService = ref.read(syncServiceProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Process any pending operations first
      await syncService.processPendingOperations();

      // Then do a full sync to get latest from server
      await syncService.performFullSync(user.id);
    } catch (e) {
      // Show visual feedback if sync fails instead of silent failure
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildTodayTasks(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final syncComplete = ref.watch(initialSyncCompleteProvider);

    // Show loading while initial sync is in progress
    if (!syncComplete) {
      return const Center(child: CircularProgressIndicator());
    }

    final tasksAsync = ref.watch(todayTasksProvider);
    final sortOption = ref.watch(taskSortNotifierProvider(_viewKey));

    return tasksAsync.when(
      data: (tasks) {
        final sortedTasks = applySorting(tasks, sortOption);
        return _buildTaskListView(
            context, ref, sortedTasks, l10n.noTasksDueToday,
            showProject: true, sortOption: sortOption);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.error(error.toString()))),
    );
  }

  Widget _buildUpcomingTasks(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final syncComplete = ref.watch(initialSyncCompleteProvider);

    // Show loading while initial sync is in progress
    if (!syncComplete) {
      return const Center(child: CircularProgressIndicator());
    }

    final tasksAsync = ref.watch(upcomingTasksProvider);
    final sortOption = ref.watch(taskSortNotifierProvider(_viewKey));

    return tasksAsync.when(
      data: (tasks) {
        // Apply per-view sorting
        final sortedTasks = applySorting(
          mergeExitingTaskSnapshots(
            tasks.where((task) => !task.isCompleted),
            _exitingTasks.values,
          ),
          sortOption,
        );

        // Group tasks by date
        final grouped = <DateTime, List<Task>>{};
        for (final task in sortedTasks) {
          if (task.dueDate != null) {
            final date = DateTime(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
            );
            grouped.putIfAbsent(date, () => []).add(task);
          }
        }

        final sortedDates = grouped.keys.toList()..sort();

        return CustomScrollView(
          key: ValueKey('task-list-$_viewKey'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (sortedDates.isEmpty)
              _buildEmptyStateSliver(l10n.noUpcomingTasks)
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final date = sortedDates[index];
                    final dateTasks = grouped[date]!;
                    final isToday = _isToday(date);
                    final isTomorrow = _isTomorrow(date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            isToday
                                ? l10n.today
                                : isTomorrow
                                    ? l10n.tomorrow
                                    : DateFormat('EEE, MMM d').format(date),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                          ),
                        ),
                        ...dateTasks.map((task) {
                          final exiting = _exitingTasks.containsKey(task.id);
                          final tile = TaskTile(
                            key: ValueKey(task.id),
                            task: task,
                            showProject: true,
                            onToggleComplete:
                                exiting ? null : _toggleTaskCompletion,
                          );
                          if (!exiting) return tile;
                          return _CompletionExitTransition(
                            key: ValueKey('completion-exit-${task.id}'),
                            onFinished: () => _finishCompletionExit(task.id),
                            child: IgnorePointer(child: tile),
                          );
                        }),
                      ],
                    );
                  },
                  childCount: sortedDates.length,
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.error(error.toString()))),
    );
  }

  Widget _buildProjectTasks(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final syncComplete = ref.watch(initialSyncCompleteProvider);

    // Show loading while initial sync is in progress
    if (!syncComplete) {
      return const Center(child: CircularProgressIndicator());
    }

    final AsyncValue<List<Task>> tasksAsync;
    final sortOption = ref.watch(taskSortNotifierProvider(_viewKey));

    if (widget.projectId != null) {
      tasksAsync = ref.watch(tasksStreamProvider(widget.projectId));
    } else {
      tasksAsync = ref.watch(inboxTasksProvider);
    }

    return tasksAsync.when(
      data: (tasks) {
        // Filter out subtasks from the main list
        final mainTasks = tasks.where((t) => t.parentId == null).toList();
        // Apply per-view sorting
        final sortedTasks = applySorting(mainTasks, sortOption);
        return _buildTaskListView(
          context,
          ref,
          sortedTasks,
          widget.projectId == null
              ? l10n.yourInboxIsEmpty
              : l10n.noTasksInProject,
          sortOption: sortOption,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.error(error.toString()))),
    );
  }

  Widget _buildTaskListView(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
    String emptyMessage, {
    bool showProject = false,
    TaskSortOption sortOption = TaskSortOption.manual,
  }) {
    final showCompleted = ref.watch(showCompletedProvider(_viewKey));

    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks
        .where(
          (task) => task.isCompleted && !_exitingTasks.containsKey(task.id),
        )
        .toList();
    final transitioningTasks = applySorting(
      mergeExitingTaskSnapshots(incompleteTasks, _exitingTasks.values),
      sortOption,
    );
    final hasVisibleTasks = transitioningTasks.isNotEmpty ||
        (showCompleted && completedTasks.isNotEmpty);

    // Only allow drag-and-drop reordering when sorting is set to manual
    final canReorder = sortOption == TaskSortOption.manual;

    return CustomScrollView(
      key: ValueKey('task-list-$_viewKey'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (!hasVisibleTasks)
          _buildEmptyStateSliver(emptyMessage)
        else if (canReorder && _exitingTasks.isEmpty)
          SliverReorderableList(
            itemCount: incompleteTasks.length,
            onReorderItem: (oldIndex, newIndex) {
              final reorderedTasks = List.of(incompleteTasks);
              final movedTask = reorderedTasks.removeAt(oldIndex);
              reorderedTasks.insert(newIndex, movedTask);
              ref
                  .read(tasksNotifierProvider.notifier)
                  .reorderTasks(reorderedTasks, widget.projectId);
            },
            itemBuilder: (context, index) {
              final task = incompleteTasks[index];
              return DelayedReorderableListener(
                key: ValueKey(task.id),
                index: index,
                child: TaskTile(
                  task: task,
                  showProject: showProject,
                  onToggleComplete: _toggleTaskCompletion,
                ),
              );
            },
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = transitioningTasks[index];
                final exiting = _exitingTasks.containsKey(task.id);
                final tile = TaskTile(
                  key: ValueKey(task.id),
                  task: task,
                  showProject: showProject,
                  onToggleComplete: exiting ? null : _toggleTaskCompletion,
                );
                if (!exiting) return tile;
                return _CompletionExitTransition(
                  key: ValueKey('completion-exit-${task.id}'),
                  onFinished: () => _finishCompletionExit(task.id),
                  child: IgnorePointer(child: tile),
                );
              },
              childCount: transitioningTasks.length,
            ),
          ),
        if (showCompleted && completedTasks.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Divider(height: 32),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppLocalizations.of(context)!
                    .completedCount(completedTasks.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = completedTasks[index];
                return TaskTile(
                  key: ValueKey(task.id),
                  task: task,
                  showProject: showProject,
                );
              },
              childCount: completedTasks.length,
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  SliverFillRemaining _buildEmptyStateSliver(String message) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.filter == TaskFilter.all ||
                widget.filter == TaskFilter.today)
              Text(
                AppLocalizations.of(context)!.tapToAddTask,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleTaskCompletion(Task task) {
    if (!task.isCompleted) {
      setState(() {
        _exitingTasks[task.id] = task;
      });
    }
    ref.toggleCompleteWithUndo(
      context,
      task.id,
      task.title,
      task.isCompleted,
    );
  }

  void _finishCompletionExit(String taskId) {
    if (!mounted || !_exitingTasks.containsKey(taskId)) return;
    setState(() {
      _exitingTasks.remove(taskId);
    });
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) async {
    String? targetProjectId = widget.projectId;

    if (targetProjectId == null) {
      final inbox = await ref.read(inboxProjectProvider.future);
      targetProjectId = inbox?.id;
    }

    if (targetProjectId == null) return;

    if (context.mounted) {
      final initialDueDate =
          widget.filter == TaskFilter.today ? DateTime.now() : null;
      showQuickAddTaskSheet(
        context,
        projectId: targetProjectId,
        initialDueDate: initialDueDate,
      );
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }
}

class _CompletionExitTransition extends StatefulWidget {
  const _CompletionExitTransition({
    super.key,
    required this.onFinished,
    required this.child,
  });

  final VoidCallback onFinished;
  final Widget child;

  @override
  State<_CompletionExitTransition> createState() =>
      _CompletionExitTransitionState();
}

class _CompletionExitTransitionState extends State<_CompletionExitTransition>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 180);
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _duration, vsync: this);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exit = ReverseAnimation(_animation);
    return FadeTransition(
      opacity: exit,
      child: SizeTransition(
        sizeFactor: exit,
        alignment: Alignment.topCenter,
        child: widget.child,
      ),
    );
  }
}
