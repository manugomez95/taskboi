import 'package:supabase_flutter/supabase_flutter.dart';

class PublicClientConfig {
  const PublicClientConfig({required this.url, required this.anonKey});

  factory PublicClientConfig.fromValues({
    required String url,
    required String anonKey,
  }) {
    final uri = Uri.tryParse(url);
    if (url.isEmpty ||
        uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw StateError(
        'PUBLIC_SUPABASE_URL must be an absolute HTTP(S) URL without credentials or a fragment.',
      );
    }
    if (anonKey.trim().isEmpty) {
      throw StateError('PUBLIC_SUPABASE_ANON_KEY must be set.');
    }
    return PublicClientConfig(url: url, anonKey: anonKey);
  }

  final String url;
  final String anonKey;
}

class SupabaseConfig {
  static const _url = String.fromEnvironment('PUBLIC_SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('PUBLIC_SUPABASE_ANON_KEY');

  static PublicClientConfig get publicClient =>
      PublicClientConfig.fromValues(url: _url, anonKey: _anonKey);

  static Future<void> initialize() async {
    final config = publicClient;
    await Supabase.initialize(
      url: config.url,
      anonKey: config.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
        timeout: Duration(seconds: 30),
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
