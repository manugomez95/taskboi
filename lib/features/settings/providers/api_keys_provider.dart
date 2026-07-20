import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/api_key.dart';
import '../data/repositories/api_key_repository.dart';

final apiKeyRepositoryProvider = Provider<ApiKeyRepository>((ref) {
  return ApiKeyRepository();
});

final apiKeysStreamProvider = StreamProvider<List<ApiKey>>((ref) {
  final repository = ref.watch(apiKeyRepositoryProvider);
  return repository.watchApiKeys();
});

final apiKeysNotifierProvider =
    StateNotifierProvider<ApiKeysNotifier, AsyncValue<void>>((ref) {
  return ApiKeysNotifier(
    ref.read(apiKeyRepositoryProvider),
    onKeysChanged: () => ref.invalidate(apiKeysStreamProvider),
  );
});

class ApiKeysNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiKeyRepository _repository;
  final void Function() _onKeysChanged;

  ApiKeysNotifier(
    this._repository, {
    required void Function() onKeysChanged,
  })  : _onKeysChanged = onKeysChanged,
        super(const AsyncValue.data(null));

  Future<({ApiKey apiKey, String fullKey})?> createApiKey({
    String name = 'MCP',
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createApiKey(name: name);
      _onKeysChanged();
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteApiKey(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteApiKey(id);
      _onKeysChanged();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
