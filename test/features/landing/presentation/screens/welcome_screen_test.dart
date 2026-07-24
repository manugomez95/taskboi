import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskboi/features/landing/presentation/screens/welcome_screen.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'package:url_launcher/link.dart';

void main() {
  Widget buildApp({
    Locale locale = const Locale('en'),
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (_, __) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('login destination')),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) =>
              const Scaffold(body: Text('register destination')),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  testWidgets('shows beta disclosure, verified features, and footer links',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Public beta'), findsOneWidget);
    expect(find.byKey(const Key('welcome-feature-offline')), findsOneWidget);
    expect(find.byKey(const Key('welcome-feature-planning')), findsOneWidget);
    expect(find.byKey(const Key('welcome-feature-backup')), findsOneWidget);
    expect(find.byKey(const Key('welcome-feature-mcp')), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('GitHub Issues'), findsWidgets);
    expect(find.textContaining('Apache-2.0'), findsOneWidget);
    final externalUris =
        tester.widgetList<Link>(find.byType(Link)).map((link) => link.uri);
    expect(
      externalUris,
      containsAll([
        Uri.parse('https://taskboi.netlify.app/privacy-policy.html'),
        Uri.parse('https://taskboi.netlify.app/terms-of-service.html'),
        Uri.parse('https://github.com/manugomez95/taskboi'),
        Uri.parse('https://github.com/manugomez95/taskboi/issues'),
      ]),
    );
  });

  testWidgets('internal calls to action navigate to register and login',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('welcome-create-account')).first);
    await tester.pumpAndSettle();
    expect(find.text('register destination'), findsOneWidget);

    GoRouter.of(tester.element(find.text('register destination')))
        .go('/welcome');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-sign-in')).first);
    await tester.pumpAndSettle();
    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('renders localized Spanish landing copy', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp(locale: const Locale('es')));
    await tester.pumpAndSettle();

    expect(find.text('Beta pública'), findsOneWidget);
    expect(find.text('Crear cuenta gratis'), findsWidgets);
  });

  testWidgets('feature cards fit localized copy at large text scales',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildApp(
        locale: const Locale('es'),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcome-feature-mcp')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
