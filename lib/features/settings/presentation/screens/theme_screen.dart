import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../providers/theme_provider.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeId = ref.watch(themeIdProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: Text(l10n.theme),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: AppTheme.allThemes.length,
        itemBuilder: (context, index) {
          final colorTheme = AppTheme.allThemes[index];
          final isSelected = colorTheme.id == currentThemeId;

          return _ThemeTile(
            colorTheme: colorTheme,
            isSelected: isSelected,
            onTap: () {
              ref.read(themeNotifierProvider.notifier).setTheme(colorTheme.id);
            },
          );
        },
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final AppColorTheme colorTheme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.colorTheme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorTheme.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isSelected ? theme.colorScheme.onSurface : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      title: Text(
        colorTheme.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: theme.colorScheme.primary,
            )
          : null,
    );
  }
}
