import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/repositories/user_preferences_repository.dart';
import '../data/services/theme_cache_service.dart';
import 'theme_provider.dart';

// ============================================
// LANGUAGE PROVIDERS
// ============================================

/// Stream provider that watches the language from Supabase and updates cache
final _languageStreamProvider = StreamProvider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(ThemeCacheService.getCachedLanguage() ?? 'system');
  }

  final repository = ref.watch(userPreferencesRepositoryProvider);
  return repository.watchLanguage().map((language) {
    // Update cache when we receive a new value from Supabase
    ThemeCacheService.cacheLanguage(language);
    return language;
  });
});

/// Optimistic language state - used for instant UI updates
final _optimisticLanguageProvider = StateProvider<String?>((ref) => null);

/// Combined language ID provider - prefers optimistic state over stream
/// Uses cached value as fallback to prevent flash on app launch
final languageIdProvider = Provider<String>((ref) {
  final optimistic = ref.watch(_optimisticLanguageProvider);
  if (optimistic != null) return optimistic;

  final streamValue = ref.watch(_languageStreamProvider);
  // Use cached value while waiting for Supabase, fallback to 'system' if no cache
  return streamValue.valueOrNull ??
      ThemeCacheService.getCachedLanguage() ??
      'system';
});

/// Provider that returns the Flutter Locale based on languageId
/// Returns null if 'system' to let Flutter use device locale
final appLocaleProvider = Provider<Locale?>((ref) {
  final languageId = ref.watch(languageIdProvider);
  if (languageId == 'system') {
    return null; // Use system locale
  }
  return Locale(languageId);
});

/// Notifier for changing language with optimistic updates
class LanguageNotifier extends StateNotifier<AsyncValue<void>> {
  final UserPreferencesRepository _repository;
  final Ref _ref;

  LanguageNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// Change the language with optimistic update
  Future<void> setLanguage(String languageId) async {
    // Optimistically update the language immediately
    _ref.read(_optimisticLanguageProvider.notifier).state = languageId;

    // Cache locally for instant load on next app launch
    ThemeCacheService.cacheLanguage(languageId);

    state = const AsyncValue.loading();
    try {
      await _repository.setLanguage(languageId);
      state = const AsyncValue.data(null);

      // Clear optimistic state after a short delay to let stream catch up
      Future.delayed(const Duration(milliseconds: 500), () {
        _ref.read(_optimisticLanguageProvider.notifier).state = null;
      });
    } catch (e, st) {
      // On error, keep the optimistic state for UX but report error
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the language notifier
final languageNotifierProvider =
    StateNotifierProvider<LanguageNotifier, AsyncValue<void>>((ref) {
  return LanguageNotifier(
    ref.read(userPreferencesRepositoryProvider),
    ref,
  );
});

/// Available languages in the app
class LanguageOption {
  final String id;
  final String name;
  final String nativeName;

  const LanguageOption({
    required this.id,
    required this.name,
    required this.nativeName,
  });
}

/// List of supported languages
const supportedLanguages = [
  LanguageOption(id: 'system', name: 'System', nativeName: 'System'),
  LanguageOption(id: 'en', name: 'English', nativeName: 'English'),
  LanguageOption(id: 'es', name: 'Spanish', nativeName: 'Español'),
];
