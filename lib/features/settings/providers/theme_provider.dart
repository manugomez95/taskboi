import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/repositories/user_preferences_repository.dart';
import '../data/services/theme_cache_service.dart';

/// Repository provider for user preferences
final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  return UserPreferencesRepository();
});

// ============================================
// COLOR THEME PROVIDERS
// ============================================

/// Stream provider that watches the theme from Supabase and updates cache
final _themeStreamProvider = StreamProvider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(ThemeCacheService.getCachedThemeId() ?? 'default');
  }

  final repository = ref.watch(userPreferencesRepositoryProvider);
  return repository.watchTheme().map((themeId) {
    // Update cache when we receive a new value from Supabase
    ThemeCacheService.cacheThemeId(themeId);
    return themeId;
  });
});

/// Optimistic theme state - used for instant UI updates
final _optimisticThemeProvider = StateProvider<String?>((ref) => null);

/// Combined theme ID provider - prefers optimistic state over stream
/// Uses cached value as fallback to prevent flash on app launch
final themeIdProvider = Provider<String>((ref) {
  final optimistic = ref.watch(_optimisticThemeProvider);
  if (optimistic != null) return optimistic;

  final streamValue = ref.watch(_themeStreamProvider);
  // Use cached value while waiting for Supabase, fallback to 'default' if no cache
  return streamValue.valueOrNull ??
      ThemeCacheService.getCachedThemeId() ??
      'default';
});

/// Provider that returns the current AppColorTheme based on themeId
final currentThemeProvider = Provider<AppColorTheme>((ref) {
  final themeId = ref.watch(themeIdProvider);
  return AppTheme.getThemeById(themeId);
});

/// Notifier for changing themes with optimistic updates
class ThemeNotifier extends StateNotifier<AsyncValue<void>> {
  final UserPreferencesRepository _repository;
  final Ref _ref;

  ThemeNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// Change the theme with optimistic update
  Future<void> setTheme(String themeId) async {
    // Optimistically update the theme immediately
    _ref.read(_optimisticThemeProvider.notifier).state = themeId;

    // Cache locally for instant load on next app launch
    ThemeCacheService.cacheThemeId(themeId);

    state = const AsyncValue.loading();
    try {
      await _repository.setTheme(themeId);
      state = const AsyncValue.data(null);

      // Clear optimistic state after a short delay to let stream catch up
      Future.delayed(const Duration(milliseconds: 500), () {
        _ref.read(_optimisticThemeProvider.notifier).state = null;
      });
    } catch (e, st) {
      // On error, keep the optimistic state for UX but report error
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the theme notifier
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, AsyncValue<void>>((ref) {
  return ThemeNotifier(
    ref.read(userPreferencesRepositoryProvider),
    ref,
  );
});

// ============================================
// THEME MODE PROVIDERS (light/dark/system)
// ============================================

/// Stream provider that watches the theme mode from Supabase and updates cache
final _themeModeStreamProvider = StreamProvider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(ThemeCacheService.getCachedThemeMode() ?? 'system');
  }

  final repository = ref.watch(userPreferencesRepositoryProvider);
  return repository.watchThemeMode().map((themeMode) {
    // Update cache when we receive a new value from Supabase
    ThemeCacheService.cacheThemeMode(themeMode);
    return themeMode;
  });
});

/// Optimistic theme mode state - used for instant UI updates
final _optimisticThemeModeProvider = StateProvider<String?>((ref) => null);

/// Combined theme mode ID provider - prefers optimistic state over stream
/// Uses cached value as fallback to prevent flash on app launch
final themeModeIdProvider = Provider<String>((ref) {
  final optimistic = ref.watch(_optimisticThemeModeProvider);
  if (optimistic != null) return optimistic;

  final streamValue = ref.watch(_themeModeStreamProvider);
  // Use cached value while waiting for Supabase, fallback to 'system' if no cache
  return streamValue.valueOrNull ??
      ThemeCacheService.getCachedThemeMode() ??
      'system';
});

/// Provider that returns the Flutter ThemeMode based on themeModeId
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final modeId = ref.watch(themeModeIdProvider);
  switch (modeId) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});

/// Notifier for changing theme mode with optimistic updates
class ThemeModeNotifier extends StateNotifier<AsyncValue<void>> {
  final UserPreferencesRepository _repository;
  final Ref _ref;

  ThemeModeNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// Change the theme mode with optimistic update
  Future<void> setThemeMode(String modeId) async {
    // Optimistically update the theme mode immediately
    _ref.read(_optimisticThemeModeProvider.notifier).state = modeId;

    // Cache locally for instant load on next app launch
    ThemeCacheService.cacheThemeMode(modeId);

    state = const AsyncValue.loading();
    try {
      await _repository.setThemeMode(modeId);
      state = const AsyncValue.data(null);

      // Clear optimistic state after a short delay to let stream catch up
      Future.delayed(const Duration(milliseconds: 500), () {
        _ref.read(_optimisticThemeModeProvider.notifier).state = null;
      });
    } catch (e, st) {
      // On error, keep the optimistic state for UX but report error
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the theme mode notifier
final themeModeNotifierProvider =
    StateNotifierProvider<ThemeModeNotifier, AsyncValue<void>>((ref) {
  return ThemeModeNotifier(
    ref.read(userPreferencesRepositoryProvider),
    ref,
  );
});
