/// Serialization helpers for values sent to Supabase.
///
/// Postgres interprets timestamps without a zone offset in the server's
/// timezone (UTC), so a bare `toIso8601String()` of a local [DateTime]
/// stores the wrong instant (e.g. +2h in Spain). Every `timestamptz`
/// value must go through [utcIso].
///
/// `date` columns (due_date, recurrence_anchor_date) are calendar dates in
/// the user's timezone; converting them to UTC could shift them to the
/// previous day, so they use [dateOnly] instead.
String? utcIso(DateTime? dateTime) => dateTime?.toUtc().toIso8601String();

String? dateOnly(DateTime? dateTime) {
  if (dateTime == null) return null;
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
