import 'package:taskboi_task_engine/taskboi_task_engine.dart';
import 'package:test/test.dart';

void main() {
  test('recurringOccurrenceId supplies stable date-only deterministic material',
      () {
    String? receivedMaterial;
    final id = recurringOccurrenceId(
      recurrenceParentId: 'series:with:punctuation',
      occurrenceDate: DateTime(2026, 2, 3, 23, 59),
      generateId: (material) {
        receivedMaterial = material;
        return 'generated-id';
      },
    );

    expect(id, 'generated-id');
    expect(
      receivedMaterial,
      'taskboi:recurring-occurrence:v1:series:with:punctuation:2026-02-03',
    );
  });

  test('material is unchanged for another time on the same local date', () {
    String material(DateTime date) => recurringOccurrenceId(
          recurrenceParentId: 'series',
          occurrenceDate: date,
          generateId: (value) => value,
        );

    expect(material(DateTime(2026, 12, 9)),
        material(DateTime(2026, 12, 9, 18, 30)));
  });
}
