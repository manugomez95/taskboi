import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/tasks/data/models/task.dart';

/// Service for managing the Android home screen widget.
///
/// Handles syncing task data to the widget and processing widget interactions.
class WidgetService {
  static const String _appGroupId = 'group.com.manugo.taskboi';
  static const String _androidWidgetName = 'TodayTasksWidget';

  /// Initialize the widget service.
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    await HomeWidget.setAppGroupId(_appGroupId);

    // Register callback for widget interactions
    HomeWidget.widgetClicked.listen(_handleWidgetClick);
  }

  /// Update the widget with the current today tasks.
  static Future<void> updateTodayTasks(List<Task> tasks) async {
    if (!Platform.isAndroid) return;

    try {
      // Filter to incomplete tasks for display
      final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();

      // Calculate overdue count
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final overdueCount = incompleteTasks.where((t) {
        if (t.dueDate == null) return false;
        final dueDay =
            DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return dueDay.isBefore(today);
      }).length;

      // Prepare task data for widget (show all incomplete tasks, scrollable)
      final displayTasks = incompleteTasks;

      final tasksJson = jsonEncode(
        displayTasks
            .map((t) => {
                  'id': t.id,
                  'title': t.title,
                  'isCompleted': t.isCompleted,
                  'priority': t.priority,
                  'dueDate': t.dueDate?.toIso8601String(),
                })
            .toList(),
      );

      // Save data to shared preferences for the widget
      await HomeWidget.saveWidgetData('today_tasks', tasksJson);
      await HomeWidget.saveWidgetData(
          'today_task_count', incompleteTasks.length);
      await HomeWidget.saveWidgetData('overdue_count', overdueCount);

      // Trigger widget update
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );

      debugPrint(
          'WidgetService: Updated widget with ${displayTasks.length} tasks');
    } catch (e) {
      debugPrint('WidgetService: Failed to update widget: $e');
    }
  }

  /// Handle clicks from the widget.
  static void _handleWidgetClick(Uri? uri) {
    if (uri == null) return;

    debugPrint('WidgetService: Widget clicked with URI: $uri');

    // URIs are in format: taskboi://action/taskId
    // Examples:
    // - taskboi://toggle/abc123 - Toggle task completion
    // - taskboi://open/abc123 - Open task details
    // - taskboi://today - Open today view
    // - taskboi://add - Open add task dialog

    // The actual handling will be done by the app's deep link handler
    // when the app is launched. The URI will be passed to the app.
  }

  /// Register a callback for widget click handling.
  /// Returns the initial URI if the app was launched from a widget click.
  static Future<Uri?> getInitialUri() async {
    if (!Platform.isAndroid) return null;
    return await HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  /// Clear widget data (e.g., on logout).
  static Future<void> clearWidgetData() async {
    if (!Platform.isAndroid) return;

    try {
      await HomeWidget.saveWidgetData('today_tasks', '[]');
      await HomeWidget.saveWidgetData('today_task_count', 0);
      await HomeWidget.saveWidgetData('overdue_count', 0);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('WidgetService: Failed to clear widget data: $e');
    }
  }
}
