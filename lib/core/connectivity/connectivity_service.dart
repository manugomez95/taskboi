import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream of connectivity changes
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Check current connectivity status
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  /// Check if the connectivity result indicates a connection
  bool _isConnected(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  /// Convert connectivity results to a boolean stream
  Stream<bool> get onlineStatusStream =>
      onConnectivityChanged.map(_isConnected);
}
