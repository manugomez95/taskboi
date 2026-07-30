import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/features/projects/providers/projects_provider.dart';
import 'package:taskboi/features/tasks/data/models/task.dart';
import 'package:taskboi/features/tasks/presentation/widgets/task_tile.dart';
import 'package:taskboi/features/tasks/providers/tasks_provider.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('delegates incomplete checkbox completion to its list owner',
      (tester) async {
    const task = Task(
      id: 'task-id',
      projectId: 'project-id',
      userId: 'user-id',
      title: 'Owned transition',
    );
    Task? completedTask;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsStreamProvider.overrideWithValue(const AsyncValue.data([])),
          subtasksStreamProvider.overrideWith(
            (ref, parentId) => const AsyncValue.data([]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TaskTile(
              task: task,
              onToggleComplete: (value) => completedTask = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector).last);
    await tester.pump();

    expect(completedTask, task);
    expect(
      find.descendant(
        of: find.byType(TaskTile),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(TaskTile),
        matching: find.byType(SizeTransition),
      ),
      findsNothing,
    );
  });
}
