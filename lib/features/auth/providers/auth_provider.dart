import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/sync_provider.dart';
import '../../../core/widget/widget_service.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges.map((state) => state.session?.user);
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUpWithEmail(
      String email, String password, String? displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.signInWithGoogle(),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      // Stop realtime sync first
      final syncService = _ref.read(syncServiceProvider);
      syncService.stopRealtimeSync();

      // Clear local database
      final db = _ref.read(appDatabaseProvider);
      await db.clearAllData();

      // Clear Android home screen widget
      if (!kIsWeb && Platform.isAndroid) {
        await WidgetService.clearWidgetData();
      }

      if (kDebugMode) {
        print('Local database cleared');
      }

      // Sign out from Supabase
      await _repository.signOut();

      // Invalidate providers to force refresh on next login
      // This ensures cached data from previous user is cleared
      _ref.invalidate(appDatabaseProvider);
      _ref.invalidate(syncServiceProvider);
      _ref.invalidate(initialSyncProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.resetPassword(email),
    );
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

/// Provider to trigger initial sync on app startup if user is already logged in
final initialSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final syncService = ref.watch(syncServiceProvider);

  // Start realtime sync early so we don't miss changes during full sync
  syncService.startRealtimeSync(user.id);

  // CRITICAL: Process pending operations FIRST to push local changes to server
  // before pulling server state. This prevents full sync from overwriting
  // local changes that haven't been synced yet.
  await syncService.processPendingOperations();

  // Always perform full sync on startup to catch any changes missed
  // while the app was closed (realtime subscriptions don't persist)
  await syncService.performFullSync(user.id);
});

/// Provider that returns true once initial sync has completed,
/// including when it fails. Startup routing keeps the app on the loading
/// screen while the same sync future is in progress, so returning users do not
/// interact with stale cached tasks that may shift after server data arrives.
final initialSyncCompleteProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return true;

  final syncState = ref.watch(initialSyncProvider);
  return !syncState.isLoading;
});
