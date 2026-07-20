import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskboi/features/settings/data/repositories/api_key_repository.dart';

void main() {
  const userId = '00000000-0000-4000-8000-000000000001';
  const keyId = '00000000-0000-4000-8000-000000000002';

  ApiKeyRepository repositoryReturning(String responseBody) {
    final client = SupabaseClient(
      'https://synthetic.invalid',
      'synthetic-anon-key',
      httpClient: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/rest/v1/api_keys');
        expect(request.url.queryParameters['id'], 'eq.$keyId');
        expect(request.url.queryParameters['user_id'], 'eq.$userId');
        expect(request.url.queryParameters['select'], 'id');
        expect(request.headers['prefer'], contains('return=representation'));
        return http.Response(
          responseBody,
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    return ApiKeyRepository(client: client, userId: () => userId);
  }

  test('deleteApiKey completes only when the owned key was deleted', () async {
    final repository = repositoryReturning('[{"id":"$keyId"}]');

    await expectLater(repository.deleteApiKey(keyId), completes);
  });

  test('deleteApiKey reports an RLS or ownership no-op', () async {
    var requestCount = 0;
    final client = SupabaseClient(
      'https://synthetic.invalid',
      'synthetic-anon-key',
      httpClient: MockClient((request) async {
        requestCount++;
        expect(request.url.queryParameters['id'], 'eq.$keyId');
        expect(request.url.queryParameters['user_id'], 'eq.$userId');
        return http.Response(
          requestCount == 1 ? '[]' : '[{"id":"$keyId"}]',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final repository = ApiKeyRepository(client: client, userId: () => userId);

    await expectLater(repository.deleteApiKey(keyId), throwsStateError);
    expect(requestCount, 2);
  });

  test(
    'deleteApiKey accepts an empty representation when a scoped read confirms absence',
    () async {
      var requestCount = 0;
      final client = SupabaseClient(
        'https://synthetic.invalid',
        'synthetic-anon-key',
        httpClient: MockClient((request) async {
          requestCount++;
          expect(request.url.path, '/rest/v1/api_keys');
          expect(request.url.queryParameters['id'], 'eq.$keyId');
          expect(request.url.queryParameters['user_id'], 'eq.$userId');

          if (requestCount == 1) {
            expect(request.method, 'DELETE');
            expect(request.url.queryParameters['select'], 'id');
            return http.Response(
              '[]',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }

          expect(request.method, 'GET');
          expect(request.url.queryParameters['select'], 'id');
          return http.Response(
            '[]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = ApiKeyRepository(client: client, userId: () => userId);

      await expectLater(repository.deleteApiKey(keyId), completes);
      expect(requestCount, 2);
    },
  );

  test('deleteApiKey reports an empty-response verification error', () async {
    var requestCount = 0;
    final client = SupabaseClient(
      'https://synthetic.invalid',
      'synthetic-anon-key',
      httpClient: MockClient((request) async {
        requestCount++;
        expect(request.url.queryParameters['id'], 'eq.$keyId');
        expect(request.url.queryParameters['user_id'], 'eq.$userId');
        if (requestCount == 1) {
          return http.Response(
            '[]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"message":"verification failed"}',
          500,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final repository = ApiKeyRepository(client: client, userId: () => userId);

    await expectLater(repository.deleteApiKey(keyId), throwsA(anything));
    expect(requestCount, 2);
  });
}
