import 'package:flutter/material.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sync/sync_lifecycle_observer.dart';
import '../../../../core/widgets/android_app_banner.dart';
import '../../../../core/widgets/delayed_reorderable_listener.dart';
import '../../../../core/widgets/sync_status_indicator.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/project.dart';
import '../../providers/projects_provider.dart';
import '../widgets/project_form.dart';
import '../widgets/project_tile.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isWide = MediaQuery.of(context).size.width >= 800;
    final l10n = AppLocalizations.of(context)!;

    // Trigger initial sync when app loads (if user is logged in)
    ref.watch(initialSyncProvider);

    final drawer = _buildDrawer(context, ref, projectsAsync, currentUser, l10n);

    return SyncLifecycleObserver(
        child: Scaffold(
      appBar: isWide
          ? null
          : AppBar(
              title: Text(l10n.appName),
            ),
      drawer: isWide ? null : drawer,
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: 280,
              child: drawer,
            ),
          if (isWide) const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const AndroidAppBanner(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> projectsAsync,
    dynamic currentUser,
    AppLocalizations l10n,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (currentUser?.email?.substring(0, 1) ?? '?')
                          .toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.userMetadata?['full_name'] ?? l10n.user,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentUser?.email ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.inbox),
              title: Text(l10n.inbox),
              selected: GoRouterState.of(context).matchedLocation == '/',
              onTap: () {
                context.go('/');
                if (MediaQuery.of(context).size.width < 800) {
                  Navigator.of(context).pop();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: Text(l10n.today),
              selected: GoRouterState.of(context).matchedLocation == '/today',
              onTap: () {
                context.go('/today');
                if (MediaQuery.of(context).size.width < 800) {
                  Navigator.of(context).pop();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(l10n.upcoming),
              selected:
                  GoRouterState.of(context).matchedLocation == '/upcoming',
              onTap: () {
                context.go('/upcoming');
                if (MediaQuery.of(context).size.width < 800) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.projects,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _showCreateProjectDialog(context, ref),
                    tooltip: l10n.createProject,
                  ),
                ],
              ),
            ),
            Expanded(
              child: projectsAsync.when(
                data: (projects) {
                  final nonInboxProjects = projects
                      .where((p) => !p.isInbox)
                      .toList()
                      .cast<Project>();
                  if (nonInboxProjects.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noProjectsYet,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ReorderableListView.builder(
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    itemCount: nonInboxProjects.length,
                    onReorderItem: (oldIndex, newIndex) {
                      final reorderedProjects = List.of(nonInboxProjects);
                      final movedProject = reorderedProjects.removeAt(oldIndex);
                      reorderedProjects.insert(newIndex, movedProject);
                      ref
                          .read(projectsNotifierProvider.notifier)
                          .reorderProjects(reorderedProjects);
                    },
                    itemBuilder: (context, index) {
                      final project = nonInboxProjects[index];
                      return DelayedReorderableListener(
                        key: ValueKey(project.id),
                        index: index,
                        child: ProjectTile(
                          project: project,
                          selected: GoRouterState.of(context).matchedLocation ==
                              '/project/${project.id}',
                          onTap: () {
                            context.go('/project/${project.id}');
                            if (MediaQuery.of(context).size.width < 800) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(l10n.error(error.toString())),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.settings),
              selected: GoRouterState.of(context)
                  .matchedLocation
                  .startsWith('/settings'),
              onTap: () {
                context.go('/settings');
                if (MediaQuery.of(context).size.width < 800) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SyncStatusIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ProjectFormDialog(),
    );
  }
}
