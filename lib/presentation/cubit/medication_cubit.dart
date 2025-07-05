// NOTE: Make sure to add flutter_bloc: ^8.1.2 to your pubspec.yaml dependencies.
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medication.dart';
import '../../domain/usecases/add_medication.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/update_dose_status.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/reset_daily_doses.dart';
import '../../core/services/awesome_notification_service.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'medication_state.dart';

class MedicationCubit extends Cubit<MedicationState> {
  final AddMedication _addMedication;
  final GetMedications _getMedications;
  final UpdateDoseStatus _updateDoseStatus;
  final DeleteMedication _deleteMedication;
  final ResetDailyDoses _resetDailyDoses;

  MedicationCubit({
    required AddMedication addMedication,
    required GetMedications getMedications,
    required UpdateDoseStatus updateDoseStatus,
    required DeleteMedication deleteMedication,
    required ResetDailyDoses resetDailyDoses,
  }) : _addMedication = addMedication,
       _getMedications = getMedications,
       _updateDoseStatus = updateDoseStatus,
       _deleteMedication = deleteMedication,
       _resetDailyDoses = resetDailyDoses,
       super(MedicationInitial()) {}

  Future<void> loadMedications() async {
    emit(MedicationLoading());
    try {
      final medications = await _getMedications();
      log('MedicationCubit: Loaded ${medications.length} medications');

      // No automatic cleanup since users can manually delete any medication
      emit(MedicationLoaded(medications));

      // Don't reschedule notifications here - only schedule when adding new medications
      // or when marking doses as taken to prevent duplicate scheduling
      log('MedicationCubit: Medications loaded successfully');
    } catch (e) {
      log('MedicationCubit: Error loading medications: $e');
      emit(MedicationError(e.toString()));
    }
  }

