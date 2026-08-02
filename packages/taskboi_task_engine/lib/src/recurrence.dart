part of '../taskboi_task_engine.dart';

enum _RecurrenceFrequency { daily, weekly, monthly, yearly }

/// Semantic recurrence variants understood by description adapters.
enum RecurrenceDescriptionKind {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  everyNDays,
  everyNWeeks,
  everyNMonths,
  weeklyOn,
  unknown,
}

/// Framework-free result of strictly parsing a rule for description.
class RecurrenceDescription {
  const RecurrenceDescription._(
    this.kind, {
    this.interval,
    this.days = const [],
  });

  final RecurrenceDescriptionKind kind;
  final int? interval;
  final List<String> days;
}

/// Strict semantic parser used before presentation and localization.
abstract final class RecurrenceDescriptor {
  static const _none = RecurrenceDescription._(RecurrenceDescriptionKind.none);
  static const _unknown = RecurrenceDescription._(
    RecurrenceDescriptionKind.unknown,
  );

  static RecurrenceDescription parse(String? rule) {
    if (rule == null) return _none;
    final values = <String, String>{};
    for (final component in rule.split(';')) {
      final separator = component.indexOf('=');
      if (separator <= 0 || separator == component.length - 1) return _unknown;
      final key = component.substring(0, separator);
      if (!const {'FREQ', 'INTERVAL', 'BYDAY', 'BYMONTHDAY'}.contains(key) ||
          values.containsKey(key)) {
        return _unknown;
      }
      values[key] = component.substring(separator + 1);
    }

    final frequency = values['FREQ'];
    if (!const {'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'}.contains(frequency)) {
      return _unknown;
    }
    final interval = values['INTERVAL'] == null
        ? 1
        : int.tryParse(values['INTERVAL']!);
    final days = values['BYDAY']?.split(',') ?? const <String>[];
    final monthDay = values['BYMONTHDAY'] == null
        ? null
        : int.tryParse(values['BYMONTHDAY']!);
    if (interval == null ||
        interval < 1 ||
        days.any((day) => !RecurrenceRule._validDays.contains(day)) ||
        (days.isNotEmpty && frequency != 'WEEKLY') ||
        (values.containsKey('BYMONTHDAY') && monthDay == null) ||
        (monthDay != null &&
            (monthDay < 1 || monthDay > 31 || frequency != 'MONTHLY'))) {
      return _unknown;
    }

    if (values.containsKey('INTERVAL')) {
      if (frequency == 'YEARLY') return _unknown;
      if (interval == 1) {
        return RecurrenceDescription._(_simpleKind(frequency!));
      }
      final kind = switch (frequency) {
        'DAILY' => RecurrenceDescriptionKind.everyNDays,
        'WEEKLY' => RecurrenceDescriptionKind.everyNWeeks,
        _ => RecurrenceDescriptionKind.everyNMonths,
      };
      return RecurrenceDescription._(kind, interval: interval);
    }
    if (days.isNotEmpty) {
      return RecurrenceDescription._(
        RecurrenceDescriptionKind.weeklyOn,
        days: List.unmodifiable(days),
      );
    }
    if (monthDay != null) return _unknown;
    return RecurrenceDescription._(_simpleKind(frequency!));
  }

  static RecurrenceDescriptionKind _simpleKind(String frequency) =>
      switch (frequency) {
        'DAILY' => RecurrenceDescriptionKind.daily,
        'WEEKLY' => RecurrenceDescriptionKind.weekly,
        'MONTHLY' => RecurrenceDescriptionKind.monthly,
        'YEARLY' => RecurrenceDescriptionKind.yearly,
        _ => throw StateError('Validated frequency expected'),
      };
}

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
          current.year,
          current.month + parsed.interval,
          current.day,
        );
      case _RecurrenceFrequency.yearly:
        return DateTime(
          current.year + parsed.interval,
          current.month,
          current.day,
        );
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
    final interval = values['INTERVAL'] == null
        ? 1
        : int.tryParse(values['INTERVAL']!);
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
