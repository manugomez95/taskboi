import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/features/tasks/data/models/task.dart';
import 'package:taskboi/features/tasks/providers/tasks_provider.dart';

void main() {
  test('applySorting preserves engine due-date and time ordering', () {
    final date = DateTime(2026, 8, 2);
    Task task(String id, {DateTime? dueDate, String? dueTime}) => Task(
          id: id,
          projectId: 'project-id',
          userId: 'user-id',
          title: id,
          dueDate: dueDate,
          dueTime: dueTime,
        );
    final tasks = [
      task('untimed', dueDate: date),
      task('no-date', dueTime: '08:00'),
      task('later', dueDate: date, dueTime: '15:30'),
      task('earlier', dueDate: date, dueTime: '09:00'),
    ];

    expect(
      applySorting(tasks, TaskSortOption.dueDate).map((task) => task.id),
      ['earlier', 'later', 'untimed', 'no-date'],
    );
    expect(tasks.map((task) => task.id),
        ['untimed', 'no-date', 'later', 'earlier']);
  });

  test('applySorting preserves caller objects, duplicate IDs, and stable ties',
      () {
    Task task(String title) => Task(
          id: 'same-id',
          projectId: 'project-id',
          userId: 'user-id',
          title: title,
        );
    final first = task('same');
    final second = task('same');

    final result = applySorting([first, second], TaskSortOption.title);

    expect(result[0], same(first));
    expect(result[1], same(second));
  });

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
