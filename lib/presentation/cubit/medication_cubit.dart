// NOTE: Make sure to add flutter_bloc: ^8.1.2 to your pubspec.yaml dependencies.
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medication.dart';
import '../../domain/usecases/add_medication.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/update_medication.dart';
import '../../domain/usecases/update_dose_status.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/reset_daily_doses.dart';
import '../../core/services/awesome_notification_service.dart';
import '../../core/services/medication_reminder_actions.dart';
import '../../core/services/notification_optimizer.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import 'medication_state.dart';

class MedicationCubit extends Cubit<MedicationState> {
  final AddMedication _addMedication;
  final GetMedications _getMedications;
  final UpdateMedication _updateMedication;
  final UpdateDoseStatus _updateDoseStatus;
  final DeleteMedication _deleteMedication;
  final ResetDailyDoses _resetDailyDoses;

  MedicationCubit({
    required AddMedication addMedication,
    required GetMedications getMedications,
    required UpdateMedication updateMedication,
    required UpdateDoseStatus updateDoseStatus,
    required DeleteMedication deleteMedication,
    required ResetDailyDoses resetDailyDoses,
  }) : _addMedication = addMedication,
       _getMedications = getMedications,
       _updateMedication = updateMedication,
       _updateDoseStatus = updateDoseStatus,
       _deleteMedication = deleteMedication,
       _resetDailyDoses = resetDailyDoses,
       super(MedicationInitial());

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
      final context = navigatorKey.currentContext;
      String? title;
      String? body;
      String? doneLabel;
      String? remindLaterLabel;

      final l10n = (context != null && context.mounted) ? AppLocalizations.of(context) : null;
      if (l10n != null) {
        title = l10n.medicationReminder;
        body = l10n.timeToTakeMedication(medication.name);
        doneLabel = l10n.done;
        remindLaterLabel = l10n.remindMeLater;
      }

      for (int i = 0; i < medication.doses.length; i++) {
        final dose = medication.doses[i];
        if (dose.time != null && dose.time!.isAfter(now) && !dose.taken) {
          await AwesomeNotificationService.scheduleMedicationReminder(
            id: medication.id.hashCode + i,
            medicationName: medication.name,
            scheduledTime: dose.time!,
            medicationId: medication.id,
            doseIndex: i,
            title: title,
            body: body,
            doneLabel: doneLabel,
            remindLaterLabel: remindLaterLabel,
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

  Future<void> updateMedication(Medication medication) async {
    try {
      log('MedicationCubit: Updating medication: ${medication.id}');
      await _updateMedication(medication);

      // T012: Reschedule notifications immediately for offline edit support
      await NotificationOptimizer().cancelMedicationNotifications(
        medication.id,
      );
      await NotificationOptimizer().scheduleNextDoseNotification(
        medication,
        context: navigatorKey.currentContext,
      );

      await loadMedications();
      log('MedicationCubit: Medication updated successfully');
    } catch (e) {
      log('MedicationCubit: Error updating medication: $e');
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
      if (taken) {
        await MedicationReminderActions.applyDoseTaken(medicationId, doseIndex);
      } else {
        await _updateDoseStatus(medicationId, doseIndex, false);
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

      // Clean up medications that are truly completed OR whose strict time course has expired
      final fullyCompletedMedications = medications
          .where(
            (m) => !m.isDeleted && (!m.isActive || m.isFullyComplete),
          ) // Use isFullyComplete or inactive status to safely delete expired medications
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

  /// Recomputes dose times for all meal-based medications using current meal
  /// times from settings, then reschedules notifications. Call this when the
  /// user saves new meal times in settings.
  Future<void> recomputeMealBasedDoseTimesAndReschedule(
    BuildContext? context,
  ) async {
    try {
      final medications = await _getMedications();
      final prefs = await SharedPreferences.getInstance();

      final breakfast = _getTimeFromPrefs(prefs, 'breakfastTime', 8, 0);
      final lunch = _getTimeFromPrefs(prefs, 'lunchTime', 13, 0);
      final dinner = _getTimeFromPrefs(prefs, 'dinnerTime', 19, 0);

      final mealHourMin = <MealContext, ({int hour, int minute})>{
        MealContext.beforeBreakfast: breakfast,
        MealContext.afterBreakfast: breakfast,
        MealContext.beforeLunch: lunch,
        MealContext.afterLunch: lunch,
        MealContext.beforeDinner: dinner,
        MealContext.afterDinner: dinner,
      };

      for (final medication in medications) {
        if (medication.timingType != MedicationTimingType.contextBased) {
          continue;
        }
        final hasMealBasedDoses = medication.doses.any(
          (d) => d.context != null && d.time != null,
        );
        if (!hasMealBasedDoses) continue;

        final updatedDoses = <MedicationDose>[];
        for (final dose in medication.doses) {
          if (dose.context == null || dose.time == null) {
            updatedDoses.add(dose);
            continue;
          }
          final meal = mealHourMin[dose.context!]!;
          final offset = dose.offsetMinutes ?? 15;
          final baseTime = DateTime(
            dose.time!.year,
            dose.time!.month,
            dose.time!.day,
            meal.hour,
            meal.minute,
          );
          final bool isBefore = dose.context!.name.startsWith('before');
          final DateTime newTime = isBefore
              ? baseTime.subtract(Duration(minutes: offset))
              : baseTime.add(Duration(minutes: offset));

          updatedDoses.add(
            MedicationDose(
              time: newTime,
              context: dose.context,
              offsetMinutes: dose.offsetMinutes,
              taken: dose.taken,
              takenDate: dose.takenDate,
            ),
          );
        }

        final updated = medication.copyWith(doses: updatedDoses);
        await _updateMedication(updated);
      }

      final updatedMedications = await _getMedications();
      emit(MedicationLoaded(updatedMedications));

      await NotificationOptimizer().clearAllNotifications();
      await NotificationOptimizer().batchScheduleNotifications(
        updatedMedications,
        context: (context != null && context.mounted) ? context : null,
      );
      log(
        'MedicationCubit: Recomputed meal-based dose times and rescheduled notifications',
      );
    } catch (e) {
      log('MedicationCubit: Error recomputing meal-based dose times: $e');
      rethrow;
    }
  }

  static ({int hour, int minute}) _getTimeFromPrefs(
    SharedPreferences prefs,
    String key,
    int defaultHour,
    int defaultMinute,
  ) {
    final s = prefs.getString(key);
    if (s == null) return (hour: defaultHour, minute: defaultMinute);
    final parts = s.split(':');
    if (parts.length < 2) return (hour: defaultHour, minute: defaultMinute);
    final hour = int.tryParse(parts[0]) ?? defaultHour;
    final minute = int.tryParse(parts[1]) ?? defaultMinute;
    return (hour: hour, minute: minute);
  }
}
