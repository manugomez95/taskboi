import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/core/router/app_router.dart';

void main() {
  group('public landing redirects', () {
    test('anonymous routes preserve auth pages and use welcome for tasks', () {
      expect(
        appRedirect(
          location: '/',
          isAuthLoading: false,
          isStartupLoading: false,
          isLoggedIn: false,
        ),
        '/welcome',
      );
      expect(
        appRedirect(
          location: '/welcome',
          isAuthLoading: false,
          isStartupLoading: false,
          isLoggedIn: false,
        ),
        isNull,
      );
      expect(
        appRedirect(
          location: '/login',
          isAuthLoading: false,
          isStartupLoading: false,
          isLoggedIn: false,
        ),
        isNull,
      );
      expect(
        appRedirect(
          location: '/register',
          isAuthLoading: false,
          isStartupLoading: false,
          isLoggedIn: false,
        ),
        isNull,
      );
    });

    test('resolved loading and authenticated public routes use destinations',
        () {
      expect(
        appRedirect(
          location: '/loading',
          isAuthLoading: false,
          isStartupLoading: false,
          isLoggedIn: false,
        ),
        '/welcome',
      );
      for (final location in ['/welcome', '/login', '/register']) {
        expect(
          appRedirect(
            location: location,
            isAuthLoading: false,
            isStartupLoading: false,
            isLoggedIn: true,
          ),
          '/today',
        );
      }
    });

    test('loading and unknown deep-link behavior remains intact', () {
      expect(
        appRedirect(
          location: '/today',
          isAuthLoading: true,
          isStartupLoading: false,
          isLoggedIn: false,
        ),
        '/loading',
      );
      expect(
        appRedirect(
          location: '/task-from-widget',
          isAuthLoading: false,
          isStartupLoading: false,
          isLoggedIn: true,
        ),
        '/today',
      );
    });
  });
}
