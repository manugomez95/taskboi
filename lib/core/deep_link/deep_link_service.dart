import 'dart:async';

import 'package:flutter/foundation.dart';

/// Service for handling deep links from widgets and external sources.
///
/// This service bridges the gap between the deep link handler (which runs
/// before ProviderScope) and the app's navigation system.
class DeepLinkService {
  DeepLinkService._();

  static final _instance = DeepLinkService._();
  static DeepLinkService get instance => _instance;

  final _pendingUriController = StreamController<Uri>.broadcast();

  /// Stream of URIs that need to be handled by the app.
  Stream<Uri> get uriStream => _pendingUriController.stream;

  /// URI that launched the app (if any), consumed on first read.
  Uri? _initialUri;

  /// Get and clear the initial URI that launched the app.
  Uri? consumeInitialUri() {
    final uri = _initialUri;
    _initialUri = null;
    return uri;
  }

  /// Set the initial URI (called when app starts from a deep link).
  void setInitialUri(Uri uri) {
    _initialUri = uri;
  }

  /// Handle a deep link URI by adding it to the stream.
  void handleUri(Uri uri) {
    if (kDebugMode) {
      print('DeepLinkService: Handling URI: $uri');
    }
    _pendingUriController.add(uri);
  }

  void dispose() {
    _pendingUriController.close();
  }
}
