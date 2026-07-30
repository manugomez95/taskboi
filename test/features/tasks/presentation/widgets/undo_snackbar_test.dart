import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskboi/core/database/database.dart';
import 'package:taskboi/core/sync/sync_service.dart';
import 'package:taskboi/features/tasks/presentation/widgets/undo_snackbar.dart';
import 'package:taskboi/features/tasks/providers/tasks_provider.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockSyncService extends Mock implements SyncService {}

class _MockRef extends Mock implements Ref {}

class _ControlledTasksNotifier extends TasksNotifier {
  _ControlledTasksNotifier()
      : super(_MockAppDatabase(), _MockSyncService(), null, _MockRef());

  final completion = Completer<void>();
  var completeTaskCallCount = 0;
  var uncompleteTaskCallCount = 0;
  var pendingCompletion = false;

  @override
  void markPendingCompletion(String taskId) {
    pendingCompletion = true;
  }

  @override
  void clearPendingCompletion(String taskId) {
    pendingCompletion = false;
  }

  @override
  Future<void> completeTask(String id) {
    completeTaskCallCount++;
    return completion.future;
  }

  @override
  Future<void> uncompleteTask(String id) async {
    uncompleteTaskCallCount++;
  }
}

void main() {
  const taskTitle = 'Write regression test';

  testWidgets(
    'shows completion snackbar with captured messenger after context unmounts',
    (tester) async {
      final notifier = _ControlledTasksNotifier();
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      late StateSetter setState;
      var showInitiator = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            scaffoldMessengerKey: messengerKey,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, updateState) {
                  setState = updateState;
                  return showInitiator
                      ? Consumer(
                          builder: (context, ref, child) {
                            return TextButton(
                              onPressed: () {
                                unawaited(
                                  ref.completeTaskWithUndo(
                                    context,
                                    'task-id',
                                    taskTitle,
                                    messenger: messengerKey.currentState!,
                                  ),
                                );
                              },
                              child: const Text('Complete'),
                            );
                          },
                        )
                      : const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Complete'));
      setState(() => showInitiator = false);
      await tester.pump();

      notifier.completion.complete();
      await tester.pump();

      expect(find.text('"$taskTitle" completed'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(notifier.uncompleteTaskCallCount, 1);
      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  testWidgets('shows completion snackbar while context remains mounted',
      (tester) async {
    final notifier = _ControlledTasksNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: _MountedCompletionButton.new,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Complete'));
    notifier.completion.complete();
    await tester.pump();

    expect(find.text('"$taskTitle" completed'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets(
    'immediate undo wins when completion is still in flight',
    (tester) async {
      final notifier = _ControlledTasksNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: _MountedCompletionButton.new,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Complete'));
      await tester.pump();

      expect(notifier.completeTaskCallCount, 1);
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(notifier.pendingCompletion, isFalse);
      expect(notifier.uncompleteTaskCallCount, 0);

      notifier.completion.complete();
      await tester.pump();

      expect(notifier.uncompleteTaskCallCount, 1);
      expect(notifier.pendingCompletion, isFalse);
      await tester.pump(const Duration(milliseconds: 500));
    },
  );
}

class _MountedCompletionButton extends StatelessWidget {
  const _MountedCompletionButton(
    this.context,
    this.ref,
    this.child,
  );

  final BuildContext context;
  final WidgetRef ref;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        unawaited(
          ref.completeTaskWithUndo(
            context,
            'task-id',
            'Write regression test',
          ),
        );
      },
      child: const Text('Complete'),
    );
  }
}
