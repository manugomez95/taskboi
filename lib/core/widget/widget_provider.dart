import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tasks/providers/tasks_provider.dart';
import 'widget_service.dart';

/// Provider that watches today tasks and updates the Android widget.
///
/// This provider should be watched by a widget near the root of the app
/// to ensure the home screen widget stays in sync with today's tasks.
final widgetUpdateProvider = Provider<void>((ref) {
  if (!Platform.isAndroid) return;

  // Watch today tasks and update widget when they change
  ref.listen<AsyncValue<dynamic>>(
    todayTasksProvider,
    (previous, next) {
      next.whenData((tasks) {
        WidgetService.updateTodayTasks(tasks);
      });
    },
    fireImmediately: true,
  );
});

/// Provider to trigger initial widget update when app starts.
/// Call this after authentication is confirmed.
final widgetInitializerProvider = Provider<WidgetInitializer>((ref) {
  return WidgetInitializer(ref);
});

class WidgetInitializer {
  final Ref _ref;

  WidgetInitializer(this._ref);

  /// Initialize the widget with current today tasks.
  void initialize() {
    if (!Platform.isAndroid) return;

    final todayTasks = _ref.read(todayTasksProvider);
    todayTasks.whenData((tasks) {
      WidgetService.updateTodayTasks(tasks);
    });
  }

  /// Clear widget data (call on logout).
  Future<void> clear() async {
    if (!Platform.isAndroid) return;
    await WidgetService.clearWidgetData();
  }
}
