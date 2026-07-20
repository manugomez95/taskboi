import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../connectivity/connectivity_provider.dart';
import 'sync_operation.dart';
import 'sync_service.dart';

class SyncQueueStatus {
  final int pendingCount;
  final int exhaustedCount;

  const SyncQueueStatus({
    required this.pendingCount,
    required this.exhaustedCount,
  });

  bool get hasExhaustedOperations => exhaustedCount > 0;
}

/// Provider for the app database
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for the sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final supabase = Supabase.instance.client;

  final service = SyncService(
    db: db,
    supabase: supabase,
    connectivity: connectivity,
  );

  service.initialize();
  ref.onDispose(() => service.dispose());

  return service;
});

/// Provider for pending sync count
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPendingSyncCount();
});

/// Detailed queue state used to avoid presenting exhausted operations as an
/// indefinitely active synchronization. They remain pending and recoverable.
final syncQueueStatusProvider = StreamProvider<SyncQueueStatus>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPendingSyncOperations().map(
        (operations) => SyncQueueStatus(
          pendingCount: operations.length,
          exhaustedCount: operations
              .where((op) => op.retryCount >= SyncOperation.maxRetries)
              .length,
        ),
      );
});

/// Provider to check if initial sync is needed
final needsInitialSyncProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(syncServiceProvider);
  return service.needsInitialSync();
});
