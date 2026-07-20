import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/core/config/supabase_config.dart';

void main() {
  group('PublicClientConfig', () {
    test('accepts explicit public client settings', () {
      final config = PublicClientConfig.fromValues(
        url: 'https://project.example.test',
        anonKey: 'public-test-key',
      );
      expect(config.url, 'https://project.example.test');
      expect(config.anonKey, 'public-test-key');
    });

    test('rejects missing settings without including their values', () {
      expect(
        () => PublicClientConfig.fromValues(url: '', anonKey: 'marker-value'),
        throwsA(isA<StateError>().having(
          (error) => error.message,
          'message',
          isNot(contains('marker-value')),
        )),
      );
      expect(
        () => PublicClientConfig.fromValues(
          url: 'https://project.example.test',
          anonKey: '',
        ),
        throwsStateError,
      );
    });

    test('rejects unsafe or malformed URLs', () {
      for (final url in [
        'not-a-url',
        'ftp://project.example.test',
        'https://user:pass@project.example.test',
        'https://project.example.test/#fragment',
      ]) {
        expect(
          () => PublicClientConfig.fromValues(url: url, anonKey: 'public-key'),
          throwsStateError,
        );
      }
    });
  });
}
