part of '../taskboi_task_engine.dart';

/// Serializes an instant as an ISO 8601 UTC timestamp.
String? utcIso8601(DateTime? dateTime) => dateTime?.toUtc().toIso8601String();

/// Serializes the civil date fields without applying a timezone conversion.
String? civilDateIso8601(DateTime? dateTime) {
  if (dateTime == null) return null;
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
