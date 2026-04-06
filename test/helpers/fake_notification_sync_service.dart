import 'package:flutter/widgets.dart';
import 'package:medicinder/core/services/sync/notification_sync_service.dart';
import 'package:medicinder/domain/entities/sync/notification_regen_summary.dart';

class FakeNotificationSyncService implements NotificationSyncService {
  @override
  Future<NotificationRegenerationSummary> regenerateNotifications({
    required List<String> changedMedicationIds,
    BuildContext? context,
  }) async {
    return const NotificationRegenerationSummary(
      medicationsProcessed: 0,
      notificationsScheduled: 0,
      notificationsCancelled: 0,
      failures: 0,
      permissionDenied: false,
      durationMs: 0,
    );
  }

  @override
  Future<void> cancelAllMedicationNotifications() async {}
}
