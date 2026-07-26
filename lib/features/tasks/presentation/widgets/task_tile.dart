import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../projects/providers/projects_provider.dart';
import '../../data/models/task.dart';
import '../../providers/tasks_provider.dart';
import 'task_detail_sheet.dart';
import 'task_form.dart';
import 'undo_snackbar.dart';

class TaskTile extends ConsumerStatefulWidget {
  final Task task;
  final bool showProject;

  const TaskTile({
    super.key,
    required this.task,
    this.showProject = false,
  });

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile>
    with SingleTickerProviderStateMixin {
  final MenuController _menuController = MenuController();
  Offset _menuPosition = Offset.zero;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    // Haptic feedback for satisfaction
    HapticFeedback.mediumImpact();

    // Capture ScaffoldMessenger and task info BEFORE animation starts
    // The context may become invalid after the fade animation completes
    final messenger = ScaffoldMessenger.of(context);
    final taskId = widget.task.id;
    final taskTitle = widget.task.title;
    final wasCompleted = widget.task.isCompleted;

    // Start fade animation BEFORE marking pending completion
    // (marking pending causes the task to be filtered out, which disposes this widget)
    await _fadeController.forward();

    if (!mounted) return;

    // Now mark as pending completion and complete the task
    // Use captured values since widget may be disposed after marking pending
    final notifier = ref.read(tasksNotifierProvider.notifier);
    notifier.markPendingCompletion(taskId);

    ref.toggleCompleteWithUndo(
      context,
      taskId,
      taskTitle,
      wasCompleted,
      messenger: messenger,
    );
  }

