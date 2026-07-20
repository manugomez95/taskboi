import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/settings/data/services/theme_cache_service.dart';
import '../../l10n/generated/app_localizations.dart';

/// A banner that reminds web users about the Android app.
/// Only shows on web and can be dismissed.
class AndroidAppBanner extends StatefulWidget {
  const AndroidAppBanner({super.key});

  @override
  State<AndroidAppBanner> createState() => _AndroidAppBannerState();
}

class _AndroidAppBannerState extends State<AndroidAppBanner> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _dismissed = ThemeCacheService.isAndroidBannerDismissed();
  }

  void _dismiss() {
    ThemeCacheService.dismissAndroidBanner();
    setState(() {
      _dismissed = true;
    });
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.manugo.taskboi',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show on web and if not dismissed
    if (!kIsWeb || _dismissed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(
            Icons.android,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.androidAppAvailable,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _openPlayStore,
            child: Text(l10n.getTheApp),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _dismiss,
            tooltip: l10n.dismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}
