import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';

class UserPreferencesRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  static const _tableName = 'profiles';

  String? get _userId => _client.auth.currentUser?.id;

  // ============================================
  // THEME PREFERENCES (color theme)
  // ============================================

  /// Get the user's theme preference
  Future<String> getTheme() async {
    if (_userId == null) return 'default';

    try {
      final response = await _client
          .from(_tableName)
          .select('theme')
          .eq('id', _userId!)
          .single();

      return response['theme'] as String? ?? 'default';
    } catch (e) {
      return 'default';
    }
  }

  /// Update the user's theme preference
  Future<void> setTheme(String themeId) async {
    if (_userId == null) return;

    await _client
        .from(_tableName)
        .update({'theme': themeId}).eq('id', _userId!);
  }

  /// Watch the user's theme preference for real-time updates
  Stream<String> watchTheme() {
    if (_userId == null) return Stream.value('default');

    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', _userId!)
        .map((data) {
          if (data.isEmpty) return 'default';
          return data.first['theme'] as String? ?? 'default';
        })
        .handleError((error) {
          developer.log('Theme subscription error',
              name: 'taskboi.preferences', error: error);
          return 'default';
        });
  }

  // ============================================
  // THEME MODE PREFERENCES (light/dark/system)
  // ============================================

  /// Get the user's theme mode preference
  Future<String> getThemeMode() async {
    if (_userId == null) return 'system';

    try {
      final response = await _client
          .from(_tableName)
          .select('theme_mode')
          .eq('id', _userId!)
          .single();

      return response['theme_mode'] as String? ?? 'system';
    } catch (e) {
      return 'system';
    }
  }

  /// Update the user's theme mode preference
  Future<void> setThemeMode(String themeMode) async {
    if (_userId == null) return;

    await _client
        .from(_tableName)
        .update({'theme_mode': themeMode}).eq('id', _userId!);
  }

  /// Watch the user's theme mode preference for real-time updates
  Stream<String> watchThemeMode() {
    if (_userId == null) return Stream.value('system');

    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', _userId!)
        .map((data) {
          if (data.isEmpty) return 'system';
          return data.first['theme_mode'] as String? ?? 'system';
        })
        .handleError((error) {
          developer.log('Theme mode subscription error',
              name: 'taskboi.preferences', error: error);
          return 'system';
        });
  }

  // ============================================
  // LANGUAGE PREFERENCES
  // ============================================

  /// Get the user's language preference
  Future<String> getLanguage() async {
    if (_userId == null) return 'system';

    try {
      final response = await _client
          .from(_tableName)
          .select('language')
          .eq('id', _userId!)
          .single();

      return response['language'] as String? ?? 'system';
    } catch (e) {
      return 'system';
    }
  }

  /// Update the user's language preference
  Future<void> setLanguage(String language) async {
    if (_userId == null) return;

    await _client
        .from(_tableName)
        .update({'language': language}).eq('id', _userId!);
  }

  /// Watch the user's language preference for real-time updates
  Stream<String> watchLanguage() {
    if (_userId == null) return Stream.value('system');

    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', _userId!)
        .map((data) {
          if (data.isEmpty) return 'system';
          return data.first['language'] as String? ?? 'system';
        })
        .handleError((error) {
          developer.log('Language subscription error',
              name: 'taskboi.preferences', error: error);
          return 'system';
        });
  }

  // ============================================
  // PER-VIEW SORT PREFERENCES
  // ============================================

  /// Get all per-view sort preferences as a map
  Future<Map<String, String>> getSortPreferences() async {
    if (_userId == null) return {};

    try {
      final response = await _client
          .from(_tableName)
          .select('sort_preferences')
          .eq('id', _userId!)
          .single();

      final prefs = response['sort_preferences'];
      if (prefs == null) return {};
      return Map<String, String>.from(prefs as Map);
    } catch (e) {
      return {};
    }
  }

  /// Get sort preference for a specific view
  Future<String> getSortPreferenceForView(String viewKey) async {
    final prefs = await getSortPreferences();
    return prefs[viewKey] ?? 'manual';
  }

  /// Update sort preference for a specific view
  Future<void> setSortPreferenceForView(
      String viewKey, String sortOption) async {
    if (_userId == null) return;

    // Get current preferences
    final currentPrefs = await getSortPreferences();

    // Update the specific view
    currentPrefs[viewKey] = sortOption;

    // Save back to database
    await _client
        .from(_tableName)
        .update({'sort_preferences': currentPrefs}).eq('id', _userId!);
  }

  /// Watch all per-view sort preferences for real-time updates
  Stream<Map<String, String>> watchSortPreferences() {
    if (_userId == null) return Stream.value({});

    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', _userId!)
        .map((data) {
          if (data.isEmpty) return <String, String>{};
          final prefs = data.first['sort_preferences'];
          if (prefs == null) return <String, String>{};
          return Map<String, String>.from(prefs as Map);
        })
        .handleError((error) {
          developer.log('Sort preferences subscription error',
              name: 'taskboi.preferences', error: error);
          return <String, String>{};
        });
  }

  // ============================================
  // PER-VIEW SHOW COMPLETED PREFERENCES
  // ============================================

  /// Get all per-view show completed preferences as a map
  Future<Map<String, bool>> getShowCompletedPreferences() async {
    if (_userId == null) return {};

    try {
      final response = await _client
          .from(_tableName)
          .select('show_completed_preferences')
          .eq('id', _userId!)
          .single();

      final prefs = response['show_completed_preferences'];
      if (prefs == null) return {};
      return Map<String, bool>.from(prefs as Map);
    } catch (e) {
      return {};
    }
  }

  /// Update show completed preference for a specific view
  Future<void> setShowCompletedForView(
      String viewKey, bool showCompleted) async {
    if (_userId == null) return;

    // Get current preferences
    final currentPrefs = await getShowCompletedPreferences();

    // Update the specific view
    currentPrefs[viewKey] = showCompleted;

    // Save back to database
    await _client.from(_tableName).update(
        {'show_completed_preferences': currentPrefs}).eq('id', _userId!);
  }

  /// Watch all per-view show completed preferences for real-time updates
  Stream<Map<String, bool>> watchShowCompletedPreferences() {
    if (_userId == null) return Stream.value({});

    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', _userId!)
        .map((data) {
          if (data.isEmpty) return <String, bool>{};
          final prefs = data.first['show_completed_preferences'];
          if (prefs == null) return <String, bool>{};
          return Map<String, bool>.from(prefs as Map);
        })
        .handleError((error) {
          developer.log('Show completed preferences subscription error',
              name: 'taskboi.preferences', error: error);
          return <String, bool>{};
        });
  }

  // ============================================
  // AGENT WEBHOOK URL (global)
  // ============================================

  /// Get the user's global agent webhook URL
  Future<String> getAgentWebhookUrl() async {
    if (_userId == null) return '';

    try {
      final response = await _client
          .from(_tableName)
          .select('agent_webhook_url')
          .eq('id', _userId!)
          .single();

      return response['agent_webhook_url'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Update the user's global agent webhook URL
  Future<void> setAgentWebhookUrl(String url) async {
    if (_userId == null) return;

    await _client
        .from(_tableName)
        .update({'agent_webhook_url': url}).eq('id', _userId!);
  }
}
