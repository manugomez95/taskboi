import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../connectivity/connectivity_provider.dart';
import '../sync/sync_provider.dart';

/// A small indicator widget that shows the current sync status
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final queueStatus = ref.watch(syncQueueStatusProvider);
    final l10n = AppLocalizations.of(context)!;

    // Show offline indicator
    if (!isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 14,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.offline,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }

    // Show active syncing or a recoverable pending state.
    return queueStatus.when(
      data: (status) {
        final count = status.pendingCount;
        if (count == 0) {
          return const SizedBox.shrink();
        }
        final hasExhaustedOperations = status.hasExhaustedOperations;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasExhaustedOperations
                ? Theme.of(context).colorScheme.tertiaryContainer
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasExhaustedOperations)
                Icon(
                  Icons.sync_problem,
                  size: 14,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                )
              else
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                hasExhaustedOperations
                    ? l10n.changesPendingSync(count)
                    : l10n.syncing(count),
                style: TextStyle(
                  fontSize: 12,
                  color: hasExhaustedOperations
                      ? Theme.of(context).colorScheme.onTertiaryContainer
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// A more detailed sync status widget for settings or debug views
class SyncStatusDetails extends ConsumerWidget {
  const SyncStatusDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.syncStatus,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(isOnline ? l10n.online : l10n.offline),
              ],
            ),
            const SizedBox(height: 8),
            pendingSyncCount.when(
              data: (count) => Row(
                children: [
                  Icon(
                    count == 0 ? Icons.check_circle : Icons.sync,
                    color: count == 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(count == 0
                      ? l10n.allChangesSynced
                      : l10n.changesPendingSync(count)),
                ],
              ),
              loading: () => Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.checking),
                ],
              ),
              error: (e, _) => Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.error(e.toString())),
                ],
              ),
            ),
            if (!isOnline) ...[
              const SizedBox(height: 8),
              Text(
                l10n.changesWillSyncWhenOnline,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
