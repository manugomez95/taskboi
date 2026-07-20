import 'package:flutter/material.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../projects/providers/projects_provider.dart';
import '../../data/models/task.dart';
import '../../providers/tasks_provider.dart';
import 'advanced_date_picker.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  final String projectId;
  final String? parentId;
  final DateTime? initialDueDate;

  const QuickAddTaskSheet({
    super.key,
    required this.projectId,
    this.parentId,
    this.initialDueDate,
  });

  @override
  ConsumerState<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<QuickAddTaskSheet>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  late String _selectedProjectId;
  DateTime? _dueDate;
  String? _dueTime;
  int _priority = 0;
  String? _recurrenceRule;
  bool _hasKeyboardAppeared = false;

  bool get _isSubtask => widget.parentId != null;
  bool get _canSubmit => _titleController.text.trim().isNotEmpty;

  bool get _isDirty {
    return _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _dueDate != widget.initialDueDate ||
        _dueTime != null ||
        _priority != 0 ||
        _recurrenceRule != null ||
        _selectedProjectId != widget.projectId;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedProjectId = widget.projectId;
    _dueDate = widget.initialDueDate;
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void didChangeMetrics() {
    // Check keyboard visibility immediately from platform dispatcher
    // (MediaQuery.of(context) may not be updated yet in post frame callback)
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final keyboardHeight = view.viewInsets.bottom / view.devicePixelRatio;
    final keyboardVisible = keyboardHeight > 0;

    // Once keyboard has appeared, watch for it to disappear
    if (keyboardVisible) {
      _hasKeyboardAppeared = true;
    } else if (_hasKeyboardAppeared) {
      // Keyboard was hidden - close the sheet
      _hasKeyboardAppeared = false; // Reset to prevent multiple calls
      // Defer navigation to after the frame (requires mounted context)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Double-check that this sheet is still the current route
        // (e.g., date picker might have opened in the meantime)
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.of(context).maybePop();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;

    final notifier = ref.read(tasksNotifierProvider.notifier);

    await notifier.createTask(
      projectId: _selectedProjectId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      dueDate: _dueDate,
      dueTime: _dueTime,
      priority: _priority,
      recurrenceRule: _recurrenceRule,
      parentId: widget.parentId,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openDatePicker() async {
    final result = await showAdvancedDatePicker(
      context: context,
      initialDate: _dueDate,
      initialTime: _dueTime,
      initialRecurrence: _recurrenceRule,
    );

    if (result != null) {
      setState(() {
        _dueDate = result.dueDate;
        _dueTime = result.dueTime;
        _recurrenceRule = result.recurrenceRule;
      });
    }
  }

  void _showPriorityPicker() {
    final l10n = AppLocalizations.of(context)!;
    final priorityLabels = [
      l10n.priorityUrgent,
      l10n.priorityHigh,
      l10n.priorityMedium,
      l10n.priorityLow,
      l10n.priorityNone,
    ];
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            ...List.generate(5, (index) {
              final priority = 4 - index;
              return ListTile(
                leading: Icon(
                  Icons.flag,
                  color: TaskPriority.getColor(priority),
                ),
                title: Text(priorityLabels[index]),
                trailing: _priority == priority
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _priority = priority;
                  });
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showProjectPicker() {
    final l10n = AppLocalizations.of(context)!;
    final projectsAsync = ref.read(projectsStreamProvider);
    final projects = projectsAsync.valueOrNull ?? [];

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
                  l10n.project,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
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
                      trailing: _selectedProjectId == project.id
                          ? Icon(Icons.check,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedProjectId = project.id;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateChip(AppLocalizations l10n) {
    if (_dueDate == null && _recurrenceRule == null) return l10n.date;

    final parts = <String>[];
    if (_dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final dateOnly = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day);

      if (dateOnly == today) {
        parts.add(l10n.today);
      } else if (dateOnly == tomorrow) {
        parts.add(l10n.tomorrow);
      } else {
        parts.add(DateFormat('MMM d').format(_dueDate!));
      }

      if (_dueTime != null) {
        parts.add(_formatTime(_dueTime!));
      }
    }

    if (_recurrenceRule != null) {
      parts.add(RecurrenceRule.describe(_recurrenceRule));
    }

    return parts.join(' • ');
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final projectsAsync = ref.watch(projectsStreamProvider);
    final currentProject = projectsAsync.valueOrNull
        ?.where((p) => p.id == _selectedProjectId)
        .firstOrNull;
    final priorityColor = TaskPriority.getColor(_priority);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _handlePopAttempt,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: _isSubtask ? 'Subtask name' : 'Task name',
                    hintStyle:
                        TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ),

              // Description field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),

              const SizedBox(height: 12),

              // Chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Date chip
                    _QuickChip(
                      icon: _recurrenceRule != null
                          ? Icons.repeat
                          : Icons.calendar_today,
                      label: _formatDateChip(l10n),
                      isActive: _dueDate != null || _recurrenceRule != null,
                      onTap: _openDatePicker,
                    ),
                    const SizedBox(width: 8),
                    // Priority chip
                    _QuickChip(
                      icon: Icons.flag,
                      iconColor: _priority > 0 ? priorityColor : null,
                      label: _priority > 0 ? 'P$_priority' : l10n.priority,
                      isActive: _priority > 0,
                      onTap: _showPriorityPicker,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Bottom row: Project selector + Submit button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    // Project selector (only for top-level tasks)
                    if (!_isSubtask)
                      InkWell(
                        onTap: _showProjectPicker,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#',
                                style: TextStyle(
                                  color: currentProject != null
                                      ? _parseColor(currentProject.color)
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currentProject?.name ?? l10n.inbox,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Submit button
                    Material(
                      color: _canSubmit
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _canSubmit ? _handleSubmit : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_upward,
                            size: 20,
                            color: _canSubmit
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.38),
                          ),
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
    );
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: isActive
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor ?? color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w500 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show the quick add task sheet
Future<void> showQuickAddTaskSheet(
  BuildContext context, {
  required String projectId,
  String? parentId,
  DateTime? initialDueDate,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QuickAddTaskSheet(
      projectId: projectId,
      parentId: parentId,
      initialDueDate: initialDueDate,
    ),
  );
}
