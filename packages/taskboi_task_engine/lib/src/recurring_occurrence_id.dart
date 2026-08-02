part of '../taskboi_task_engine.dart';

/// Builds canonical occurrence material and passes it to [generateId].
///
/// Clients can inject UUID v5 or another deterministic identifier algorithm
/// without coupling this package to an ID library.
String recurringOccurrenceId({
  required String recurrenceParentId,
  required DateTime occurrenceDate,
  required String Function(String material) generateId,
}) {
  final year = occurrenceDate.year.toString().padLeft(4, '0');
  final month = occurrenceDate.month.toString().padLeft(2, '0');
  final day = occurrenceDate.day.toString().padLeft(2, '0');
  return generateId(
    'taskboi:recurring-occurrence:v1:$recurrenceParentId:$year-$month-$day',
  );
}
