import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/task.dart';

/// Types of actions that can be undone
enum UndoActionType {
  completeTask,
  uncompleteTask,
  moveTask,
  deleteTask,
}

/// Represents an action that can be undone
class UndoAction {
  final UndoActionType type;
  final Task task;
  final String? previousProjectId; // For move actions
  final DateTime timestamp;

  UndoAction({
    required this.type,
    required this.task,
    this.previousProjectId,
  }) : timestamp = DateTime.now();

  String get description {
    switch (type) {
      case UndoActionType.completeTask:
        return 'Task completed';
      case UndoActionType.uncompleteTask:
        return 'Task marked incomplete';
      case UndoActionType.moveTask:
        return 'Task moved';
      case UndoActionType.deleteTask:
        return 'Task deleted';
    }
  }
}

/// State notifier for managing undo actions
class UndoNotifier extends StateNotifier<UndoAction?> {
  Timer? _dismissTimer;
  static const Duration undoDuration = Duration(seconds: 5);

  UndoNotifier() : super(null);

  /// Push a new undoable action
  void pushAction(UndoAction action) {
    _dismissTimer?.cancel();
    state = action;

    // Auto-dismiss after timeout
    _dismissTimer = Timer(undoDuration, () {
      clearAction();
    });
  }

  /// Clear the current undo action
  void clearAction() {
    _dismissTimer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}

final undoProvider = StateNotifierProvider<UndoNotifier, UndoAction?>((ref) {
  return UndoNotifier();
});
