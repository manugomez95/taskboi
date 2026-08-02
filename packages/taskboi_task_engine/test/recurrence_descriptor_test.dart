import 'package:taskboi_task_engine/taskboi_task_engine.dart';
import 'package:test/test.dart';

void main() {
  void expectDescription(
    String? rule,
    RecurrenceDescriptionKind kind, {
    int? interval,
    List<String> days = const [],
  }) {
    final result = RecurrenceDescriptor.parse(rule);
    expect(result.kind, kind, reason: '$rule');
    expect(result.interval, interval, reason: '$rule');
    expect(result.days, days, reason: '$rule');
  }

  test('parses null and every valid description semantic', () {
    expectDescription(null, RecurrenceDescriptionKind.none);
    expectDescription('FREQ=DAILY', RecurrenceDescriptionKind.daily);
    expectDescription('FREQ=WEEKLY', RecurrenceDescriptionKind.weekly);
    expectDescription('FREQ=MONTHLY', RecurrenceDescriptionKind.monthly);
    expectDescription('FREQ=YEARLY', RecurrenceDescriptionKind.yearly);
    expectDescription(
      'FREQ=DAILY;INTERVAL=3',
      RecurrenceDescriptionKind.everyNDays,
      interval: 3,
    );
    expectDescription(
      'FREQ=WEEKLY;INTERVAL=2',
      RecurrenceDescriptionKind.everyNWeeks,
      interval: 2,
    );
    expectDescription(
      'FREQ=MONTHLY;INTERVAL=4',
      RecurrenceDescriptionKind.everyNMonths,
      interval: 4,
    );
    expectDescription(
      'FREQ=WEEKLY;BYDAY=MO,WE',
      RecurrenceDescriptionKind.weeklyOn,
      days: ['MO', 'WE'],
    );
  });

  test('rejects malformed, repeated, and unknown fields strictly', () {
    for (final rule in [
      '',
      'FREQ',
      '=DAILY',
      'FREQ=',
      'FREQ=DAILY;',
      'FREQ=DAILY;FREQ=WEEKLY',
      'FREQ=DAILY;INTERVAL=2;INTERVAL=3',
      'FREQ=WEEKLY;BYDAY=MO;BYDAY=TU',
      'FREQ=MONTHLY;BYMONTHDAY=1;BYMONTHDAY=2',
      'FREQ=DAILY;COUNT=2',
      'FREQ=DAILY;X-SOURCE=legacy',
      'freq=DAILY',
      'FREQ=daily',
      'FREQ=NOPE',
      'INTERVAL=2',
    ]) {
      expectDescription(rule, RecurrenceDescriptionKind.unknown);
    }
  });

  test('validates interval and byday interactions', () {
    expectDescription('FREQ=DAILY;INTERVAL=1', RecurrenceDescriptionKind.daily);
    expectDescription(
      'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO',
      RecurrenceDescriptionKind.weekly,
    );
    expectDescription(
      'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE',
      RecurrenceDescriptionKind.everyNWeeks,
      interval: 2,
    );
    for (final rule in [
      'FREQ=DAILY;INTERVAL=0',
      'FREQ=DAILY;INTERVAL=-1',
      'FREQ=DAILY;INTERVAL=x',
      'FREQ=YEARLY;INTERVAL=1',
      'FREQ=YEARLY;INTERVAL=2',
      'FREQ=WEEKLY;BYDAY=',
      'FREQ=WEEKLY;BYDAY=XX',
      'FREQ=WEEKLY;BYDAY=MO,',
      'FREQ=DAILY;BYDAY=MO',
      'FREQ=MONTHLY;BYMONTHDAY=0',
      'FREQ=MONTHLY;BYMONTHDAY=32',
      'FREQ=MONTHLY;BYMONTHDAY=x',
      'FREQ=DAILY;BYMONTHDAY=1',
      'FREQ=MONTHLY;BYMONTHDAY=15',
    ]) {
      expectDescription(rule, RecurrenceDescriptionKind.unknown);
    }
  });

  test('returned days cannot be mutated', () {
    final days = RecurrenceDescriptor.parse('FREQ=WEEKLY;BYDAY=MO').days;
    expect(() => days.add('TU'), throwsUnsupportedError);
  });
}
