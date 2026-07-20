import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_provider.dart';

/// Observes app lifecycle and triggers a full re-sync when the app
/// resumes from the background. This ensures data stays fresh even
/// if the Supabase realtime WebSocket dropped while backgrounded.
class SyncLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;

  const SyncLifecycleObserver({super.key, required this.child});

  @override
  ConsumerState<SyncLifecycleObserver> createState() =>
      _SyncLifecycleObserverState();
}

class _SyncLifecycleObserverState extends ConsumerState<SyncLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncServiceProvider).resumeSync();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
