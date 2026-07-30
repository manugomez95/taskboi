import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/features/tasks/data/models/task.dart';
import 'package:taskboi/features/tasks/providers/tasks_provider.dart';

void main() {
  group('applyOptimisticTaskOverlay', () {
    Task task(String id, {bool isCompleted = false}) => Task(
          id: id,
          projectId: 'project-id',
          userId: 'user-id',
          title: id,
          isCompleted: isCompleted,
        );

    test('removes pending deletions', () {
      final tasks = [task('kept'), task('deleted')];

      final result = applyOptimisticTaskOverlay(
        tasks,
        pendingDeletion: {'deleted'},
        pendingCompletion: const {},
      );

      expect(result.map((task) => task.id), ['kept']);
    });

    test('overlays pending completion without removing the task', () {
      final tasks = [task('pending'), task('already-done', isCompleted: true)];

      final result = applyOptimisticTaskOverlay(
        tasks,
        pendingDeletion: const {},
        pendingCompletion: {'pending'},
      );

      expect(result.map((task) => task.id), ['pending', 'already-done']);
      expect(result, everyElement(isA<Task>()));
      expect(result.first.isCompleted, isTrue);
      expect(result.last.isCompleted, isTrue);
    });
  });
}
