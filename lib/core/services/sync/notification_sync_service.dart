import 'dart:developer';

import 'package:flutter/widgets.dart';

import '../../../domain/entities/sync/notification_regen_summary.dart';
import '../../../domain/repositories/medication_repository.dart';
import '../notification_optimizer.dart';
import 'sync_diagnostics.dart';

class NotificationSyncService {
  final MedicationRepository _medicationRepository;
  final NotificationOptimizer _notificationOptimizer;
  final SyncDiagnostics _syncDiagnostics;

  NotificationSyncService({
    required MedicationRepository medicationRepository,
    required NotificationOptimizer notificationOptimizer,
    required SyncDiagnostics syncDiagnostics,
  })  : _medicationRepository = medicationRepository,
        _notificationOptimizer = notificationOptimizer,
        _syncDiagnostics = syncDiagnostics;

  Future<NotificationRegenerationSummary> regenerateNotifications({
    required List<String> changedMedicationIds,
    BuildContext? context,
  }) async {
    final startTime = DateTime.now();
    int scheduled = 0;
    int cancelled = 0;
    int failures = 0;
    bool permissionDenied = false;

    if (!await _notificationOptimizer.isNotificationAllowed()) {
      permissionDenied = true;
      log('NotificationRegeneration: Permission denied', name: 'sync');
    }

    for (final medicationId in changedMedicationIds) {
      try {
        final medication = await _medicationRepository.getMedicationById(
          medicationId,
          includeDeleted: true,
        );

        if (medication == null) {
          final count = await _notificationOptimizer.cancelMedicationNotifications(medicationId);
          cancelled += count;
          continue;
        }

        if (medication.isDeleted) {
          final count = await _notificationOptimizer.cancelMedicationNotifications(medicationId);
          cancelled += count;
          continue;
        }

        if (medication.doses.isEmpty) {
          log('Skipping notification regeneration for medication $medicationId: no doses', name: 'sync');
          failures++;
          continue;
        }

        final count = await _notificationOptimizer.cancelMedicationNotifications(medicationId);
        cancelled += count;

        if (!permissionDenied) {
          final currentContext = (context != null && context.mounted) ? context : null;
          await _notificationOptimizer.scheduleNextDoseNotification(
            medication,
            context: currentContext,
          );
          scheduled++;
        }
      } catch (e, stackTrace) {
        log('Error regenerating notifications for $medicationId: $e', error: e, stackTrace: stackTrace, name: 'sync');
        failures++;
      }
    }

    final durationMs = DateTime.now().difference(startTime).inMilliseconds;

    final summary = NotificationRegenerationSummary(
      medicationsProcessed: changedMedicationIds.length,
      notificationsScheduled: scheduled,
      notificationsCancelled: cancelled,
      failures: failures,
      permissionDenied: permissionDenied,
      durationMs: durationMs,
    );

    _syncDiagnostics.logNotificationRegenEvent(summary);
    return summary;
  }

  Future<void> cancelAllMedicationNotifications() async {
    await _notificationOptimizer.clearAllNotifications();
    log('All medication notifications cancelled (sign-out)', name: 'sync');
  }
}
