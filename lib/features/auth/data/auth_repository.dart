import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';

class AuthRepository {
  final GoTrueClient _auth = SupabaseConfig.auth;

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'full_name': displayName} : null,
    );
  }

  Future<AuthResponse> signInWithGoogle() async {
    // Use web OAuth for web and macOS (more reliable on desktop)
    if (kIsWeb || (!kIsWeb && Platform.isMacOS)) {
      return await _signInWithGoogleWeb();
    } else {
      return await _signInWithGoogleNative();
    }
  }

  Future<AuthResponse> _signInWithGoogleWeb() async {
    // For web, use the current origin; for desktop, use web callback that redirects to app
    String? redirectUrl;
    if (kIsWeb) {
      // Use current origin for web (works for both localhost and production)
      final uri = Uri.base;
      redirectUrl =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    } else {
      redirectUrl = 'https://taskboi.netlify.app/auth-callback.html';
    }

    final success = await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!success) {
      throw const AuthException('Failed to launch Google sign-in');
    }

    // OAuth uses redirect, so this won't return a session immediately
    return AuthResponse(session: _auth.currentSession, user: _auth.currentUser);
  }

  Future<AuthResponse> _signInWithGoogleNative() async {
    const webClientId =
        '636021098570-q7ra7pblp70ft17254jh43dnfunbfd9n.apps.googleusercontent.com';
    const iosClientId =
        '636021098570-5ineegpgtltag13ommojm6bhsu3co1ie.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw const AuthException('Failed to get Google auth tokens');
    }

    return await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }
}
