import 'package:taskboi_task_engine/taskboi_task_engine.dart';
import 'package:test/test.dart';

void main() {
  group('recurrence builders', () {
    test('builds supported rules', () {
      expect(RecurrenceRule.daily, 'FREQ=DAILY');
      expect(RecurrenceRule.everyNDays(3), 'FREQ=DAILY;INTERVAL=3');
      expect(RecurrenceRule.weeklyOn(['MO', 'WE']), 'FREQ=WEEKLY;BYDAY=MO,WE');
      expect(RecurrenceRule.monthlyOnDay(31), 'FREQ=MONTHLY;BYMONTHDAY=31');
    });

    test('rejects invalid builder values', () {
      expect(() => RecurrenceRule.everyNDays(0), throwsArgumentError);
      expect(() => RecurrenceRule.monthlyOnDay(32), throwsArgumentError);
      expect(() => RecurrenceRule.weeklyOn(['XX']), throwsArgumentError);
    });
  });

  group('next occurrence', () {
    test(
        'schedules strict-parse unknown components with legacy rule-map behavior',
        () {
      final current = DateTime(2026, 1, 15, 9, 30);

      const countedRule = 'FREQ=DAILY;COUNT=10';
      expect(
        RecurrenceRule.nextOccurrence(current, countedRule),
        DateTime(2026, 1, 16, 9, 30),
      );

      const extendedRule = 'FREQ=MONTHLY;INTERVAL=2;X-SOURCE=legacy';
      expect(
        RecurrenceRule.nextOccurrence(current, extendedRule),
        DateTime(2026, 3, 15),
      );
    });

    test('advances daily, weekly, monthly, and yearly intervals', () {
      final current = DateTime(2026, 1, 15, 9, 30);
      expect(RecurrenceRule.nextOccurrence(current, 'FREQ=DAILY;INTERVAL=2'),
          DateTime(2026, 1, 17, 9, 30));
      expect(RecurrenceRule.nextOccurrence(current, 'FREQ=WEEKLY;INTERVAL=2'),
          DateTime(2026, 1, 29, 9, 30));
      expect(RecurrenceRule.nextOccurrence(current, 'FREQ=MONTHLY;INTERVAL=2'),
          DateTime(2026, 3, 15));
      expect(RecurrenceRule.nextOccurrence(current, 'FREQ=YEARLY;INTERVAL=2'),
          DateTime(2028, 1, 15));
    });

    test('weekly days preserve legacy behavior that ignores interval', () {
      final monday = DateTime(2026, 8, 3);
      expect(
          RecurrenceRule.nextOccurrence(
              monday, 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE'),
          DateTime(2026, 8, 5));
      final wednesday = DateTime(2026, 8, 5);
      expect(
          RecurrenceRule.nextOccurrence(
              wednesday, 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE'),
          DateTime(2026, 8, 10));
    });

    test('monthly day selector preserves legacy current-day rollover', () {
      expect(
        RecurrenceRule.nextOccurrence(
          DateTime(2026, 1, 31),
          'FREQ=MONTHLY;BYMONTHDAY=31',
        ),
        DateTime(2026, 3, 3),
      );
      expect(
        RecurrenceRule.nextOccurrence(
          DateTime(2026, 1, 10),
          'FREQ=MONTHLY;BYMONTHDAY=15',
        ),
        DateTime(2026, 2, 10),
      );
    });

    test('invalid or unknown input has no next occurrence', () {
      for (final rule in [
        'FREQ=NOPE',
        'FREQ=DAILY;INTERVAL=0',
        'FREQ=DAILY;INTERVAL=invalid',
        'INTERVAL=2;COUNT=10',
        'FREQ=WEEKLY;BYDAY=XX;COUNT=10',
        'FREQ=MONTHLY;BYMONTHDAY=0;COUNT=10',
        'FREQ=DAILY;FREQ=WEEKLY;COUNT=10',
        'FREQ=DAILY;INTERVAL=2;INTERVAL=3;COUNT=10',
        'FREQ=DAILY;UNKNOWN',
      ]) {
        expect(
          RecurrenceRule.nextOccurrence(DateTime(2026), rule),
          isNull,
          reason: rule,
        );
      }
    });
  });
}
