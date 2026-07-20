import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching theme preferences and UI state locally.
/// This ensures the correct theme is shown immediately on app launch
/// without waiting for Supabase to load.
class ThemeCacheService {
  static const String _themeIdKey = 'cached_theme_id';
  static const String _themeModeKey = 'cached_theme_mode';
  static const String _languageKey = 'cached_language';
  static const String _androidBannerDismissedKey = 'android_banner_dismissed';

  static SharedPreferences? _prefs;

  /// Initialize the cache service. Call this in main() before runApp().
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the cached theme ID, or null if not cached.
  static String? getCachedThemeId() {
    return _prefs?.getString(_themeIdKey);
  }

  /// Get the cached theme mode, or null if not cached.
  static String? getCachedThemeMode() {
    return _prefs?.getString(_themeModeKey);
  }

  /// Cache the theme ID locally.
  static Future<void> cacheThemeId(String themeId) async {
    await _prefs?.setString(_themeIdKey, themeId);
  }

  /// Cache the theme mode locally.
  static Future<void> cacheThemeMode(String themeMode) async {
    await _prefs?.setString(_themeModeKey, themeMode);
  }

  /// Get the cached language, or null if not cached.
  static String? getCachedLanguage() {
    return _prefs?.getString(_languageKey);
  }

  /// Cache the language locally.
  static Future<void> cacheLanguage(String language) async {
    await _prefs?.setString(_languageKey, language);
  }

  /// Check if the Android app banner has been dismissed.
  static bool isAndroidBannerDismissed() {
    return _prefs?.getBool(_androidBannerDismissedKey) ?? false;
  }

  /// Mark the Android app banner as dismissed.
  static Future<void> dismissAndroidBanner() async {
    await _prefs?.setBool(_androidBannerDismissedKey, true);
  }
}
