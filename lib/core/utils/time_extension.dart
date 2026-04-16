import 'package:flutter/material.dart';
import 'package:medicinder/l10n/app_localizations.dart';

extension RelativeTimeExtension on DateTime {
  /// Formats the DateTime as a relative time string (e.g., "Just now", "5 m ago", "2 h ago").
  /// The [context] is required to access the localized strings.
  String toRelativeTime(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inHours < 1) {
      return l10n.timeAgoMinutes(difference.inMinutes);
    } else {
      return l10n.timeAgoHours(difference.inHours);
    }
  }
}
