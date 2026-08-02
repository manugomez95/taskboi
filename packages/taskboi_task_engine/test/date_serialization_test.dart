import 'package:taskboi_task_engine/taskboi_task_engine.dart';
import 'package:test/test.dart';

void main() {
  test('UTC ISO serialization handles null, UTC, and instant boundaries', () {
    expect(utcIso8601(null), isNull);
    expect(
      utcIso8601(DateTime.utc(2026, 1, 2, 3, 4, 5, 6, 7)),
      '2026-01-02T03:04:05.006007Z',
    );
    expect(
      utcIso8601(DateTime.parse('2026-01-01T00:15:00+02:00')),
      '2025-12-31T22:15:00.000Z',
    );
  });

  test('civil ISO serialization preserves fields across UTC boundaries', () {
    expect(civilDateIso8601(null), isNull);
    expect(civilDateIso8601(DateTime.utc(1, 1, 1)), '0001-01-01');
    expect(civilDateIso8601(DateTime.utc(9999, 12, 31, 23, 59)), '9999-12-31');
    final offsetInstant = DateTime.parse('2026-01-01T00:15:00+02:00');
    expect(civilDateIso8601(offsetInstant), '2025-12-31');
  });
}
