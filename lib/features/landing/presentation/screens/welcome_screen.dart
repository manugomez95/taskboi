import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';

import '../../../../l10n/generated/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static final _links = <String, Uri>{
    'privacy': Uri.parse('https://taskboi.netlify.app/privacy-policy.html'),
    'terms': Uri.parse('https://taskboi.netlify.app/terms-of-service.html'),
    'github': Uri.parse('https://github.com/manugomez95/taskboi'),
    'issues': Uri.parse('https://github.com/manugomez95/taskboi/issues'),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(l10n: l10n),
                      const SizedBox(height: 32),
                      _Hero(l10n: l10n),
                      const SizedBox(height: 32),
                      Text(
                        l10n.welcomeFeaturesTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      _FeatureGrid(l10n: l10n),
                      const SizedBox(height: 32),
                      _Footer(l10n: l10n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final brand = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icons/app_icon.jpg',
                  width: 40,
                  height: 40,
                  semanticLabel: l10n.appName,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.appName,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          );
          final actions = [
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(l10n.signIn),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () => context.go('/register'),
              child: Text(l10n.welcomeCreateFreeAccount),
            ),
          ];
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: brand),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 8,
                  children: actions,
                ),
              ],
            );
          }
          return Row(children: [brand, const Spacer(), ...actions]);
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Chip(
            avatar: const Icon(Icons.science_outlined, size: 18),
            label: Text(l10n.welcomeBetaBadge),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.welcomeHeadline,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _CenteredCopy(text: l10n.welcomeSupportingCopy, prominent: true),
          const SizedBox(height: 12),
          _CenteredCopy(text: l10n.welcomeBetaCaveat),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                key: const Key('welcome-create-account'),
                onPressed: () => context.go('/register'),
                child: Text(l10n.welcomeCreateFreeAccount),
              ),
              OutlinedButton(
                key: const Key('welcome-sign-in'),
                onPressed: () => context.go('/login'),
                child: Text(l10n.signIn),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenteredCopy extends StatelessWidget {
  const _CenteredCopy({required this.text, this.prominent = false});
  final String text;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: prominent
            ? theme.textTheme.bodyLarge
            : theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        const Key('welcome-feature-offline'),
        Icons.offline_bolt_outlined,
        l10n.welcomeOfflineTitle,
        l10n.welcomeOfflineDescription,
      ),
      (
        const Key('welcome-feature-planning'),
        Icons.account_tree_outlined,
        l10n.welcomePlanningTitle,
        l10n.welcomePlanningDescription,
      ),
      (
        const Key('welcome-feature-backup'),
        Icons.import_export_outlined,
        l10n.welcomeBackupTitle,
        l10n.welcomeBackupDescription,
      ),
      (
        const Key('welcome-feature-mcp'),
        Icons.hub_outlined,
        l10n.welcomeMcpTitle,
        l10n.welcomeMcpDescription,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final cardWidth =
            isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final feature in features)
              SizedBox(
                width: cardWidth,
                child: _FeatureCard(
                  key: feature.$1,
                  icon: feature.$2,
                  title: feature.$3,
                  description: feature.$4,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            _Link(l10n.privacyPolicy, WelcomeScreen._links['privacy']!),
            _Link(l10n.termsOfService, WelcomeScreen._links['terms']!),
            _Link(l10n.welcomeGitHub, WelcomeScreen._links['github']!),
            _Link(l10n.welcomeGitHubIssues, WelcomeScreen._links['issues']!),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.welcomeSourceNotice,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.uri);
  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: uri,
      target: LinkTarget.blank,
      builder: (context, followLink) => TextButton(
        onPressed: followLink,
        child: Text(label),
      ),
    );
  }
}
