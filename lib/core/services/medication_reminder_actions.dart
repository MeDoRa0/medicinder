import 'dart:developer';

import 'package:medicinder/core/di/injector.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/domain/usecases/get_medications.dart';
import 'package:medicinder/domain/usecases/update_dose_status.dart';

import 'awesome_notification_service.dart';

/// Persists "dose taken" and reschedules the next reminder without requiring
/// a [BuildContext] (notification actions while the app is backgrounded).
class MedicationReminderActions {
  MedicationReminderActions._();

  static Future<void> applyDoseTaken(
    String medicationId,
    int doseIndex,
  ) async {
    if (!sl.isRegistered<UpdateDoseStatus>()) {
      log('MedicationReminderActions: GetIt not initialized');
      return;
    }

    final updateDose = sl<UpdateDoseStatus>();
    final getMedications = sl<GetMedications>();

    await updateDose(medicationId, doseIndex, true);
    await AwesomeNotificationService.cancelMedicationReminder(
      medicationId.hashCode + doseIndex,
    );

    final medications = await getMedications();
    Medication? med;
    try {
      med = medications.firstWhere((m) => m.id == medicationId);
    } catch (_) {
      return;
    }

    final now = DateTime.now();
    for (var i = 0; i < med.doses.length; i++) {
      final dose = med.doses[i];
      if (dose.time != null && dose.time!.isAfter(now) && !dose.taken) {
        await AwesomeNotificationService.scheduleMedicationReminder(
          id: med.id.hashCode + i,
          medicationName: med.name,
          scheduledTime: dose.time!,
          medicationId: med.id,
          doseIndex: i,
        );
        break;
      }
    }
  }
}
