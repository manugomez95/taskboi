import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/project.dart';
import '../../providers/projects_provider.dart';
import 'project_form.dart';

class ProjectTile extends ConsumerWidget {
  final Project project;
  final bool selected;
  final VoidCallback onTap;

  const ProjectTile({
    super.key,
    required this.project,
    this.selected = false,
    required this.onTap,
  });

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(project.color);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        project.name,
        overflow: TextOverflow.ellipsis,
      ),
      selected: selected,
      onTap: onTap,
      trailing: PopupMenuButton(
        icon: const Icon(Icons.more_horiz, size: 20),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, size: 20),
                const SizedBox(width: 8),
                Text(l10n.edit),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            showDialog(
              context: context,
              builder: (context) => ProjectFormDialog(project: project),
            );
          } else if (value == 'delete') {
            _confirmDelete(context, ref, l10n);
          }
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProject),
        content: Text(l10n.deleteProjectConfirmation(project.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(projectsNotifierProvider.notifier)
                  .deleteProject(project.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
