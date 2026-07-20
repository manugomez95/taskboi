import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tasks_provider.dart';

/// Helper class for showing undo snackbars
class UndoSnackBarService {
  /// How long the undo window stays open before the action is committed.
  static const Duration _undoDuration = Duration(seconds: 5);

  /// Shows an undo snackbar for task completion
  static void showTaskCompleted(
    BuildContext context,
    WidgetRef ref, {
    required String taskTitle,
    required VoidCallback onUndo,
  }) {
    _showUndoSnackBar(
      context,
      message: '"$taskTitle" completed',
      onUndo: onUndo,
    );
  }

  /// Shows an undo snackbar for task uncompleted
  static void showTaskUncompleted(
    BuildContext context,
    WidgetRef ref, {
    required String taskTitle,
    required VoidCallback onUndo,
  }) {
    _showUndoSnackBar(
      context,
      message: '"$taskTitle" marked incomplete',
      onUndo: onUndo,
    );
  }

  /// Shows an undo snackbar for task moved
  static void showTaskMoved(
    BuildContext context,
    WidgetRef ref, {
    required String taskTitle,
    required String projectName,
    required VoidCallback onUndo,
  }) {
    _showUndoSnackBar(
      context,
      message: '"$taskTitle" moved to $projectName',
      onUndo: onUndo,
    );
  }

  /// Shows an undo snackbar for a deleted task and owns the full optimistic
  /// deletion lifecycle.
  ///
  /// The task is hidden immediately and actually deleted once the undo window
  /// elapses. The commit is driven by an independent [Timer] — NOT the
  /// snackbar's `closed` future — because action snackbars do not auto-dismiss
  /// while an accessibility service (TalkBack/VoiceOver) is active. Wiring the
  /// deletion to `closed` previously left the toast on screen indefinitely and,
  /// as a result, also skipped the deletion entirely.
  static void showTaskDeleted(
    BuildContext context,
    WidgetRef ref, {
    required String taskId,
    required String message,
    String actionLabel = 'Undo',
    ScaffoldMessengerState? messenger,
  }) {
    final scaffoldMessenger = messenger ?? ScaffoldMessenger.of(context);
    final notifier = ref.read(tasksNotifierProvider.notifier);

    // Hide immediately for optimistic UI.
    notifier.markPendingDeletion(taskId);

    var settled = false;
    Timer? commitTimer;

    void finalizeDeletion() {
      notifier.deleteTask(taskId);
      notifier.clearPendingDeletion(taskId);
    }

    commitTimer = Timer(_undoDuration, () {
      if (settled) return;
      settled = true;
      finalizeDeletion();
      // Our snackbar is guaranteed to still be current here: any earlier
      // dismissal would have completed `closed` and settled this first. Force
      // it away so it doesn't linger under an active accessibility service.
      scaffoldMessenger.hideCurrentSnackBar();
    });

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger
        .showSnackBar(
          SnackBar(
            content: Text(message, overflow: TextOverflow.ellipsis),
            duration: _undoDuration,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: actionLabel,
              onPressed: () {
                if (settled) return;
                settled = true;
                commitTimer?.cancel();
                // Undo: the task was never deleted, just unhide it.
                notifier.clearPendingDeletion(taskId);
              },
            ),
          ),
        )
        .closed
        .then((_) {
      // Dismissed (swiped away or replaced) before the timer fired: commit now.
      if (settled) return;
      settled = true;
      commitTimer?.cancel();
      finalizeDeletion();
    });
  }

  static void _showUndoSnackBar(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    ScaffoldMessengerState? messenger,
  }) {
    final scaffoldMessenger = messenger ?? ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          overflow: TextOverflow.ellipsis,
        ),
        duration: _undoDuration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: onUndo,
        ),
      ),
    );
  }
}

/// Extension on WidgetRef to simplify undo operations
extension UndoRefExtension on WidgetRef {
  /// Complete a task with undo support
  /// Uses optimistic pending completion to prevent flicker from realtime sync
  ///
  /// If [messenger] is provided, it will be used to show the snackbar.
  /// This is useful when the context may become invalid (e.g., after animations).
  Future<void> completeTaskWithUndo(
    BuildContext context,
    String taskId,
    String taskTitle, {
    ScaffoldMessengerState? messenger,
  }) async {
    // Capture ScaffoldMessenger before async operations to avoid invalid context
    // (task may be filtered from list during completion, unmounting the widget)
    final scaffoldMessenger = messenger ?? ScaffoldMessenger.of(context);
    final notifier = read(tasksNotifierProvider.notifier);

    // Mark as pending completion immediately for optimistic UI
    notifier.markPendingCompletion(taskId);

    // Actually complete the task in the database
    await notifier.completeTask(taskId);

    // Clear pending completion after delay to let stream catch up
    // This ensures the task stays hidden even if realtime sync causes flicker
    Future.delayed(const Duration(milliseconds: 500), () {
      notifier.clearPendingCompletion(taskId);
    });

    if (!context.mounted) return;

    UndoSnackBarService._showUndoSnackBar(
      context,
      message: '"$taskTitle" completed',
      onUndo: () async {
        // Clear pending completion since we're undoing
        notifier.clearPendingCompletion(taskId);
        await notifier.uncompleteTask(taskId);
      },
      messenger: scaffoldMessenger,
    );
  }

  /// Uncomplete a task with undo support
  Future<void> uncompleteTaskWithUndo(
    BuildContext context,
    String taskId,
    String taskTitle,
  ) async {
    // Capture ScaffoldMessenger before async operations to avoid invalid context
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final notifier = read(tasksNotifierProvider.notifier);
    await notifier.uncompleteTask(taskId);

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          '"$taskTitle" marked incomplete',
          overflow: TextOverflow.ellipsis,
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // When undoing an uncomplete, mark as pending completion for optimistic UI
            notifier.markPendingCompletion(taskId);
            await notifier.completeTask(taskId);
            Future.delayed(const Duration(milliseconds: 500), () {
              notifier.clearPendingCompletion(taskId);
            });
          },
        ),
      ),
    );
  }

  /// Toggle task completion with undo support
  ///
  /// If [messenger] is provided, it will be used to show the snackbar.
  /// This is useful when the context may become invalid (e.g., after animations).
  Future<void> toggleCompleteWithUndo(
    BuildContext context,
    String taskId,
    String taskTitle,
    bool wasCompleted, {
    ScaffoldMessengerState? messenger,
  }) async {
    if (wasCompleted) {
      await uncompleteTaskWithUndo(context, taskId, taskTitle);
    } else {
      await completeTaskWithUndo(context, taskId, taskTitle,
          messenger: messenger);
    }
  }
}
