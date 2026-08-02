part of '../taskboi_task_engine.dart';

/// Frequencies supported by Taskboi recurrence rules.
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// Validated, structured recurrence rule data.
class ParsedRecurrenceRule {
  const ParsedRecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.days = const [],
    this.monthDay,
  });

  final RecurrenceFrequency frequency;
  final int interval;
  final List<String> days;
  final int? monthDay;

  @override
  bool operator ==(Object other) =>
      other is ParsedRecurrenceRule &&
      frequency == other.frequency &&
      interval == other.interval &&
      _listEquals(days, other.days) &&
      monthDay == other.monthDay;

  @override
  int get hashCode =>
      Object.hash(frequency, interval, Object.hashAll(days), monthDay);
}

/// A localization key plus values needed to render a recurrence description.
class RecurrenceDescription {
  const RecurrenceDescription(this.key, {this.values = const {}});

  final String key;
  final Map<String, Object> values;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceDescription &&
      key == other.key &&
      _mapEquals(values, other.values);

  @override
  int get hashCode => Object.hash(
      key,
      Object.hashAllUnordered(
        values.entries
            .map((entry) => Object.hash(entry.key, _deepHash(entry.value))),
      ));
}

/// Builders, parsing, and scheduling for Taskboi recurrence rules.
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

  /// Parses a supported rule, returning `null` for malformed or unknown input.
  static ParsedRecurrenceRule? parse(String rule) {
    if (rule.isEmpty) return null;
    final values = <String, String>{};
    for (final component in rule.split(';')) {
      final separator = component.indexOf('=');
      if (separator <= 0 || separator == component.length - 1) return null;
      final key = component.substring(0, separator);
      if (values.containsKey(key) ||
          !const {'FREQ', 'INTERVAL', 'BYDAY', 'BYMONTHDAY'}.contains(key)) {
        return null;
      }
      values[key] = component.substring(separator + 1);
    }
    final frequency = switch (values['FREQ']) {
      'DAILY' => RecurrenceFrequency.daily,
      'WEEKLY' => RecurrenceFrequency.weekly,
      'MONTHLY' => RecurrenceFrequency.monthly,
      'YEARLY' => RecurrenceFrequency.yearly,
      _ => null,
    };
    if (frequency == null) return null;
    final interval =
        values['INTERVAL'] == null ? 1 : int.tryParse(values['INTERVAL']!);
    if (interval == null || interval < 1) return null;
    final days = values['BYDAY']?.split(',') ?? const <String>[];
    if (days.any((day) => !_validDays.contains(day)) ||
        (days.isNotEmpty && frequency != RecurrenceFrequency.weekly)) {
      return null;
    }
    final monthDay = values['BYMONTHDAY'] == null
        ? null
        : int.tryParse(values['BYMONTHDAY']!);
    if ((monthDay != null && (monthDay < 1 || monthDay > 31)) ||
        (values.containsKey('BYMONTHDAY') && monthDay == null) ||
        (monthDay != null && frequency != RecurrenceFrequency.monthly)) {
      return null;
    }
    return ParsedRecurrenceRule(
      frequency: frequency,
      interval: interval,
      days: List.unmodifiable(days),
      monthDay: monthDay,
    );
  }

  /// Returns nonlocalized description data for [rule].
  static RecurrenceDescription description(String? rule) {
    if (rule == null) return const RecurrenceDescription('none');
    final parsed = parse(rule);
    if (parsed == null) return const RecurrenceDescription('unknown');
    if (rule.split(';').any((component) => component.startsWith('INTERVAL='))) {
      if (parsed.frequency == RecurrenceFrequency.yearly) {
        return const RecurrenceDescription('unknown');
      }
      final key = switch (parsed.frequency) {
        RecurrenceFrequency.daily => 'everyNDays',
        RecurrenceFrequency.weekly => 'everyNWeeks',
        RecurrenceFrequency.monthly => 'everyNMonths',
        RecurrenceFrequency.yearly => throw StateError('Handled above'),
      };
      return parsed.interval == 1
          ? RecurrenceDescription(parsed.frequency.name)
          : RecurrenceDescription(key, values: {'interval': parsed.interval});
    }
    if (parsed.days.isNotEmpty) {
      return RecurrenceDescription('weeklyOn', values: {'days': parsed.days});
    }
    if (parsed.monthDay != null) return const RecurrenceDescription('unknown');
    return RecurrenceDescription(parsed.frequency.name);
  }

  /// Calculates the first scheduled occurrence strictly after [current].
  static DateTime? nextOccurrence(DateTime current, String rule) {
    final parsed = parse(rule) ?? _parseLegacySchedulingRule(rule);
    if (parsed == null) return null;
    switch (parsed.frequency) {
      case RecurrenceFrequency.daily:
        return current.add(Duration(days: parsed.interval));
      case RecurrenceFrequency.weekly:
        if (parsed.days.isEmpty) {
          return current.add(Duration(days: 7 * parsed.interval));
        }
        final weekdays = parsed.days.map(_weekday).toList()..sort();
        for (final weekday in weekdays) {
          if (weekday > current.weekday) {
            return current.add(Duration(days: weekday - current.weekday));
          }
        }
        final days = 7 - current.weekday + weekdays.first;
        return current.add(Duration(days: days));
      case RecurrenceFrequency.monthly:
        return DateTime(
          current.year,
          current.month + parsed.interval,
          current.day,
        );
      case RecurrenceFrequency.yearly:
        return DateTime(
          current.year + parsed.interval,
          current.month,
          current.day,
        );
    }
  }

  static ParsedRecurrenceRule? _parseLegacySchedulingRule(String rule) {
    final knownComponents = <String>[];
    final knownKeys = <String>{};
    for (final component in rule.split(';')) {
      final separator = component.indexOf('=');
      if (separator <= 0 || separator == component.length - 1) return null;
      final key = component.substring(0, separator);
      if (const {'FREQ', 'INTERVAL', 'BYDAY', 'BYMONTHDAY'}.contains(key)) {
        if (!knownKeys.add(key)) return null;
        knownComponents.add(component);
      }
    }
    return parse(knownComponents.join(';'));
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

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_deepEquals(a[i], b[i])) return false;
  }
  return true;
}

bool _mapEquals(Map<String, Object> a, Map<String, Object> b) {
  if (a.length != b.length) return false;
  return a.entries.every((entry) =>
      b.containsKey(entry.key) && _deepEquals(entry.value, b[entry.key]));
}

bool _deepEquals(Object? a, Object? b) =>
    a is List && b is List ? _listEquals(a, b) : a == b;

int _deepHash(Object? value) =>
    value is List ? Object.hashAll(value.map(_deepHash)) : value.hashCode;
