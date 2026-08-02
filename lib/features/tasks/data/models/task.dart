import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskboi_task_engine/taskboi_task_engine.dart' as engine;
import 'package:taskboi_task_engine/taskboi_task_engine.dart'
    show civilDateIso8601, utcIso8601;

import '../../../../l10n/generated/app_localizations.dart';

part 'task.freezed.dart';
part 'task.g.dart';

// Compatibility names embedded in existing Freezed output. These are function
// aliases only; serialization semantics live in taskboi_task_engine.
const dateOnly = civilDateIso8601;
const utcIso = utcIso8601;

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
    @JsonKey(name: 'due_date', toJson: civilDateIso8601) DateTime? dueDate,
    @JsonKey(name: 'due_time') String? dueTime,
    @Default(0) int priority,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'completed_at', toJson: utcIso8601) DateTime? completedAt,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
    @JsonKey(name: 'recurrence_parent_id') String? recurrenceParentId,
    @JsonKey(name: 'recurrence_anchor_date', toJson: civilDateIso8601)
    DateTime? recurrenceAnchorDate,
    @JsonKey(name: 'created_at', toJson: utcIso8601) DateTime? createdAt,
    @JsonKey(name: 'updated_at', toJson: utcIso8601) DateTime? updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  bool get isRecurring => recurrenceRule != null;
  bool get isSubtask => parentId != null;
}

/// Recurrence rule builder for common patterns
class RecurrenceRule {
  static const String daily = engine.RecurrenceRule.daily;
  static const String weekly = engine.RecurrenceRule.weekly;
  static const String monthly = engine.RecurrenceRule.monthly;
  static const String yearly = engine.RecurrenceRule.yearly;

  static String weeklyOn(List<String> days) {
    return engine.RecurrenceRule.weeklyOn(days);
  }

  static String monthlyOnDay(int day) {
    return engine.RecurrenceRule.monthlyOnDay(day);
  }

  static String everyNDays(int n) {
    return engine.RecurrenceRule.everyNDays(n);
  }

  static String everyNWeeks(int n) {
    return engine.RecurrenceRule.everyNWeeks(n);
  }

  static String everyNMonths(int n) {
    return engine.RecurrenceRule.everyNMonths(n);
  }

  /// Parse a recurrence rule and return a human-readable description
  static String describe(String? rule) {
    final description = engine.RecurrenceDescriptor.parse(rule);
    return switch (description.kind) {
      engine.RecurrenceDescriptionKind.none => '',
      engine.RecurrenceDescriptionKind.daily => 'Daily',
      engine.RecurrenceDescriptionKind.weekly => 'Weekly',
      engine.RecurrenceDescriptionKind.monthly => 'Monthly',
      engine.RecurrenceDescriptionKind.yearly => 'Yearly',
      engine.RecurrenceDescriptionKind.everyNDays =>
        'Every ${description.interval} days',
      engine.RecurrenceDescriptionKind.everyNWeeks =>
        'Every ${description.interval} weeks',
      engine.RecurrenceDescriptionKind.everyNMonths =>
        'Every ${description.interval} months',
      engine.RecurrenceDescriptionKind.weeklyOn =>
        'Weekly on ${_englishDays(description.days).join(', ')}',
      engine.RecurrenceDescriptionKind.unknown => 'Recurring',
    };
  }

  /// Parse a recurrence rule and return a localized human-readable description
  static String describeWithL10n(String? rule, AppLocalizations l10n) {
    final description = engine.RecurrenceDescriptor.parse(rule);
    return switch (description.kind) {
      engine.RecurrenceDescriptionKind.none => '',
      engine.RecurrenceDescriptionKind.daily => l10n.recurrenceDaily,
      engine.RecurrenceDescriptionKind.weekly => l10n.recurrenceWeekly,
      engine.RecurrenceDescriptionKind.monthly => l10n.recurrenceMonthly,
      engine.RecurrenceDescriptionKind.yearly => l10n.recurrenceYearly,
      engine.RecurrenceDescriptionKind.everyNDays => l10n.recurrenceEveryNDays(
          description.interval!,
        ),
      engine.RecurrenceDescriptionKind.everyNWeeks =>
        l10n.recurrenceEveryNWeeks(description.interval!),
      engine.RecurrenceDescriptionKind.everyNMonths =>
        l10n.recurrenceEveryNMonths(description.interval!),
      engine.RecurrenceDescriptionKind.weeklyOn => l10n.recurrenceWeeklyOn(
          _localizedDays(description.days, l10n).join(', '),
        ),
      engine.RecurrenceDescriptionKind.unknown => l10n.recurring,
    };
  }

  /// Calculate the next occurrence date based on the rule
  static DateTime? getNextOccurrence(DateTime current, String rule) {
    return engine.RecurrenceRule.nextOccurrence(current, rule);
  }

  static List<String> _englishDays(List<String> days) {
    const names = {
      'MO': 'Mon',
      'TU': 'Tue',
      'WE': 'Wed',
      'TH': 'Thu',
      'FR': 'Fri',
      'SA': 'Sat',
      'SU': 'Sun',
    };
    return days.map((day) => names[day] ?? day).toList();
  }

  static List<String> _localizedDays(List<String> days, AppLocalizations l10n) {
    final names = {
      'MO': l10n.dayMon,
      'TU': l10n.dayTue,
      'WE': l10n.dayWed,
      'TH': l10n.dayThu,
      'FR': l10n.dayFri,
      'SA': l10n.daySat,
      'SU': l10n.daySun,
    };
    return days.map((day) => names[day] ?? day).toList();
  }
}