  void _handleUncomplete() {
    // Light haptic for uncomplete too
    HapticFeedback.selectionClick();

    ref.toggleCompleteWithUndo(
      context,
      widget.task.id,
      widget.task.title,
      widget.task.isCompleted,
    );
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TaskFormSheet(
        projectId: widget.task.projectId,
        task: widget.task,
      ),
    );
  }

  void _openDetailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(task: widget.task),
    );
  }

  Future<void> _moveToProject(String projectId) async {
    final task = widget.task;
    final oldProjectId = task.projectId;
    await ref.read(tasksNotifierProvider.notifier).updateTask(
          id: task.id,
          projectId: projectId,
        );
    ref.invalidate(tasksStreamProvider(oldProjectId));
    ref.invalidate(tasksStreamProvider(projectId));
    ref.invalidate(todayTasksProvider);
    ref.invalidate(upcomingTasksProvider);
    ref.invalidate(inboxTasksProvider);
  }

  Future<void> _setPriority(int priority) async {
    final task = widget.task;
    await ref.read(tasksNotifierProvider.notifier).updateTask(
          id: task.id,
          priority: priority,
        );
  }

  Future<void> _rescheduleTask(DateTime? dueDate) async {
    await ref.read(tasksNotifierProvider.notifier).rescheduleTask(
          widget.task.id,
          dueDate,
        );
  }

  DateTime _getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _getTomorrow() {
    return _getToday().add(const Duration(days: 1));
  }

  DateTime _getThisWeekend() {
    final today = _getToday();
    final daysUntilSaturday = (DateTime.saturday - today.weekday) % 7;
    if (daysUntilSaturday == 0 || today.weekday == DateTime.sunday) {
      return today;
    }
    return today.add(Duration(days: daysUntilSaturday));
  }

  DateTime _getNextWeek() {
    final today = _getToday();
    final daysUntilMonday = (DateTime.monday - today.weekday + 7) % 7;
    if (daysUntilMonday == 0) {
      return today.add(const Duration(days: 7));
    }
    return today.add(Duration(days: daysUntilMonday));
  }

  Future<void> _confirmDelete(BuildContext context, int subtaskCount) async {
    final task = widget.task;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${task.title}"?${subtaskCount > 0 ? '\n\nThis will also delete $subtaskCount subtask(s).' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      UndoSnackBarService.showTaskDeleted(
        // context is unused here (an explicit messenger is passed), so it's
        // safe across the dialog's async gap.
        // ignore: use_build_context_synchronously
        context,
        ref,
        taskId: task.id,
        message: '"${task.title}" deleted',
        messenger: scaffoldMessenger,
      );
    }
  }

  List<Widget> _buildMenuChildren(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final task = widget.task;
    final subtasksAsync = ref.read(subtasksStreamProvider(task.id));
    final subtaskCount = subtasksAsync.valueOrNull?.length ?? 0;
    final projects = ref.read(projectsStreamProvider).valueOrNull ?? [];

    return [
      // Edit
      MenuItemButton(
        leadingIcon: const Icon(Icons.edit, size: 20),
        child: Text(l10n.edit),
        onPressed: () {
          _menuController.close();
          _openEditSheet();
        },
      ),
      // Reschedule submenu with horizontal icons
      SubmenuButton(
        leadingIcon: const Icon(Icons.schedule, size: 20),
        menuChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRescheduleIcon(
                  icon: Icons.today,
                  color: Colors.green,
                  tooltip: l10n.today,
                  onTap: () {
                    _menuController.close();
                    _rescheduleTask(_getToday());
                  },
                ),
                const SizedBox(width: 4),
                _buildRescheduleIcon(
                  icon: Icons.wb_sunny_outlined,
                  color: Colors.orange,
                  tooltip: l10n.tomorrow,
                  onTap: () {
                    _menuController.close();
                    _rescheduleTask(_getTomorrow());
                  },
                ),
                const SizedBox(width: 4),
                _buildRescheduleIcon(
                  icon: Icons.weekend_outlined,
                  color: Colors.blue,
                  tooltip: l10n.thisWeekend,
                  onTap: () {
                    _menuController.close();
                    _rescheduleTask(_getThisWeekend());
                  },
                ),
                const SizedBox(width: 4),
                _buildRescheduleIcon(
                  icon: Icons.next_week_outlined,
                  color: Colors.purple,
                  tooltip: l10n.nextWeek,
                  onTap: () {
                    _menuController.close();
                    _rescheduleTask(_getNextWeek());
                  },
                ),
                const SizedBox(width: 4),
                _buildRescheduleIcon(
                  icon: Icons.block,
                  color: Colors.grey,
                  tooltip: l10n.noDate,
                  onTap: () {
                    _menuController.close();
                    _rescheduleTask(null);
                  },
                ),
              ],
            ),
          ),
        ],
        child: Text(l10n.reschedule),
      ),
      // Move to Project submenu
      SubmenuButton(
        leadingIcon: const Icon(Icons.drive_file_move_outline, size: 20),
        menuChildren: projects.map((project) {
          final isCurrentProject = project.id == task.projectId;
          return MenuItemButton(
            leadingIcon: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _parseColor(project.color),
                shape: BoxShape.circle,
              ),
            ),
            trailingIcon: isCurrentProject
                ? const Icon(Icons.check, size: 18, color: Colors.grey)
                : null,
            onPressed: isCurrentProject
                ? null
                : () {
                    _menuController.close();
                    _moveToProject(project.id);
                  },
            child: Text(
              project.name,
              style: TextStyle(
                color: isCurrentProject ? Colors.grey : null,
              ),
            ),
          );
        }).toList(),
        child: Text(l10n.moveToProject),
      ),
      // Set Priority submenu
      SubmenuButton(
        leadingIcon: Icon(Icons.flag,
            size: 20, color: TaskPriority.getColor(task.priority)),
        menuChildren: [
          _buildPriorityMenuItem(
              l10n, TaskPriority.urgent, l10n.priorityUrgent, task.priority),
          _buildPriorityMenuItem(
              l10n, TaskPriority.high, l10n.priorityHigh, task.priority),
          _buildPriorityMenuItem(
              l10n, TaskPriority.medium, l10n.priorityMedium, task.priority),
          _buildPriorityMenuItem(
              l10n, TaskPriority.low, l10n.priorityLow, task.priority),
          _buildPriorityMenuItem(
              l10n, TaskPriority.none, l10n.priorityNone, task.priority),
        ],
        child: Text(l10n.setPriority),
      ),
      // Add Subtask
      MenuItemButton(
        leadingIcon: const Icon(Icons.add_task, size: 20),
        child: Text(l10n.addSubtask),
        onPressed: () {
          _menuController.close();
          _openDetailSheet();
        },
      ),
      // Toggle Complete
      MenuItemButton(
        leadingIcon: Icon(
          task.isCompleted ? Icons.radio_button_unchecked : Icons.check_circle,
          size: 20,
        ),
        child: Text(task.isCompleted ? l10n.markIncomplete : l10n.markComplete),
        onPressed: () {
          _menuController.close();
          // Haptic feedback for satisfaction
          if (task.isCompleted) {
            HapticFeedback.selectionClick();
          } else {
            HapticFeedback.mediumImpact();
          }
          // Use the same undo pattern as checkbox for consistency
          if (!task.isCompleted) {
            // Mark pending completion before completing
            ref
                .read(tasksNotifierProvider.notifier)
                .markPendingCompletion(task.id);
          }
          ref.toggleCompleteWithUndo(
            context,
            task.id,
            task.title,
            task.isCompleted,
          );
        },
      ),
      // Delete
      MenuItemButton(
        leadingIcon: const Icon(Icons.delete, size: 20, color: Colors.red),
        child: Text(
          subtaskCount > 0
              ? l10n.deleteWithSubtasks(subtaskCount)
              : l10n.delete,
          style: const TextStyle(color: Colors.red),
        ),
        onPressed: () {
          _menuController.close();
          _confirmDelete(context, subtaskCount);
        },
      ),
    ];
  }

  MenuItemButton _buildPriorityMenuItem(
      AppLocalizations l10n, int priority, String label, int currentPriority) {
    final isSelected = priority == currentPriority;
    return MenuItemButton(
      leadingIcon: Icon(
        Icons.flag,
        size: 20,
        color: TaskPriority.getColor(priority),
      ),
      trailingIcon: isSelected ? const Icon(Icons.check, size: 18) : null,
      onPressed: isSelected
          ? null
          : () {
              _menuController.close();
              _setPriority(priority);
            },
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _buildRescheduleIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final theme = Theme.of(context);
    final priorityColor = TaskPriority.getColor(task.priority);
    final isOverdue = task.dueDate != null &&
        !task.isCompleted &&
        task.dueDate!
            .isBefore(DateTime.now().subtract(const Duration(days: 1)));

    // Watch subtasks to show count
    final subtasksAsync = ref.watch(subtasksStreamProvider(task.id));
    final subtaskCount = subtasksAsync.valueOrNull?.length ?? 0;
    final completedSubtaskCount =
        subtasksAsync.valueOrNull?.where((t) => t.isCompleted).length ?? 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizeTransition(
        sizeFactor: _fadeAnimation,
        alignment: Alignment.topCenter,
        child: MenuAnchor(
          controller: _menuController,
          menuChildren: _buildMenuChildren(context),
          alignmentOffset: _menuPosition,
          child: GestureDetector(
            // Use onSecondaryTapUp to open context menu on right-click release.
            // This integrates with Flutter's gesture arena and avoids conflicts
            // with ReorderableDelayedDragStartListener.
            behavior: HitTestBehavior.translucent,
            onSecondaryTapUp: (details) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition =
                  renderBox.globalToLocal(details.globalPosition);
              setState(() {
                _menuPosition = localPosition;
              });
              _menuController.open(position: localPosition);
            },
            child: InkWell(
              onTap: _openDetailSheet,
              // Long press is disabled to allow drag-and-drop reordering.
              // Context menu: right-click on desktop, tap to open detail sheet on mobile.
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          if (task.isCompleted) {
                            _handleUncomplete();
                          } else {
                            _handleComplete();
                          }
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: task.isCompleted
                                  ? Colors.grey
                                  : (task.priority > 0
                                      ? priorityColor
                                      : Colors.grey.shade400),
                              width: 2,
                            ),
                            color:
                                task.isCompleted ? Colors.grey.shade300 : null,
                          ),
                          child: task.isCompleted
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            task.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted ? Colors.grey : null,
                            ),
                          ),
                          // Description (1 line max)
                          if (task.description != null &&
                              task.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                task.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: task.isCompleted
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          // Metadata row
                          _buildMetadataRow(context, task, isOverdue,
                              subtaskCount, completedSubtaskCount),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, Task task, bool isOverdue,
      int subtaskCount, int completedSubtaskCount) {
    final l10n = AppLocalizations.of(context)!;
    final items = <Widget>[];

    // Due date
    if (task.dueDate != null) {
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 12,
            color: isOverdue ? Colors.red : Colors.grey.shade600,
          ),
          const SizedBox(width: 3),
          Text(
            task.dueTime != null
                ? '${_formatDueDate(task.dueDate!, l10n)} ${_formatTime(task.dueTime!)}'
                : _formatDueDate(task.dueDate!, l10n),
            style: TextStyle(
              color: isOverdue ? Colors.red : Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ));
    }

    // Recurring indicator
    if (task.isRecurring) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 8));
      items.add(Icon(
        Icons.repeat,
        size: 12,
        color: Colors.grey.shade600,
      ));
    }

    // Subtask count
    if (subtaskCount > 0) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 8));
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 2),
          Text(
            '$completedSubtaskCount/$subtaskCount',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ));
    }

    // Project name (right-aligned)
    if (widget.showProject) {
      final projectAsync = ref.watch(projectProvider(task.projectId));
      projectAsync.whenData((project) {
        if (project != null) {
          items.add(const Spacer());
          items.add(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _parseColor(project.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                project.name,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ));
        }
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: items,
      ),
    );
  }

  String _formatDueDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return l10n.today;
    if (dateOnly == tomorrow) return l10n.tomorrow;
    if (dateOnly.isBefore(today)) {
      return DateFormat('MMM d').format(date);
    }
    if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    }
    return DateFormat('MMM d, y').format(date);
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
