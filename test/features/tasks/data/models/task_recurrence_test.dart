import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/features/tasks/data/models/task.dart';
import 'package:taskboi/l10n/generated/app_localizations_es.dart';

void main() {
  test('describe preserves established English recurrence output', () {
    expect(RecurrenceRule.describe(null), '');
    expect(RecurrenceRule.describe('FREQ=DAILY'), 'Daily');
    expect(
      RecurrenceRule.describe('FREQ=DAILY;INTERVAL=3'),
      'Every 3 days',
    );
    expect(
      RecurrenceRule.describe('FREQ=WEEKLY;BYDAY=MO,WE'),
      'Weekly on Mon, Wed',
    );
    expect(
      RecurrenceRule.describe('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE'),
      'Every 2 weeks',
    );
    expect(
      RecurrenceRule.describe('FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE'),
      'Weekly',
    );
    expect(RecurrenceRule.describe('FREQ=MONTHLY;BYMONTHDAY=15'), 'Recurring');
    expect(RecurrenceRule.describe('FREQ=YEARLY;INTERVAL=2'), 'Recurring');
    expect(RecurrenceRule.describe('FREQ=NOPE'), 'Recurring');
  });

  test('describeWithL10n preserves established localized recurrence output',
      () {
    final l10n = AppLocalizationsEs();

    expect(
      RecurrenceRule.describeWithL10n('FREQ=MONTHLY', l10n),
      l10n.recurrenceMonthly,
    );
    expect(
      RecurrenceRule.describeWithL10n(
        'FREQ=WEEKLY;BYDAY=MO,WE',
        l10n,
      ),
      l10n.recurrenceWeeklyOn('${l10n.dayMon}, ${l10n.dayWed}'),
    );
    expect(
      RecurrenceRule.describeWithL10n('FREQ=NOPE', l10n),
      l10n.recurring,
    );
  });
}
