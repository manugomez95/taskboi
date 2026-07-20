import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/tasks/providers/tasks_provider.dart';
import 'deep_link_service.dart';

/// Provider that handles deep link navigation for widget URIs.
///
/// This provider listens to URIs from DeepLinkService and performs
/// the appropriate navigation or action.
final deepLinkHandlerProvider = Provider.autoDispose<DeepLinkHandler>((ref) {
  final handler = DeepLinkHandler(ref);
  ref.onDispose(() => handler.dispose());
  return handler;
});

class DeepLinkHandler {
  final Ref _ref;
  StreamSubscription<Uri>? _subscription;
  GoRouter? _router;

  DeepLinkHandler(this._ref);

  /// Initialize with the router and start listening for URIs.
  void initialize(GoRouter router) {
    _router = router;

    // Handle any initial URI that launched the app.
    // Must be delayed to run after GoRouter's initial navigation completes.
    final initialUri = DeepLinkService.instance.consumeInitialUri();
    if (initialUri != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUri(initialUri);
      });
    }

    // Listen for subsequent URIs
    _subscription = DeepLinkService.instance.uriStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    if (_router == null) {
      if (kDebugMode) {
        print('DeepLinkHandler: Router not initialized, ignoring URI: $uri');
      }
      return;
    }

    if (uri.scheme != 'taskboi') return;

    if (kDebugMode) {
      print('DeepLinkHandler: Processing URI: $uri');
    }

    switch (uri.host) {
      case 'today':
        _router!.go('/today');
        break;

      case 'add':
        // Navigate to today view, the add dialog will be triggered there
        _router!.go('/today');
        // TODO: Could trigger add task dialog after navigation
        break;

      case 'toggle':
        // Toggle task completion
        final taskId =
            uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        if (taskId != null) {
          _toggleTask(taskId);
        }
        // Navigate to today view after toggle
        _router!.go('/today');
        break;

      case 'open':
        // Open task - navigate to today view
        // The task detail sheet would need additional routing support
        _router!.go('/today');
        break;

      default:
        if (kDebugMode) {
          print('DeepLinkHandler: Unknown host: ${uri.host}');
        }
    }
  }

  Future<void> _toggleTask(String taskId) async {
    try {
      final notifier = _ref.read(tasksNotifierProvider.notifier);
      // We need to get the task to check its current state
      final task = await _ref.read(taskProvider(taskId).future);
      if (task != null) {
        if (task.isCompleted) {
          await notifier.uncompleteTask(taskId);
        } else {
          notifier.markPendingCompletion(taskId);
          await notifier.completeTask(taskId);
          Future.delayed(const Duration(milliseconds: 500), () {
            notifier.clearPendingCompletion(taskId);
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeepLinkHandler: Error toggling task: $e');
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