  /// Check if it's a new day and reset doses if needed
  /// This should only be called when the app is reopened, not during active use
  Future<void> checkDailyResetOnAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetDate = prefs.getString('last_dose_reset_date');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastResetDate != null) {
        final lastReset = DateTime.parse(lastResetDate);
        final lastResetDay = DateTime(
          lastReset.year,
          lastReset.month,
          lastReset.day,
        );

        // If it's a new day, reset doses
        if (!lastResetDay.isAtSameMomentAs(today)) {
          log(
            'MedicationCubit: New day detected on app open, resetting daily doses',
          );
          await _resetDailyDoses();
          await prefs.setString(
            'last_dose_reset_date',
            today.toIso8601String(),
          );
        }
      } else {
        // First time running, set today as reset date
        await prefs.setString('last_dose_reset_date', today.toIso8601String());
      }
    } catch (e) {
      log('MedicationCubit: Error checking daily reset: $e');
    }
  }

  Future<void> addNewMedication(Medication medication) async {
    try {
      log('MedicationCubit: Adding new medication: ${medication.name}');
      log(
        'MedicationCubit: Medication details - ID: ${medication.id}, Doses: ${medication.doses.length}, Timing: ${medication.timingType}',
      );

      await _addMedication(medication);
      log('MedicationCubit: Medication added successfully');

      // Schedule notification only for the next upcoming dose
      final now = DateTime.now();
      for (int i = 0; i < medication.doses.length; i++) {
        final dose = medication.doses[i];
        if (dose.time != null && dose.time!.isAfter(now) && !dose.taken) {
          await AwesomeNotificationService.scheduleMedicationReminder(
            id: medication.id.hashCode + i,
            medicationName: medication.name,
            scheduledTime: dose.time!,
            medicationId: medication.id,
            doseIndex: i,
          );
          break; // Only schedule the first upcoming dose
        }
      }
      log('MedicationCubit: Notifications scheduled successfully');

      await loadMedications();
    } catch (e) {
      log('MedicationCubit: Error adding medication: $e');
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> markDoseTaken(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {
    try {
      log(
        'MedicationCubit: Marking dose $doseIndex as \\${taken ? 'taken' : 'not taken'} for medication $medicationId',
      );
      await _updateDoseStatus(medicationId, doseIndex, taken);

      if (taken) {
        // Cancel the notification for this dose since it's been taken
        log('MedicationCubit: Cancelling notification for taken dose');
        await AwesomeNotificationService.cancelMedicationReminder(
          medicationId.hashCode + doseIndex,
        );

        // Schedule notification for the next upcoming dose
        final medications = await _getMedications();
        final med = medications.where((m) => m.id == medicationId).isNotEmpty
            ? medications.firstWhere((m) => m.id == medicationId)
            : null;
        if (med != null) {
          final now = DateTime.now();
          for (int i = 0; i < med.doses.length; i++) {
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

      // Check if the medication is now fully complete
      // (Do not delete immediately; let daily cleanup handle it)
      // final medications = await _getMedications();
      // final med = medications.where((m) => m.id == medicationId).isNotEmpty
      //     ? medications.firstWhere((m) => m.id == medicationId)
      //     : null;
      // if (med != null && med.isFullyComplete) {
      //   log('MedicationCubit: Medication is fully complete, deleting...');
      //   await _deleteMedication(medicationId);
      // }

      await loadMedications();
    } catch (e) {
      log('MedicationCubit: Error marking dose: $e');
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      log('MedicationCubit: Deleting medication: $medicationId');

      // Get the medication details before deleting for logging
      final medications = await _getMedications();
      final medicationToDelete = medications.firstWhere(
        (m) => m.id == medicationId,
        orElse: () => throw Exception('Medication not found: $medicationId'),
      );
      log(
        'MedicationCubit: Found medication to delete: ${medicationToDelete.name}',
      );
      log(
        'MedicationCubit: Medication canBeDeleted: ${medicationToDelete.canBeDeleted}',
      );
      log(
        'MedicationCubit: Medication isFullyComplete: ${medicationToDelete.isFullyComplete}',
      );

      // Efficiently cancel only scheduled notifications for this medication
      log(
        'MedicationCubit: Cancelling notifications for medication: $medicationId',
      );
      try {
        List<NotificationModel> scheduledNotifications =
            await AwesomeNotifications().listScheduledNotifications();
        int cancelledCount = 0;
        for (var notification in scheduledNotifications) {
          if (notification.content?.payload?['medicationId'] == medicationId) {
            await AwesomeNotifications().cancel(notification.content!.id!);
            cancelledCount++;
          }
        }
        log(
          'MedicationCubit: Cancelled $cancelledCount notifications for medication $medicationId',
        );
      } catch (e) {
        log('MedicationCubit: Error cancelling notifications: $e');
        // Continue with deletion even if notification cancellation fails
      }

      // Delete the medication
      log('MedicationCubit: Calling deleteMedication use case');
      await _deleteMedication(medicationId);
      log('MedicationCubit: Medication deleted successfully');

      // Reload medications
      log('MedicationCubit: Reloading medications after deletion');
      await loadMedications();
      log('MedicationCubit: Medications reloaded successfully');
    } catch (e) {
      log('MedicationCubit: Error deleting medication: $e');
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> cleanupCompletedMedications() async {
    try {
      final medications = await _getMedications();

      // Only clean up medications that are truly completed (treatment period ended AND all doses taken)
      final fullyCompletedMedications = medications
          .where(
            (m) => m.isFullyComplete,
          ) // Use isFullyComplete instead of canBeDeleted
          .toList();

      if (fullyCompletedMedications.isNotEmpty) {
        log(
          'MedicationCubit: Found ${fullyCompletedMedications.length} fully completed medications to clean up',
        );

        // Delete only fully completed medications
        for (final medication in fullyCompletedMedications) {
          await _deleteMedication(medication.id);
          // Cancel notifications for deleted medication
          for (int i = 0; i < medication.doses.length; i++) {
            await AwesomeNotificationService.cancelMedicationReminder(
              medication.id.hashCode + i,
            );
          }
        }

        // Reload medications after cleanup
        await loadMedications();
      } else {
        log('MedicationCubit: No fully completed medications to clean up');
      }
    } catch (e) {
      log('MedicationCubit: Error cleaning up medications: $e');
      emit(MedicationError(e.toString()));
    }
  }
}
