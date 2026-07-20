import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'core/deep_link/deep_link_provider.dart';
import 'core/router/app_router.dart';
import 'core/widget/widget_provider.dart';
import 'features/settings/providers/language_provider.dart';
import 'features/settings/providers/theme_provider.dart';

class TaskboiApp extends ConsumerWidget {
  const TaskboiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    // Watch the widget update provider to keep Android widget in sync
    if (!kIsWeb && Platform.isAndroid) {
      ref.watch(widgetUpdateProvider);

      // Initialize deep link handler for widget clicks
      ref.read(deepLinkHandlerProvider).initialize(router);
    }

    return MaterialApp.router(
      title: 'Taskboi',
      debugShowCheckedModeBanner: false,
      theme: currentTheme.lightTheme,
      darkTheme: currentTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
