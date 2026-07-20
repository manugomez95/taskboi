import 'package:flutter/material.dart';

/// Simple loading screen shown while auth state is being determined.
/// This prevents flashing to login screen on web page reload before
/// the session is recovered from browser storage.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
