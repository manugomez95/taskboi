import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reorderable drag listener that requires a brief hold before dragging.
/// Provides haptic feedback when drag is ready to start.
class DelayedReorderableListener extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final bool enabled;

  const DelayedReorderableListener({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 200),
    this.enabled = true,
  });

  @override
  State<DelayedReorderableListener> createState() =>
      _DelayedReorderableListenerState();
}

class _DelayedReorderableListenerState
    extends State<DelayedReorderableListener> {
  Timer? _hapticTimer;
  Offset? _startPosition;
  static const double _scrollThreshold = 10.0;

  @override
  void dispose() {
    _hapticTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _startPosition = event.position;
    _hapticTimer?.cancel();
    _hapticTimer = Timer(widget.delay, () {
      // Only trigger if we haven't been cancelled by movement
      if (_startPosition != null) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    // If moved too far, user is scrolling - cancel haptic
    if (_startPosition != null) {
      final distance = (event.position - _startPosition!).distance;
      if (distance > _scrollThreshold) {
        _hapticTimer?.cancel();
        _startPosition = null;
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _hapticTimer?.cancel();
    _startPosition = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _hapticTimer?.cancel();
    _startPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    // Use Flutter's built-in delayed drag listener
    // Wrap with Listener for haptic feedback (doesn't interfere with gestures)
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: ReorderableDelayedDragStartListener(
        index: widget.index,
        child: widget.child,
      ),
    );
  }
}
