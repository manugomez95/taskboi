import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';

import '../../providers/language_provider.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguageId = ref.watch(languageIdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: Text(l10n.language),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: supportedLanguages.length,
        itemBuilder: (context, index) {
          final language = supportedLanguages[index];
          final isSelected = language.id == currentLanguageId;

          return _LanguageTile(
            language: language,
            isSelected: isSelected,
            l10n: l10n,
            onTap: () {
              ref
                  .read(languageNotifierProvider.notifier)
                  .setLanguage(language.id);
            },
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final LanguageOption language;
  final bool isSelected;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.l10n,
    required this.onTap,
  });

  String _getLocalizedName() {
    switch (language.id) {
      case 'system':
        return l10n.languageSystem;
      case 'en':
        return l10n.languageEnglish;
      case 'es':
        return l10n.languageSpanish;
      default:
        return language.name;
    }
  }

  IconData _getIcon() {
    switch (language.id) {
      case 'system':
        return Icons.smartphone;
      case 'en':
      case 'es':
      default:
        return Icons.language;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Icon(
        _getIcon(),
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
      title: Text(
        _getLocalizedName(),
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: language.id != 'system'
          ? Text(
              language.nativeName,
              style: TextStyle(
                color: theme.colorScheme.outline,
              ),
            )
          : null,
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: theme.colorScheme.primary,
            )
          : null,
    );
  }
}
