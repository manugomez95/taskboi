import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/task.dart';
import '../../providers/tasks_provider.dart';
import 'task_detail_sheet.dart';
import 'undo_snackbar.dart';

class SubtaskList extends ConsumerStatefulWidget {
  final String parentId;
  final String projectId;

  const SubtaskList({
    super.key,
    required this.parentId,
    required this.projectId,
  });

  @override
  ConsumerState<SubtaskList> createState() => _SubtaskListState();
}

class _SubtaskListState extends ConsumerState<SubtaskList> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final subtasksAsync = ref.watch(subtasksStreamProvider(widget.parentId));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return subtasksAsync.when(
      data: (subtasks) {
        if (subtasks.isEmpty) {
          return const SizedBox.shrink();
        }

        final incompleteSubtasks =
            subtasks.where((t) => !t.isCompleted).toList();
        final completedSubtasks = subtasks.where((t) => t.isCompleted).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...incompleteSubtasks.map((subtask) => SubtaskTile(
                  key: ValueKey(subtask.id),
                  subtask: subtask,
                  projectId: widget.projectId,
                )),
            if (completedSubtasks.isNotEmpty)
              InkWell(
                onTap: () => setState(() => _showCompleted = !_showCompleted),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showCompleted ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showCompleted
                            ? l10n.hideCompleted
                            : l10n.completedCount(completedSubtasks.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showCompleted)
              ...completedSubtasks.map((subtask) => SubtaskTile(
                    key: ValueKey(subtask.id),
                    subtask: subtask,
                    projectId: widget.projectId,
                  )),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class SubtaskTile extends ConsumerStatefulWidget {
  final Task subtask;
  final String projectId;

  const SubtaskTile({
    super.key,
    required this.subtask,
    required this.projectId,
  });

  @override
  ConsumerState<SubtaskTile> createState() => _SubtaskTileState();
}

class _SubtaskTileState extends ConsumerState<SubtaskTile>
    with SingleTickerProviderStateMixin {
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

    // Capture values before animation — widget may be disposed during fade
    final taskId = widget.subtask.id;
    final taskTitle = widget.subtask.title;
    final wasCompleted = widget.subtask.isCompleted;
    final messenger = ScaffoldMessenger.of(context);

    // Animation FIRST, then pending state (see CLAUDE.md: Animation + Pending State Bug)
    await _fadeController.forward();

    if (!mounted) return;

    // Now safe to mark pending and complete
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
      widget.subtask.id,
      widget.subtask.title,
      widget.subtask.isCompleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtask = widget.subtask;
    final priorityColor = TaskPriority.getColor(subtask.priority);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizeTransition(
        sizeFactor: _fadeAnimation,
        alignment: Alignment.topCenter,
        child: Dismissible(
          key: Key(subtask.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white, size: 18),
          ),
          onDismissed: (_) {
            // Hides the subtask immediately and defers the actual deletion
            // until the undo window elapses.
            UndoSnackBarService.showTaskDeleted(
              context,
              ref,
              taskId: subtask.id,
              message: '"${subtask.title}" deleted',
            );
          },
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => TaskDetailSheet(task: subtask),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (subtask.isCompleted) {
                        _handleUncomplete();
                      } else {
                        _handleComplete();
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: subtask.isCompleted
                              ? Colors.grey
                              : (subtask.priority > 0
                                  ? priorityColor
                                  : Colors.grey.shade400),
                          width: 2,
                        ),
                        color:
                            subtask.isCompleted ? Colors.grey.shade300 : null,
                      ),
                      child: subtask.isCompleted
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtask.title,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: subtask.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: subtask.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        if (subtask.description != null &&
                            subtask.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtask.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtask.isCompleted
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                decoration: subtask.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
