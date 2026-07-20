import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/project.dart';
import '../../providers/projects_provider.dart';

class ProjectFormDialog extends ConsumerStatefulWidget {
  final Project? project;

  const ProjectFormDialog({super.key, this.project});

  @override
  ConsumerState<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends ConsumerState<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _webhookController;
  late String _selectedColor;
  late String _selectedDefaultAssignee;

  static const List<String> _colors = [
    '#6B7280', // Gray
    '#DC4C3E', // Red
    '#F59E0B', // Orange
    '#10B981', // Green
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#6366F1', // Indigo
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _webhookController =
        TextEditingController(text: widget.project?.agentWebhookUrl ?? '');
    _selectedColor = widget.project?.color ?? _colors[0];
    _selectedDefaultAssignee = widget.project?.defaultAssignee ?? 'manuel';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _webhookController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  Widget _buildAssigneeSelector() {
    return Row(
      children: [
        _assigneeOption('manuel', '👤', 'manuel'),
        const SizedBox(width: 8),
        _assigneeOption('hermes', '🤖', 'hermes'),
      ],
    );
  }

  Widget _assigneeOption(String value, String emoji, String label) {
    final isSelected = _selectedDefaultAssignee == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDefaultAssignee = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withAlpha(50),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(projectsNotifierProvider.notifier);

    if (widget.project != null) {
      await notifier.updateProject(
        id: widget.project!.id,
        name: _nameController.text.trim(),
        color: _selectedColor,
        defaultAssignee: _selectedDefaultAssignee,
        agentWebhookUrl: _webhookController.text.trim(),
      );
    } else {
      await notifier.createProject(
        name: _nameController.text.trim(),
        color: _selectedColor,
        defaultAssignee: _selectedDefaultAssignee,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(isEditing ? l10n.editProject : l10n.createProject),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.projectName,
                hintText: l10n.enterProjectName,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterProjectName;
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.color,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _parseColor(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _parseColor(color).withAlpha(128),
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Default assignee',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            _buildAssigneeSelector(),
            if (isEditing) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _webhookController,
                decoration: InputDecoration(
                  labelText: 'Agent Webhook URL (optional)',
                  hintText: 'https://example.com/webhook',
                  prefixIcon: const Icon(Icons.webhook, size: 20),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 4),
              Text(
                'Overrides the global webhook URL for this project',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _handleSubmit,
          child: Text(isEditing ? l10n.save : l10n.create),
        ),
      ],
    );
  }
}
