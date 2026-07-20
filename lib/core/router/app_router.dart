import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/loading_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/projects/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/api_keys_screen.dart';
import '../../features/settings/presentation/screens/language_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/theme_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/tasks/providers/tasks_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isLoggedIn = authState.valueOrNull != null;
  final initialSyncState = isLoggedIn
      ? ref.watch(initialSyncProvider)
      : const AsyncValue<void>.data(null);
  final taskPreferencesState = isLoggedIn
      ? ref.watch(startupTaskPreferencesProvider)
      : const AsyncValue<void>.data(null);

  return GoRouter(
    initialLocation: '/loading',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isStartupLoading = isLoggedIn &&
          (initialSyncState.isLoading || taskPreferencesState.isLoading);
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isLoadingRoute = state.matchedLocation == '/loading';

      // While auth state, startup sync, or task view preferences are loading,
      // keep the app on the loading screen. This prevents the task UI from
      // rendering cached/default ordering and then shifting after startup.
      if ((isLoading || isStartupLoading) && !isLoadingRoute) {
        return '/loading';
      }

      // Once auth and startup data resolve, redirect from loading to the
      // appropriate destination.
      if (!isLoading && !isStartupLoading && isLoadingRoute) {
        return isLoggedIn ? '/today' : '/login';
      }

      // Handle widget deep links that GoRouter incorrectly tries to route.
      // URIs like taskboi://open/abc123 get parsed as path /abc123.
      // Redirect unknown paths (likely task IDs) to /today.
      final knownPaths = [
        '/',
        '/login',
        '/register',
        '/today',
        '/upcoming',
        '/settings',
        '/loading'
      ];
      final isKnownPath = knownPaths.contains(state.matchedLocation) ||
          state.matchedLocation.startsWith('/project/') ||
          state.matchedLocation.startsWith('/settings/');
      if (!isKnownPath) {
        return '/today';
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/today';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TaskListScreen(),
            ),
          ),
          GoRoute(
            path: '/project/:projectId',
            name: 'project',
            pageBuilder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return NoTransitionPage(
                child: TaskListScreen(projectId: projectId),
              );
            },
          ),
          GoRoute(
            path: '/today',
            name: 'today',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TaskListScreen(filter: TaskFilter.today),
            ),
          ),
          GoRoute(
            path: '/upcoming',
            name: 'upcoming',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TaskListScreen(filter: TaskFilter.upcoming),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings/api-keys',
            name: 'api-keys',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ApiKeysScreen(),
            ),
          ),
          GoRoute(
            path: '/settings/theme',
            name: 'theme',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ThemeScreen(),
            ),
          ),
          GoRoute(
            path: '/settings/language',
            name: 'language',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LanguageScreen(),
            ),
          ),
          GoRoute(
            path: '/settings/about',
            name: 'about',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AboutScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

enum TaskFilter { all, today, upcoming }
