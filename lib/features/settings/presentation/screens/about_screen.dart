import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../providers/app_info_provider.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const String _privacyPolicyUrl =
      'https://taskboi.netlify.app/privacy-policy.html';
  static const String _termsOfServiceUrl =
      'https://taskboi.netlify.app/terms-of-service.html';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final version = ref.watch(appFullVersionProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: Text(l10n.about),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          // App logo and name
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icons/app_icon.jpg',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  version.isNotEmpty ? l10n.version(version) : '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.appDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(height: 1),
          // Legal section
          _AboutTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () => _launchUrl(_privacyPolicyUrl, context, l10n),
          ),
          _AboutTile(
            icon: Icons.description_outlined,
            title: l10n.termsOfService,
            onTap: () => _launchUrl(_termsOfServiceUrl, context, l10n),
          ),
          const Divider(height: 1),
          const SizedBox(height: 24),
          // Copyright
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.allRightsReserved(DateTime.now().year),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchUrl(
      String url, BuildContext context, AppLocalizations l10n) async {
    final uri = Uri.parse(url);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenLink)),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenLink)),
      );
    }
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AboutTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.onSurface,
      ),
      title: Text(title),
      trailing: Icon(
        Icons.open_in_new,
        size: 18,
        color: theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}
