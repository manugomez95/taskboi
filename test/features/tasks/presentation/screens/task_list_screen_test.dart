import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/features/auth/providers/auth_provider.dart';
import 'package:taskboi/features/tasks/data/models/task.dart';
import 'package:taskboi/features/tasks/presentation/screens/task_list_screen.dart';
import 'package:taskboi/features/tasks/providers/tasks_provider.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';

void main() {
  test('dedupes a source task against its exiting snapshot', () {
    const sourceTask = Task(
      id: 'task-id',
      projectId: 'project-id',
      userId: 'user-id',
      title: 'Source task',
    );
    const exitingSnapshot = Task(
      id: 'task-id',
      projectId: 'project-id',
      userId: 'user-id',
      title: 'Exiting snapshot',
    );

    final renderedTasks = mergeExitingTaskSnapshots(
      [sourceTask],
      [exitingSnapshot],
    );

    expect(renderedTasks, [exitingSnapshot]);
  });

  testWidgets('empty inbox keeps the keyed task viewport in place',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSyncCompleteProvider.overrideWithValue(true),
          inboxTasksProvider.overrideWithValue(const AsyncValue.data([])),
          taskSortNotifierProvider.overrideWith(
            (ref, viewKey) =>
                TaskSortNotifier(ref, viewKey, TaskSortOption.manual),
          ),
          showCompletedProvider.overrideWith((ref, viewKey) => false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TaskListScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('task-list-inbox')),
      findsOneWidget,
    );
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverFillRemaining), findsOneWidget);
  });
}
