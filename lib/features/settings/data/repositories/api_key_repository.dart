import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../models/api_key.dart';

class ApiKeyRepository {
  ApiKeyRepository({SupabaseClient? client, String? Function()? userId})
      : _client = client ?? SupabaseConfig.client,
        _userIdProvider = userId;

  final SupabaseClient _client;
  final String? Function()? _userIdProvider;

  static const _tableName = 'api_keys';

  String? get _userId =>
      _userIdProvider?.call() ?? _client.auth.currentUser?.id;

  /// Generate a random API key with prefix "tk_"
  String _generateApiKey() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final key =
        List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
    return 'tk_$key';
  }

  /// Hash an API key using SHA-256
  String _hashApiKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get all API keys for the current user
  Future<List<ApiKey>> getApiKeys() async {
    final response = await _client
        .from(_tableName)
        .select('id, user_id, key_prefix, name, last_used_at, created_at')
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return (response as List).map((json) => ApiKey.fromJson(json)).toList();
  }

  /// Create a new API key
  /// Returns the full API key (only shown once!)
  Future<({ApiKey apiKey, String fullKey})> createApiKey({
    String name = 'MCP',
  }) async {
    final fullKey = _generateApiKey();
    final keyHash = _hashApiKey(fullKey);
    final keyPrefix = fullKey.substring(0, 11); // "tk_" + first 8 chars

    final response = await _client
        .from(_tableName)
        .insert({
          'user_id': _userId,
          'key_hash': keyHash,
          'key_prefix': keyPrefix,
          'name': name,
        })
        .select('id, user_id, key_prefix, name, last_used_at, created_at')
        .single();

    return (
      apiKey: ApiKey.fromJson(response),
      fullKey: fullKey,
    );
  }

  /// Delete an API key
  Future<void> deleteApiKey(String id) async {
    final userId = _userId!;
    final deletedRows = await _client
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', userId)
        .select('id');

    if (deletedRows.isNotEmpty) return;

    final remainingRows = await _client
        .from(_tableName)
        .select('id')
        .eq('id', id)
        .eq('user_id', userId);

    if (remainingRows.isNotEmpty) {
      throw StateError('API key was not found or could not be deleted.');
    }
  }

  /// Watch API keys for real-time updates
  Stream<List<ApiKey>> watchApiKeys() {
    if (_userId == null) return Stream.value([]);

    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => ApiKey.fromJson(json)).toList())
        .handleError((error) {
          developer.log(
            'Realtime subscription error',
            name: 'taskboi.api_keys',
            error: error,
          );
          return <ApiKey>[];
        });
  }
}
