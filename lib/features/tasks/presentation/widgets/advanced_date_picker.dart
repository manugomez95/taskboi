import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/task.dart';

/// Result from the advanced date picker containing due date, due time, and recurrence
class DatePickerResult {
  final DateTime? dueDate;
  final String? dueTime;
  final String? recurrenceRule;

  const DatePickerResult({
    this.dueDate,
    this.dueTime,
    this.recurrenceRule,
  });
}

/// Shows an advanced date picker with quick options, time picker, and recurrence
Future<DatePickerResult?> showAdvancedDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  String? initialTime,
  String? initialRecurrence,
}) {
  return showModalBottomSheet<DatePickerResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AdvancedDatePickerSheet(
      initialDate: initialDate,
      initialTime: initialTime,
      initialRecurrence: initialRecurrence,
    ),
  );
}

class AdvancedDatePickerSheet extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialTime;
  final String? initialRecurrence;

  const AdvancedDatePickerSheet({
    super.key,
    this.initialDate,
    this.initialTime,
    this.initialRecurrence,
  });

  @override
  State<AdvancedDatePickerSheet> createState() =>
      _AdvancedDatePickerSheetState();
}

class _AdvancedDatePickerSheetState extends State<AdvancedDatePickerSheet> {
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedRecurrence;
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    _selectedRecurrence = widget.initialRecurrence;
  }

  void _selectAndClose(
    DateTime? date, {
    String? time,
    String? recurrence,
    bool keepCurrentRecurrence = true,
    bool keepCurrentTime = true,
  }) {
    Navigator.of(context).pop(DatePickerResult(
      dueDate: date,
      dueTime: keepCurrentTime ? (time ?? _selectedTime) : time,
      recurrenceRule: keepCurrentRecurrence
          ? (recurrence ?? _selectedRecurrence)
          : recurrence,
    ));
  }

  DateTime _getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _getTomorrow() {
    final today = _getToday();
    return today.add(const Duration(days: 1));
  }

  DateTime _getThisWeekend() {
    final today = _getToday();
    // Saturday is weekday 6
    final daysUntilSaturday = (DateTime.saturday - today.weekday) % 7;
    // If today is Saturday or Sunday, return today
    if (daysUntilSaturday == 0 || today.weekday == DateTime.sunday) {
      return today;
    }
    return today.add(Duration(days: daysUntilSaturday));
  }

  DateTime _getNextWeek() {
    final today = _getToday();
    // Next Monday
    final daysUntilMonday = (DateTime.monday - today.weekday + 7) % 7;
    // If today is Monday, get next Monday
    if (daysUntilMonday == 0) {
      return today.add(const Duration(days: 7));
    }
    return today.add(Duration(days: daysUntilMonday));
  }

  String _formatQuickDate(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  bool _isDateSelected(DateTime date) {
    if (_selectedDate == null) return false;
    return _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;
  }

  void _setRecurrence(String? rule) {
    setState(() {
      _selectedRecurrence = rule;
      // Auto-set due date to today if recurrence is selected but no date set
      if (rule != null && _selectedDate == null) {
        _selectedDate = _getToday();
      }
    });
  }

  Future<void> _pickATime() async {
    // Parse current time or default to now
    TimeOfDay initialTimeOfDay;
    if (_selectedTime != null) {
      final parts = _selectedTime!.split(':');
      initialTimeOfDay = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      initialTimeOfDay = TimeOfDay.now();
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTimeOfDay,
    );

    if (picked != null) {
      setState(() {
        _selectedTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _removeTime() {
    setState(() {
      _selectedTime = null;
    });
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final today = _getToday();
    final tomorrow = _getTomorrow();
    final thisWeekend = _getThisWeekend();
    final nextWeek = _getNextWeek();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    Text(
                      l10n.dueDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(DatePickerResult(
                        dueDate: _selectedDate,
                        dueTime: _selectedTime,
                        recurrenceRule: _selectedRecurrence,
                      )),
                      child: Text(l10n.done),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Quick date options
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today
                    _QuickDateTile(
                      icon: Icons.today,
                      iconColor: Colors.green,
                      title: l10n.today,
                      subtitle: _formatQuickDate(today),
                      isSelected: _isDateSelected(today),
                      onTap: () => _selectAndClose(today),
                    ),

                    // Tomorrow
                    _QuickDateTile(
                      icon: Icons.wb_sunny_outlined,
                      iconColor: Colors.orange,
                      title: l10n.tomorrow,
                      subtitle: _formatQuickDate(tomorrow),
                      isSelected: _isDateSelected(tomorrow),
                      onTap: () => _selectAndClose(tomorrow),
                    ),

                    // This Weekend
                    _QuickDateTile(
                      icon: Icons.weekend_outlined,
                      iconColor: Colors.blue,
                      title: l10n.thisWeekend,
                      subtitle: _formatQuickDate(thisWeekend),
                      isSelected: _isDateSelected(thisWeekend),
                      onTap: () => _selectAndClose(thisWeekend),
                    ),

                    // Next Week
                    _QuickDateTile(
                      icon: Icons.next_week_outlined,
                      iconColor: Colors.purple,
                      title: l10n.nextWeek,
                      subtitle: _formatQuickDate(nextWeek),
                      isSelected: _isDateSelected(nextWeek),
                      onTap: () => _selectAndClose(nextWeek),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Calendar section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickDateTile(
                      icon: Icons.calendar_month,
                      iconColor: theme.colorScheme.primary,
                      title: _selectedDate != null && !_showCalendar
                          ? DateFormat('EEEE, MMMM d, y').format(_selectedDate!)
                          : l10n.pickADate,
                      isSelected: _showCalendar,
                      showChevron: true,
                      onTap: () {
                        setState(() {
                          _showCalendar = !_showCalendar;
                        });
                      },
                    ),
                    if (_showCalendar) ...[
                      const SizedBox(height: 8),
                      CalendarDatePicker(
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 5)),
                        onDateChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1),

              // Time section (only show when a date is selected)
              if (_selectedDate != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QuickDateTile(
                        icon: Icons.schedule,
                        iconColor: theme.colorScheme.primary,
                        title: _selectedTime != null
                            ? _formatTime(_selectedTime!)
                            : l10n.pickATime,
                        isSelected: _selectedTime != null,
                        showChevron: true,
                        onTap: _pickATime,
                      ),
                      if (_selectedTime != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _removeTime,
                            icon: const Icon(Icons.clear,
                                size: 18, color: Colors.red),
                            label: Text(
                              l10n.removeTime,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],

              // Recurrence section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RecurrenceChip(
                          label: l10n.recurrenceNone,
                          isSelected: _selectedRecurrence == null,
                          onTap: () => _setRecurrence(null),
                        ),
                        _RecurrenceChip(
                          label: l10n.recurrenceDaily,
                          isSelected:
                              _selectedRecurrence == RecurrenceRule.daily,
                          onTap: () => _setRecurrence(RecurrenceRule.daily),
                        ),
                        _RecurrenceChip(
                          label: l10n.recurrenceWeekly,
                          isSelected:
                              _selectedRecurrence == RecurrenceRule.weekly,
                          onTap: () => _setRecurrence(RecurrenceRule.weekly),
                        ),
                        _RecurrenceChip(
                          label: l10n.recurrenceMonthly,
                          isSelected:
                              _selectedRecurrence == RecurrenceRule.monthly,
                          onTap: () => _setRecurrence(RecurrenceRule.monthly),
                        ),
                        _RecurrenceChip(
                          label: l10n.recurrenceYearly,
                          isSelected:
                              _selectedRecurrence == RecurrenceRule.yearly,
                          onTap: () => _setRecurrence(RecurrenceRule.yearly),
                        ),
                        _RecurrenceChip(
                          label: l10n.recurrenceWeekdays,
                          isSelected: _selectedRecurrence ==
                              'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
                          onTap: () => _setRecurrence(
                              'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Clear button (only if date or recurrence is set)
              if (_selectedDate != null || _selectedRecurrence != null) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    onPressed: () => _selectAndClose(
                      null,
                      time: null,
                      recurrence: null,
                      keepCurrentRecurrence: false,
                      keepCurrentTime: false,
                    ),
                    icon: const Icon(Icons.clear, color: Colors.red),
                    label: Text(
                      l10n.removeDateAndRecurrence,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickDateTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final bool showChevron;
  final VoidCallback onTap;

  const _QuickDateTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.isSelected,
    this.showChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (subtitle != null) ...[
                const Spacer(),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ] else
                const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              if (showChevron && !isSelected)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecurrenceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}
