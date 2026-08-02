part of '../taskboi_task_engine.dart';

enum _RecurrenceFrequency { daily, weekly, monthly, yearly }

class _ParsedRecurrenceRule {
  const _ParsedRecurrenceRule({
    required this.frequency,
    required this.interval,
    required this.days,
  });

  final _RecurrenceFrequency frequency;
  final int interval;
  final List<String> days;
}

/// Builders and scheduling for Taskboi recurrence rules.
abstract final class RecurrenceRule {
  static const daily = 'FREQ=DAILY';
  static const weekly = 'FREQ=WEEKLY';
  static const monthly = 'FREQ=MONTHLY';
  static const yearly = 'FREQ=YEARLY';
  static const _validDays = {'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'};

  static String weeklyOn(List<String> days) {
    if (days.isEmpty || days.any((day) => !_validDays.contains(day))) {
      throw ArgumentError.value(days, 'days');
    }
    return 'FREQ=WEEKLY;BYDAY=${days.join(',')}';
  }

  static String monthlyOnDay(int day) {
    if (day < 1 || day > 31) throw ArgumentError.value(day, 'day');
    return 'FREQ=MONTHLY;BYMONTHDAY=$day';
  }

  static String everyNDays(int interval) => _intervalRule('DAILY', interval);
  static String everyNWeeks(int interval) => _intervalRule('WEEKLY', interval);
  static String everyNMonths(int interval) =>
      _intervalRule('MONTHLY', interval);

  static String _intervalRule(String frequency, int interval) {
    if (interval < 1) throw ArgumentError.value(interval, 'interval');
    return 'FREQ=$frequency;INTERVAL=$interval';
  }

  /// Calculates the first scheduled occurrence strictly after [current].
  static DateTime? nextOccurrence(DateTime current, String rule) {
    final parsed = _parse(rule);
    if (parsed == null) return null;
    switch (parsed.frequency) {
      case _RecurrenceFrequency.daily:
        return current.add(Duration(days: parsed.interval));
      case _RecurrenceFrequency.weekly:
        if (parsed.days.isEmpty) {
          return current.add(Duration(days: 7 * parsed.interval));
        }
        final weekdays = parsed.days.map(_weekday).toList()..sort();
        for (final weekday in weekdays) {
          if (weekday > current.weekday) {
            return current.add(Duration(days: weekday - current.weekday));
          }
        }
        return current.add(
          Duration(days: 7 - current.weekday + weekdays.first),
        );
      case _RecurrenceFrequency.monthly:
        return DateTime(
            current.year, current.month + parsed.interval, current.day);
      case _RecurrenceFrequency.yearly:
        return DateTime(
            current.year + parsed.interval, current.month, current.day);
    }
  }

  static _ParsedRecurrenceRule? _parse(String rule) {
    final values = <String, String>{};
    for (final component in rule.split(';')) {
      final separator = component.indexOf('=');
      if (separator <= 0 || separator == component.length - 1) return null;
      final key = component.substring(0, separator);
      if (!const {'FREQ', 'INTERVAL', 'BYDAY', 'BYMONTHDAY'}.contains(key)) {
        continue;
      }
      if (values.containsKey(key)) return null;
      values[key] = component.substring(separator + 1);
    }
    final frequency = switch (values['FREQ']) {
      'DAILY' => _RecurrenceFrequency.daily,
      'WEEKLY' => _RecurrenceFrequency.weekly,
      'MONTHLY' => _RecurrenceFrequency.monthly,
      'YEARLY' => _RecurrenceFrequency.yearly,
      _ => null,
    };
    if (frequency == null) return null;
    final interval =
        values['INTERVAL'] == null ? 1 : int.tryParse(values['INTERVAL']!);
    if (interval == null || interval < 1) return null;
    final days = values['BYDAY']?.split(',') ?? const <String>[];
    if (days.any((day) => !_validDays.contains(day)) ||
        (days.isNotEmpty && frequency != _RecurrenceFrequency.weekly)) {
      return null;
    }
    final monthDay = values['BYMONTHDAY'] == null
        ? null
        : int.tryParse(values['BYMONTHDAY']!);
    if ((monthDay != null && (monthDay < 1 || monthDay > 31)) ||
        (values.containsKey('BYMONTHDAY') && monthDay == null) ||
        (monthDay != null && frequency != _RecurrenceFrequency.monthly)) {
      return null;
    }
    return _ParsedRecurrenceRule(
      frequency: frequency,
      interval: interval,
      days: days,
    );
  }

  static int _weekday(String day) => switch (day) {
        'MO' => DateTime.monday,
        'TU' => DateTime.tuesday,
        'WE' => DateTime.wednesday,
        'TH' => DateTime.thursday,
        'FR' => DateTime.friday,
        'SA' => DateTime.saturday,
        'SU' => DateTime.sunday,
        _ => throw StateError('Validated weekday expected'),
      };
}
