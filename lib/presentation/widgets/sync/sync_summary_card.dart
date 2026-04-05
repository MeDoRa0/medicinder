import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/sync/sync_types.dart';
import '../../../domain/entities/sync/user_sync_profile.dart';
import '../../../l10n/app_localizations.dart';

class SyncSummaryCard extends StatelessWidget {
  final UserSyncProfile profile;

  const SyncSummaryCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMd().add_Hm();

    final lastSuccess = profile.lastSuccessAt;
    final lastFailure = profile.lastFailureAt;

    String? statusText;
    if (profile.engineStatus == SyncCycleStatus.running) {
      statusText = l10n.syncRunning;
    } else if (lastSuccess != null &&
        (lastFailure == null || lastSuccess.isAfter(lastFailure))) {
      statusText = l10n.syncLastSuccess(dateFormat.format(lastSuccess));
    } else if (lastFailure != null) {
      statusText = l10n.syncLastFailure(dateFormat.format(lastFailure));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.syncStatusTitle, style: theme.textTheme.titleMedium),
            if (statusText != null) ...[
              const SizedBox(height: 8),
              Text(statusText),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  label: l10n.pushed,
                  count: profile.lastPushedCount,
                  icon: Icons.cloud_upload_outlined,
                ),
                _StatItem(
                  label: l10n.pulled,
                  count: profile.lastPulledCount,
                  icon: Icons.cloud_download_outlined,
                ),
                _StatItem(
                  label: l10n.failed,
                  count: profile.lastFailedCount,
                  icon: Icons.error_outline,
                  color: profile.lastFailedCount > 0 ? Colors.red : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? theme.hintColor),
        const SizedBox(height: 4),
        Text(
          '$count $label',
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
