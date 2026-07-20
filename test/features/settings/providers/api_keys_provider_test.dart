import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskboi/features/settings/data/models/api_key.dart';
import 'package:taskboi/features/settings/data/repositories/api_key_repository.dart';
import 'package:taskboi/features/settings/providers/api_keys_provider.dart';

void main() {
  test(
    'successful create and delete refresh the observable key list without Realtime',
    () async {
      final client = SupabaseClient(
        'https://synthetic.invalid',
        'synthetic-anon-key',
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );
      addTearDown(client.dispose);
      final repository = _SilentRealtimeApiKeyRepository(client);
      final container = ProviderContainer(
        overrides: [apiKeyRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(await container.read(apiKeysStreamProvider.future), isEmpty);

      final created = await container
          .read(apiKeysNotifierProvider.notifier)
          .createApiKey(name: 'Test key');

      expect(created, isNotNull);
      expect(
        await container.read(apiKeysStreamProvider.future),
        [created!.apiKey],
      );

      final deleted = await container
          .read(apiKeysNotifierProvider.notifier)
          .deleteApiKey(created.apiKey.id);

      expect(deleted, isTrue);
      expect(await container.read(apiKeysStreamProvider.future), isEmpty);
    },
  );
}

class _SilentRealtimeApiKeyRepository extends ApiKeyRepository {
  _SilentRealtimeApiKeyRepository(SupabaseClient client)
      : super(client: client, userId: () => 'user-1');

  final List<ApiKey> _keys = [];

  @override
  Stream<List<ApiKey>> watchApiKeys() => Stream.value(List.of(_keys));

  @override
  Future<({ApiKey apiKey, String fullKey})> createApiKey({
    String name = 'MCP',
  }) async {
    final apiKey = ApiKey(
      id: 'key-${_keys.length + 1}',
      userId: 'user-1',
      keyPrefix: 'tk_testkey',
      name: name,
    );
    _keys.insert(0, apiKey);
    return (apiKey: apiKey, fullKey: 'tk_testkey_full');
  }

  @override
  Future<void> deleteApiKey(String id) async {
    _keys.removeWhere((key) => key.id == id && key.userId == 'user-1');
  }
}
