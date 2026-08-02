import 'package:taskboi_task_engine/taskboi_task_engine.dart';
import 'package:test/test.dart';

void main() {
  TaskSortKey key({
    String title = 'Task',
    DateTime? dueDate,
    String? dueTime,
    int priority = 0,
    int sortOrder = 0,
    DateTime? createdAt,
  }) =>
      TaskSortKey(
        title: title,
        dueDate: dueDate,
        dueTime: dueTime,
        priority: priority,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );

  test('compares every supported task ordering', () {
    final first = key(
      title: 'Zulu',
      priority: 1,
      sortOrder: 2,
      createdAt: DateTime(2026, 1, 1),
    );
    final second = key(
      title: 'alpha',
      priority: 4,
      sortOrder: 1,
      createdAt: DateTime(2026, 2, 1),
    );

    for (final option in [
      TaskSortOption.manual,
      TaskSortOption.priority,
      TaskSortOption.title,
      TaskSortOption.createdAt,
    ]) {
      expect(compareTaskSortKeys(first, second, option), greaterThan(0));
    }
  });

  test('due-date comparison uses date then time and puts nulls last', () {
    final date = DateTime(2026, 8, 2);

    expect(
      compareTaskSortKeys(
        key(dueDate: date, dueTime: '09:00'),
        key(dueDate: date, dueTime: '15:30'),
        TaskSortOption.dueDate,
      ),
      lessThan(0),
    );
    expect(
      compareTaskSortKeys(
        key(dueDate: date),
        key(dueDate: date, dueTime: '15:30'),
        TaskSortOption.dueDate,
      ),
      greaterThan(0),
    );
    expect(
      compareTaskSortKeys(key(), key(dueDate: date), TaskSortOption.dueDate),
      greaterThan(0),
    );
  });

  test('equal keys compare equal for caller-controlled stable ordering', () {
    final tied = key();
    for (final option in TaskSortOption.values) {
      expect(compareTaskSortKeys(tied, tied, option), 0);
    }
  });
}
