import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/supabase_serialization.dart';
import '../../../../l10n/generated/app_localizations.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const Task._();

  const factory Task({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'parent_id') String? parentId,
    required String title,
    String? description,
    @JsonKey(name: 'due_date', toJson: dateOnly) DateTime? dueDate,
    @JsonKey(name: 'due_time') String? dueTime,
    @Default(0) int priority,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'completed_at', toJson: utcIso) DateTime? completedAt,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
    @JsonKey(name: 'recurrence_parent_id') String? recurrenceParentId,
    @JsonKey(name: 'recurrence_anchor_date', toJson: dateOnly)
    DateTime? recurrenceAnchorDate,
    @JsonKey(name: 'assigned_to') @Default('manuel') String assignedTo,
    @JsonKey(name: 'created_at', toJson: utcIso) DateTime? createdAt,
    @JsonKey(name: 'updated_at', toJson: utcIso) DateTime? updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  bool get isRecurring => recurrenceRule != null;
  bool get isSubtask => parentId != null;
}

/// Recurrence rule builder for common patterns
class RecurrenceRule {
  static const String daily = 'FREQ=DAILY';
  static const String weekly = 'FREQ=WEEKLY';
  static const String monthly = 'FREQ=MONTHLY';
  static const String yearly = 'FREQ=YEARLY';

  static String weeklyOn(List<String> days) {
    return 'FREQ=WEEKLY;BYDAY=${days.join(',')}';
  }

  static String monthlyOnDay(int day) {
    return 'FREQ=MONTHLY;BYMONTHDAY=$day';
  }

  static String everyNDays(int n) {
    return 'FREQ=DAILY;INTERVAL=$n';
  }

  static String everyNWeeks(int n) {
    return 'FREQ=WEEKLY;INTERVAL=$n';
  }

  static String everyNMonths(int n) {
    return 'FREQ=MONTHLY;INTERVAL=$n';
  }

  /// Parse a recurrence rule and return a human-readable description
  static String describe(String? rule) {
    if (rule == null) return '';

    if (rule == daily) return 'Daily';
    if (rule == weekly) return 'Weekly';
    if (rule == monthly) return 'Monthly';
    if (rule == yearly) return 'Yearly';

    if (rule.contains('INTERVAL=')) {
      final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rule);
      final interval = int.tryParse(intervalMatch?.group(1) ?? '1') ?? 1;

      if (rule.contains('FREQ=DAILY')) {
        return interval == 1 ? 'Daily' : 'Every $interval days';
      }
      if (rule.contains('FREQ=WEEKLY')) {
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      }
      if (rule.contains('FREQ=MONTHLY')) {
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      }
    }

    if (rule.contains('BYDAY=')) {
      final daysMatch = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(rule);
      final days = daysMatch?.group(1)?.split(',') ?? [];
      final dayNames = days.map((d) {
        switch (d) {
          case 'MO':
            return 'Mon';
          case 'TU':
            return 'Tue';
          case 'WE':
            return 'Wed';
          case 'TH':
            return 'Thu';
          case 'FR':
            return 'Fri';
          case 'SA':
            return 'Sat';
          case 'SU':
            return 'Sun';
          default:
            return d;
        }
      }).toList();
      return 'Weekly on ${dayNames.join(', ')}';
    }

    return 'Recurring';
  }

  /// Parse a recurrence rule and return a localized human-readable description
  static String describeWithL10n(String? rule, AppLocalizations l10n) {
    if (rule == null) return '';

    if (rule == daily) return l10n.recurrenceDaily;
    if (rule == weekly) return l10n.recurrenceWeekly;
    if (rule == monthly) return l10n.recurrenceMonthly;
    if (rule == yearly) return l10n.recurrenceYearly;

    if (rule.contains('INTERVAL=')) {
      final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rule);
      final interval = int.tryParse(intervalMatch?.group(1) ?? '1') ?? 1;

      if (rule.contains('FREQ=DAILY')) {
        return interval == 1
            ? l10n.recurrenceDaily
            : l10n.recurrenceEveryNDays(interval);
      }
      if (rule.contains('FREQ=WEEKLY')) {
        return interval == 1
            ? l10n.recurrenceWeekly
            : l10n.recurrenceEveryNWeeks(interval);
      }
      if (rule.contains('FREQ=MONTHLY')) {
        return interval == 1
            ? l10n.recurrenceMonthly
            : l10n.recurrenceEveryNMonths(interval);
      }
    }

    if (rule.contains('BYDAY=')) {
      final daysMatch = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(rule);
      final days = daysMatch?.group(1)?.split(',') ?? [];
      final dayNames = days.map((d) {
        switch (d) {
          case 'MO':
            return l10n.dayMon;
          case 'TU':
            return l10n.dayTue;
          case 'WE':
            return l10n.dayWed;
          case 'TH':
            return l10n.dayThu;
          case 'FR':
            return l10n.dayFri;
          case 'SA':
            return l10n.daySat;
          case 'SU':
            return l10n.daySun;
          default:
            return d;
        }
      }).toList();
      return l10n.recurrenceWeeklyOn(dayNames.join(', '));
    }

    return l10n.recurring;
  }

  /// Calculate the next occurrence date based on the rule
  static DateTime? getNextOccurrence(DateTime current, String rule) {
    if (rule.contains('FREQ=DAILY')) {
      final interval = _getInterval(rule);
      return current.add(Duration(days: interval));
    }

    if (rule.contains('FREQ=WEEKLY')) {
      final interval = _getInterval(rule);
      if (rule.contains('BYDAY=')) {
        // Parse BYDAY value (e.g., "MO,TU,WE,TH,FR")
        final byDayMatch = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(rule);
        if (byDayMatch != null) {
          final days = byDayMatch.group(1)!.split(',');
          const dayMap = {
            'SU': DateTime.sunday, // 7
            'MO': DateTime.monday, // 1
            'TU': DateTime.tuesday, // 2
            'WE': DateTime.wednesday, // 3
            'TH': DateTime.thursday, // 4
            'FR': DateTime.friday, // 5
            'SA': DateTime.saturday, // 6
          };

          final currentDayIndex = current.weekday; // 1=Monday, 7=Sunday
          final targetDays =
              days.map((d) => dayMap[d]).whereType<int>().toList()..sort();

          if (targetDays.isEmpty) {
            return current.add(Duration(days: 7 * interval));
          }

          // Find the next occurrence
          // First, check if there's a target day later this week
          for (final targetDay in targetDays) {
            if (targetDay > currentDayIndex) {
              return current.add(Duration(days: targetDay - currentDayIndex));
            }
          }

          // No target day found later this week, go to next week's first target day
          // Days until end of week + days to first target
          final daysUntilEndOfWeek = 7 - currentDayIndex;
          final daysToFirstTarget = targetDays.first;
          return current
              .add(Duration(days: daysUntilEndOfWeek + daysToFirstTarget));
        }
        return current.add(Duration(days: 7 * interval));
      }
      return current.add(Duration(days: 7 * interval));
    }

    if (rule.contains('FREQ=MONTHLY')) {
      final interval = _getInterval(rule);
      return DateTime(
        current.year,
        current.month + interval,
        current.day,
      );
    }

    if (rule.contains('FREQ=YEARLY')) {
      final interval = _getInterval(rule);
      return DateTime(
        current.year + interval,
        current.month,
        current.day,
      );
    }

    return null;
  }

  static int _getInterval(String rule) {
    final match = RegExp(r'INTERVAL=(\d+)').firstMatch(rule);
    return int.tryParse(match?.group(1) ?? '1') ?? 1;
  }
}
