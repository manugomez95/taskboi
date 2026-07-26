import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../comments/presentation/widgets/comment_list.dart';
import '../../../comments/providers/comments_provider.dart';
import '../../../projects/providers/projects_provider.dart';
import '../../data/models/task.dart';
import '../../providers/tasks_provider.dart';
import 'advanced_date_picker.dart';
import 'quick_add_task_sheet.dart';
import 'subtask_list.dart';
import 'undo_snackbar.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailSheet({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late Task _task;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController = TextEditingController(text: _task.title);
    _descriptionController =
        TextEditingController(text: _task.description ?? '');
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _hasUnsavedChanges {
    if (!_isEditing) return false;
    return _titleController.text != _task.title ||
        _descriptionController.text != (_task.description ?? '');
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.discardChangesTitle),
        content: Text(l10n.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handlePopAttempt(bool didPop, dynamic result) async {
    if (didPop) return;
    final shouldDiscard = await _confirmDiscard();
    if (shouldDiscard && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveAndStopEditing() {
    final newTitle = _titleController.text.trim();
    final newDescription = _descriptionController.text.trim();

    if (newTitle.isEmpty) {
      _titleController.text = _task.title;
      setState(() => _isEditing = false);
      return;
    }

    final titleChanged = newTitle != _task.title;
    final descChanged = newDescription != (_task.description ?? '');

    setState(() {
      _isEditing = false;
      if (titleChanged || descChanged) {
        _task = _task.copyWith(
          title: newTitle,
          description: newDescription.isEmpty ? null : newDescription,
        );
      }
    });

    if (titleChanged || descChanged) {
      ref.read(tasksNotifierProvider.notifier).updateTask(
            id: _task.id,
            title: titleChanged ? newTitle : null,
            description: descChanged ? newDescription : null,
            updateDescription: descChanged,
          );
    }
  }

  Future<void> _openDatePicker() async {
    final result = await showAdvancedDatePicker(
      context: context,
      initialDate: _task.dueDate,
      initialTime: _task.dueTime,
      initialRecurrence: _task.recurrenceRule,
    );

    if (result != null) {
      await ref.read(tasksNotifierProvider.notifier).updateTask(
            id: _task.id,
            dueDate: result.dueDate,
            updateDueDate: true,
            dueTime: result.dueTime,
            updateDueTime: true,
            recurrenceRule: result.recurrenceRule,
            updateRecurrenceRule: true,
          );
      setState(() {
        _task = _task.copyWith(
          dueDate: result.dueDate,
          dueTime: result.dueTime,
          recurrenceRule: result.recurrenceRule,
        );
      });
    }
  }

  void _showPriorityPicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.priority,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(height: 1),
            _PriorityOption(
              priority: TaskPriority.urgent,
              label: l10n.priorityUrgent,
              isSelected: _task.priority == TaskPriority.urgent,
              onTap: () => _setPriority(TaskPriority.urgent),
            ),
            _PriorityOption(
              priority: TaskPriority.high,
              label: l10n.priorityHigh,
              isSelected: _task.priority == TaskPriority.high,
              onTap: () => _setPriority(TaskPriority.high),
            ),
            _PriorityOption(
              priority: TaskPriority.medium,
              label: l10n.priorityNormal,
              isSelected: _task.priority == TaskPriority.medium,
              onTap: () => _setPriority(TaskPriority.medium),
            ),
            _PriorityOption(
              priority: TaskPriority.low,
              label: l10n.priorityLow,
              isSelected: _task.priority == TaskPriority.low,
              onTap: () => _setPriority(TaskPriority.low),
            ),
            _PriorityOption(
              priority: TaskPriority.none,
              label: l10n.priorityNone,
              isSelected: _task.priority == TaskPriority.none,
              onTap: () => _setPriority(TaskPriority.none),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _setPriority(int priority) async {
    Navigator.of(context).pop();
    await ref.read(tasksNotifierProvider.notifier).updateTask(
          id: _task.id,
          priority: priority,
        );
    setState(() {
      _task = _task.copyWith(priority: priority);
    });
  }

  void _showMoreMenu() {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.read(projectsStreamProvider).valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: Text(l10n.moveToProject),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showMoveToProjectSheet(projects);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMoveToProjectSheet(List<dynamic> projects) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.moveToProject,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final isCurrentProject = project.id == _task.projectId;
                    return ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _parseColor(project.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(project.name),
                      trailing: isCurrentProject
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      enabled: !isCurrentProject,
                      onTap: () {
                        Navigator.pop(context);
                        _moveToProject(project.id);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveToProject(String projectId) async {
    final oldProjectId = _task.projectId;
    await ref.read(tasksNotifierProvider.notifier).updateTask(
          id: _task.id,
          projectId: projectId,
        );
    ref.invalidate(tasksStreamProvider(oldProjectId));
    ref.invalidate(tasksStreamProvider(projectId));
    if (mounted) {
      Navigator.pop(context); // Close detail sheet after move
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text(l10n.deleteTaskConfirmation(_task.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      navigator.pop(); // Close detail sheet first
      UndoSnackBarService.showTaskDeleted(
        // context is unused here (an explicit messenger is passed), so it's
        // safe across the dialog's async gap.
        // ignore: use_build_context_synchronously
        context,
        ref,
        taskId: _task.id,
        message: '"${_task.title}" deleted',
        messenger: scaffoldMessenger,
      );
    }
  }

  void _openAddSubtaskSheet() {
    showQuickAddTaskSheet(
      context,
      projectId: _task.projectId,
      parentId: _task.id,
    );
  }

  String _formatDueDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return l10n.today;
    if (dateOnly == tomorrow) return l10n.tomorrow;
    if (date.year == now.year) {
      return DateFormat('EEE, MMM d').format(date);
    }
    return DateFormat('MMM d, y').format(date);
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final projectAsync = ref.watch(projectProvider(_task.projectId));
    final parentTaskAsync = _task.parentId != null
        ? ref.watch(taskProvider(_task.parentId!))
        : null;
    final subtasksAsync = ref.watch(subtasksStreamProvider(_task.id));
    final subtasks = subtasksAsync.valueOrNull ?? [];
    final completedCount = subtasks.where((t) => t.isCompleted).length;
    final priorityColor = TaskPriority.getColor(_task.priority);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: _handlePopAttempt,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header with project/parent task breadcrumb
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Icon(
                        _task.isSubtask
                            ? Icons.subdirectory_arrow_right
                            : Icons.tag,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _task.isSubtask && parentTaskAsync != null
                            ? parentTaskAsync.when(
                                data: (parentTask) => Text(
                                  parentTask?.title ?? 'Parent Task',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                loading: () => const SizedBox(),
                                error: (_, __) => const Text('Parent Task'),
                              )
                            : projectAsync.when(
                                data: (project) => Text(
                                  project?.name ?? 'Project',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                loading: () => const SizedBox(),
                                error: (_, __) => const Text('Project'),
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: _showMoreMenu,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Task title with checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Haptic feedback for satisfaction
                              if (_task.isCompleted) {
                                HapticFeedback.selectionClick();
                              } else {
                                HapticFeedback.mediumImpact();
                              }

                              // Mark pending completion before completing for optimistic UI
                              if (!_task.isCompleted) {
                                ref
                                    .read(tasksNotifierProvider.notifier)
                                    .markPendingCompletion(_task.id);
                              }
                              ref.toggleCompleteWithUndo(
                                context,
                                _task.id,
                                _task.title,
                                _task.isCompleted,
                              );
                              setState(() {
                                _task = _task.copyWith(
                                  isCompleted: !_task.isCompleted,
                                );
                              });
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _task.isCompleted
                                      ? Colors.grey
                                      : (_task.priority > 0
                                          ? priorityColor
                                          : Colors.grey.shade400),
                                  width: 2,
                                ),
                                color: _task.isCompleted
                                    ? Colors.grey.shade300
                                    : null,
                              ),
                              child: _task.isCompleted
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _isEditing
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _titleController,
                                        autofocus: true,
                                        style: theme.textTheme.titleMedium,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) =>
                                            _saveAndStopEditing(),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      TextField(
                                        controller: _descriptionController,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Description',
                                          hintStyle: TextStyle(
                                            color: theme
                                                .colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.only(top: 4),
                                        ),
                                        maxLines: null,
                                        minLines: 1,
                                        onTapOutside: (_) =>
                                            _saveAndStopEditing(),
                                      ),
                                    ],
                                  )
                                : GestureDetector(
                                    onTap: _startEditing,
                                    behavior: HitTestBehavior.opaque,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _task.title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            decoration: _task.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: _task.isCompleted
                                                ? Colors.grey
                                                : null,
                                          ),
                                        ),
                                        if (_task.description != null &&
                                            _task.description!.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              _task.description!,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Due date row
                      _DetailRow(
                        icon: Icons.calendar_today,
                        iconColor: _task.dueDate != null
                            ? theme.colorScheme.primary
                            : Colors.grey,
                        label: _task.dueDate != null
                            ? (_task.dueTime != null
                                ? '${_formatDueDate(_task.dueDate!, l10n)} ${_formatTime(_task.dueTime!)}'
                                : _formatDueDate(_task.dueDate!, l10n))
                            : l10n.addDueDate,
                        trailing: _task.isRecurring
                            ? Icon(
                                Icons.repeat,
                                size: 18,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: _openDatePicker,
                      ),

                      const SizedBox(height: 8),

                      // Priority row
                      _DetailRow(
                        icon: Icons.flag,
                        iconColor:
                            _task.priority > 0 ? priorityColor : Colors.grey,
                        label: _task.priority > 0
                            ? l10n.priorityN(_task.priority)
                            : l10n.addPriority,
                        onTap: _showPriorityPicker,
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Subtasks header
                      Row(
                        children: [
                          Text(
                            l10n.subtasks,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.subtasksCount(completedCount, subtasks.length),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Subtask list
                      if (subtasks.isNotEmpty)
                        SubtaskList(
                          parentId: _task.id,
                          projectId: _task.projectId,
                        ),

                      // Add subtask button
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _openAddSubtaskSheet,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.addASubtask,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Comments section
                      _CommentsSection(taskId: _task.id),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _PriorityOption extends StatelessWidget {
  final int priority;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityOption({
    required this.priority,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = TaskPriority.getColor(priority);

    return ListTile(
      leading: Icon(Icons.flag, color: color),
      title: Text(label),
      trailing:
          isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: onTap,
    );
  }
}

class _CommentsSection extends ConsumerWidget {
  final String taskId;

  const _CommentsSection({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(commentsStreamProvider(taskId));
    final commentCount = commentsAsync.valueOrNull?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments header
        Row(
          children: [
            Text(
              'Comments',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$commentCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Comment list
        CommentList(taskId: taskId),

        const SizedBox(height: 8),

        // Add comment field
        AddCommentField(taskId: taskId),
      ],
    );
  }
}
