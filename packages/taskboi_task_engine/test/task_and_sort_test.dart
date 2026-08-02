import 'package:taskboi_task_engine/taskboi_task_engine.dart';
import 'package:test/test.dart';

void main() {
  Task task({
    required String id,
    String title = 'Task',
    DateTime? dueDate,
    String? dueTime,
    int priority = 0,
    int sortOrder = 0,
    DateTime? createdAt,
  }) =>
      Task(
        id: id,
        projectId: 'project',
        userId: 'user',
        title: title,
        dueDate: dueDate,
        dueTime: dueTime,
        priority: priority,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );

  test('Task is immutable, value-equal, and exposes domain flags', () {
    final dueDate = DateTime(2026, 8, 2);
    final first = Task(
      id: '1',
      projectId: 'p',
      userId: 'u',
      parentId: 'parent',
      title: 'Pay rent',
      dueDate: dueDate,
      recurrenceRule: 'FREQ=MONTHLY',
    );
    final same = Task(
      id: '1',
      projectId: 'p',
      userId: 'u',
      parentId: 'parent',
      title: 'Pay rent',
      dueDate: dueDate,
      recurrenceRule: 'FREQ=MONTHLY',
    );

    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first.isRecurring, isTrue);
    expect(first.isSubtask, isTrue);
    expect(first.isCompleted, isFalse);
  });

  test('sortTasks supports every option without mutating input', () {
    final original = [
      task(
          id: 'a',
          title: 'Zulu',
          priority: 1,
          sortOrder: 2,
          createdAt: DateTime(2026, 1, 1)),
      task(
          id: 'b',
          title: 'alpha',
          priority: 4,
          sortOrder: 1,
          createdAt: DateTime(2026, 2, 1)),
    ];

    expect(sortTasks(original, TaskSortOption.manual).map((t) => t.id),
        ['b', 'a']);
    expect(sortTasks(original, TaskSortOption.priority).map((t) => t.id),
        ['b', 'a']);
    expect(
        sortTasks(original, TaskSortOption.title).map((t) => t.id), ['b', 'a']);
    expect(sortTasks(original, TaskSortOption.createdAt).map((t) => t.id),
        ['b', 'a']);
    expect(original.map((t) => t.id), ['a', 'b']);
  });

  test('due-date sorting uses date then time, nulls last, and stable ties', () {
    final date = DateTime(2026, 8, 2);
    final tasks = [
      task(id: 'untimed-1', dueDate: date),
      task(id: 'later', dueDate: date, dueTime: '15:30'),
      task(id: 'none'),
      task(id: 'earlier-1', dueDate: date, dueTime: '09:00'),
      task(id: 'earlier-2', dueDate: date, dueTime: '09:00'),
      task(id: 'untimed-2', dueDate: date),
      task(id: 'tomorrow', dueDate: DateTime(2026, 8, 3)),
    ];

    expect(
      sortTasks(tasks, TaskSortOption.dueDate).map((t) => t.id),
      [
        'earlier-1',
        'earlier-2',
        'later',
        'untimed-1',
        'untimed-2',
        'tomorrow',
        'none'
      ],
    );
  });

  test('created-at sorting uses newest first, nulls last, and stable ties', () {
    final tasks = [
      task(id: 'missing-1'),
      task(id: 'older', createdAt: DateTime(2026, 1, 1)),
      task(id: 'missing-2'),
      task(id: 'newer', createdAt: DateTime(2026, 2, 1)),
    ];

    expect(
      sortTasks(tasks, TaskSortOption.createdAt).map((task) => task.id),
      ['newer', 'older', 'missing-1', 'missing-2'],
    );
  });

  test('all sort options preserve input order when keys tie', () {
    final tied = [task(id: 'first'), task(id: 'second'), task(id: 'third')];
    for (final option in TaskSortOption.values) {
      expect(sortTasks(tied, option).map((t) => t.id),
          ['first', 'second', 'third']);
    }
  });
}
