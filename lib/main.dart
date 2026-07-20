import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/deep_link/deep_link_service.dart';
import 'core/widget/widget_service.dart';
import 'features/settings/data/services/theme_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme cache (loads cached theme instantly on launch)
  await ThemeCacheService.initialize();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize home screen widget service (Android only)
  if (!kIsWeb && Platform.isAndroid) {
    await WidgetService.initialize();
  }

  // Handle deep links for OAuth callback (desktop/mobile)
  if (!kIsWeb) {
    _setupDeepLinks();
  }

  runApp(
    const ProviderScope(
      child: TaskboiApp(),
    ),
  );
}

void _setupDeepLinks() {
  final appLinks = AppLinks();

  // Handle link when app is already running
  appLinks.uriLinkStream.listen((Uri uri) {
    _handleDeepLink(uri, isInitial: false);
  });

  // Handle link that launched the app
  appLinks.getInitialLink().then((Uri? uri) {
    if (uri != null) {
      _handleDeepLink(uri, isInitial: true);
    }
  });
}

Future<void> _handleDeepLink(Uri uri, {bool isInitial = false}) async {
  if (uri.scheme != 'taskboi') return;

  if (kDebugMode) {
    print('Received deep link: $uri');
  }

  // Check if this is an auth callback
  if (uri.host == 'login-callback') {
    try {
      // Supabase expects the full URL to extract the auth code
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling auth callback: $e');
      }
    }
    return;
  }

  // Handle widget deep links via DeepLinkService
  // URIs: taskboi://today, taskboi://add, taskboi://toggle/taskId, taskboi://open/taskId
  if (isInitial) {
    // Initial URI that launched the app - store for later consumption
    DeepLinkService.instance.setInitialUri(uri);
  } else {
    // App is already running - handle immediately
    DeepLinkService.instance.handleUri(uri);
  }
}
