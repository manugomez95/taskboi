import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../projects/providers/projects_provider.dart';
import '../../data/models/task.dart';
import '../../providers/tasks_provider.dart';
import 'advanced_date_picker.dart';
import 'undo_snackbar.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  final String projectId;
  final Task? task;
  final String? parentId;

  const TaskFormSheet({
    super.key,
    required this.projectId,
    this.task,
    this.parentId,
  });

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedProjectId;
  late String _initialTitle;
  late String _initialDescription;
  late String _initialProjectId;
  DateTime? _dueDate;
  DateTime? _initialDueDate;
  String? _dueTime;
  String? _initialDueTime;
  int _priority = 0;
  int _initialPriority = 0;
  String? _recurrenceRule;
  String? _initialRecurrenceRule;
  String _assignedTo = 'manuel';
  String _initialAssignedTo = 'manuel';

  @override
  void initState() {
    super.initState();
    _initialTitle = widget.task?.title ?? '';
    _initialDescription = widget.task?.description ?? '';
    _initialProjectId = widget.task?.projectId ?? widget.projectId;
    _initialDueDate = widget.task?.dueDate;
    _initialDueTime = widget.task?.dueTime;
    _initialPriority = widget.task?.priority ?? 0;
    _initialRecurrenceRule = widget.task?.recurrenceRule;
    _initialAssignedTo = widget.task?.assignedTo ?? 'manuel';

    _titleController = TextEditingController(text: _initialTitle);
    _descriptionController = TextEditingController(text: _initialDescription);
    _selectedProjectId = _initialProjectId;
    _dueDate = _initialDueDate;
    _dueTime = _initialDueTime;
    _priority = _initialPriority;
    _recurrenceRule = _initialRecurrenceRule;
    _assignedTo = _initialAssignedTo;

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

  bool get _isDirty {
    return _titleController.text != _initialTitle ||
        _descriptionController.text != _initialDescription ||
        _selectedProjectId != _initialProjectId ||
        _dueDate != _initialDueDate ||
        _dueTime != _initialDueTime ||
        _priority != _initialPriority ||
        _recurrenceRule != _initialRecurrenceRule ||
        _assignedTo != _initialAssignedTo;
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(tasksNotifierProvider.notifier);
    final previousProjectId = widget.task?.projectId;
    final projectWasChanged = widget.task != null &&
        previousProjectId != null &&
        previousProjectId != _selectedProjectId;

    if (widget.task != null) {
      await notifier.updateTask(
        id: widget.task!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        updateDescription: true,
        projectId: _selectedProjectId,
        dueDate: _dueDate,
        updateDueDate: true,
        dueTime: _dueTime,
        updateDueTime: true,
        priority: _priority,
        recurrenceRule: _recurrenceRule,
        updateRecurrenceRule: true,
        assignedTo: _assignedTo,
      );
    } else {
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
        assignedTo: _assignedTo,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();

      // Show undo snackbar if project was changed
      if (projectWasChanged && context.mounted) {
        final projectsAsync = ref.read(projectsStreamProvider);
        final newProjectName = projectsAsync.valueOrNull
                ?.firstWhere((p) => p.id == _selectedProjectId,
                    orElse: () => throw Exception())
                .name ??
            'project';

        UndoSnackBarService.showTaskMoved(
          context,
          ref,
          taskTitle: widget.task!.title,
          projectName: newProjectName,
          onUndo: () async {
            await notifier.updateTask(
              id: widget.task!.id,
              projectId: previousProjectId,
            );
            // Invalidate providers to refresh
            ref.invalidate(tasksStreamProvider(previousProjectId));
            ref.invalidate(tasksStreamProvider(_selectedProjectId));
            ref.invalidate(todayTasksProvider);
            ref.invalidate(upcomingTasksProvider);
            ref.invalidate(inboxTasksProvider);
          },
        );
      }
    }
  }

  Future<void> _showAdvancedDatePicker() async {
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

  String _getDateChipLabel(AppLocalizations l10n) {
    final parts = <String>[];

    if (_dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final dueDateOnly =
          DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day);

      if (dueDateOnly == today) {
        parts.add(l10n.today);
      } else if (dueDateOnly == tomorrow) {
        parts.add(l10n.tomorrow);
      } else {
        parts.add(DateFormat('MMM d').format(_dueDate!));
      }

      if (_dueTime != null) {
        parts.add(_formatTimeLabel(_dueTime!));
      }
    }

    if (_recurrenceRule != null) {
      parts.add(RecurrenceRule.describeWithL10n(_recurrenceRule, l10n));
    }

    if (parts.isEmpty) {
      return l10n.dueDate;
    }

    return parts.join(' \u2022 '); // Bullet separator
  }

  String _formatTimeLabel(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            ...List.generate(5, (index) {
              final priority = 4 - index; // 4, 3, 2, 1, 0
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TaskPriority.getColor(priority),
                      width: 2,
                    ),
                  ),
                ),
                title: Text(TaskPriority.getLabelWithL10n(priority, l10n)),
                trailing: _priority == priority
                    ? const Icon(Icons.check, color: Colors.green)
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

  String _getAssigneeEmoji(String assignee) {
    switch (assignee) {
      case 'hermes':
        return '\u{1F916}'; // 🤖
      case 'claude':
        return '\u{1F9E0}'; // 🧠
      default:
        return '\u{1F464}'; // 👤
    }
  }

  void _showAssigneePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Assign to',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            ListTile(
              leading: const Text('\u{1F464}', style: TextStyle(fontSize: 24)),
              title: const Text('manuel'),
              trailing: _assignedTo == 'manuel'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _assignedTo = 'manuel';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Text('\u{1F916}', style: TextStyle(fontSize: 24)),
              title: const Text('hermes'),
              trailing: _assignedTo == 'hermes'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _assignedTo = 'hermes';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Text('\u{1F9E0}', style: TextStyle(fontSize: 24)),
              title: const Text('claude'),
              trailing: _assignedTo == 'claude'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _assignedTo = 'claude';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final isEditing = widget.task != null;
    final isSubtask = widget.parentId != null || widget.task?.parentId != null;
    final priorityColor = TaskPriority.getColor(_priority);
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _handlePopAttempt,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(l10n.cancel),
                    ),
                    Text(
                      isEditing
                          ? (isSubtask ? l10n.editSubtask : l10n.editTask)
                          : (isSubtask ? l10n.newSubtask : l10n.newTask),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: _handleSubmit,
                      child: Text(isEditing ? l10n.save : l10n.add),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSubmit(),
                  decoration: InputDecoration(
                    hintText: isSubtask ? l10n.subtaskName : l10n.taskName,
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 18),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.pleaseEnterTaskName;
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: l10n.description,
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: Icon(
                        _recurrenceRule != null
                            ? Icons.repeat
                            : Icons.calendar_today,
                        size: 18,
                        color: (_dueDate != null || _recurrenceRule != null)
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      label: Text(_getDateChipLabel(l10n)),
                      onPressed: _showAdvancedDatePicker,
                    ),
                    ActionChip(
                      avatar: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _priority > 0 ? priorityColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                      ),
                      label: Text(
                        _priority > 0
                            ? TaskPriority.getLabelWithL10n(_priority, l10n)
                            : l10n.priority,
                      ),
                      onPressed: _showPriorityPicker,
                    ),
                    ActionChip(
                      avatar: Text(
                        _getAssigneeEmoji(_assignedTo),
                        style: const TextStyle(fontSize: 16),
                      ),
                      label: Text(_assignedTo == 'manuel'
                          ? 'Asignado a: manuel'
                          : _assignedTo),
                      onPressed: _showAssigneePicker,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: projectsAsync.when(
                  data: (projects) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedProjectId,
                      decoration: InputDecoration(
                        labelText: l10n.project,
                        prefixIcon: const Icon(Icons.folder_outlined),
                      ),
                      items: projects.map((project) {
                        return DropdownMenuItem(
                          value: project.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _parseColor(project.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(project.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          // Update assignee based on project's default_assignee
                          final project =
                              projects.where((p) => p.id == value).firstOrNull;
                          final projectDefaultAssignee =
                              project?.defaultAssignee;
                          setState(() {
                            _selectedProjectId = value;
                            // Only auto-set assignee if user hasn't manually changed it
                            // OR if this is a new task (not editing)
                            if (widget.task == null &&
                                projectDefaultAssignee != null) {
                              _assignedTo = projectDefaultAssignee;
                            }
                          });
                        }
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(l10n.errorLoadingProjects),
                ),
              ),
              const SizedBox(height: 16),
              if (isEditing) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: () {
                      final deletedTask = widget.task!;

                      // Capture scaffold messenger before popping
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      // Close form immediately
                      Navigator.of(context).pop();

                      // Show undo snackbar - defer actual deletion until the
                      // undo window elapses (handled by the service).
                      UndoSnackBarService.showTaskDeleted(
                        context,
                        ref,
                        taskId: deletedTask.id,
                        message: l10n.taskDeleted(deletedTask.title),
                        actionLabel: l10n.undo,
                        messenger: scaffoldMessenger,
                      );
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      isSubtask ? l10n.deleteSubtask : l10n.deleteTask,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
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
