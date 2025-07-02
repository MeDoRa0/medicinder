// NOTE: Make sure to add flutter_bloc: ^8.1.2 to your pubspec.yaml dependencies.
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medication.dart';
import '../../domain/usecases/add_medication.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/update_dose_status.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../core/services/awesome_notification_service.dart';

import 'medication_state.dart';

class MedicationCubit extends Cubit<MedicationState> {
  final AddMedication _addMedication;
  final GetMedications _getMedications;
  final UpdateDoseStatus _updateDoseStatus;
  final DeleteMedication _deleteMedication;

  MedicationCubit({
    required AddMedication addMedication,
    required GetMedications getMedications,
    required UpdateDoseStatus updateDoseStatus,
    required DeleteMedication deleteMedication,
  }) : _addMedication = addMedication,
       _getMedications = getMedications,
       _updateDoseStatus = updateDoseStatus,
       _deleteMedication = deleteMedication,
       super(MedicationInitial()) {}

  Future<void> loadMedications() async {
    emit(MedicationLoading());
    try {
      final medications = await _getMedications();
      print('MedicationCubit: Loaded ${medications.length} medications');

      // No automatic cleanup since users can manually delete any medication
      emit(MedicationLoaded(medications));

      // Reschedule notifications for all active medications
      print(
        'MedicationCubit: Rescheduling notifications for active medications',
      );
      // await _notificationService.rescheduleAllActiveMedications(medications);
    } catch (e) {
      print('MedicationCubit: Error loading medications: $e');
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> addNewMedication(Medication medication) async {
    try {
      print('MedicationCubit: Adding new medication: ${medication.name}');
      print(
        'MedicationCubit: Medication details - ID: ${medication.id}, Doses: ${medication.doses.length}, Timing: ${medication.timingType}',
      );

      await _addMedication(medication);
      print('MedicationCubit: Medication added successfully');

      // Schedule notifications for the new medication
      print('MedicationCubit: Scheduling notifications for ${medication.name}');
      for (int i = 0; i < medication.doses.length; i++) {
        final dose = medication.doses[i];
        if (dose.time != null) {
          final scheduledTime = DateTime(
            medication.startDate.year,
            medication.startDate.month,
            medication.startDate.day,
            dose.time!.hour,
            dose.time!.minute,
          );
          await AwesomeNotificationService.scheduleMedicationReminder(
            id: medication.id.hashCode + i,
            medicationName: medication.name,
            scheduledTime: scheduledTime,
            medicationId: medication.id,
            doseIndex: i,
          );
        }
      }
      print('MedicationCubit: Notifications scheduled successfully');

      await loadMedications();
    } catch (e) {
      print('MedicationCubit: Error adding medication: $e');
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> markDoseTaken(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {
    try {
      print(
        'MedicationCubit: Marking dose $doseIndex as \\${taken ? 'taken' : 'not taken'} for medication $medicationId',
      );
      await _updateDoseStatus(medicationId, doseIndex, taken);

      if (taken) {
        // Cancel the notification for this dose since it's been taken
        print('MedicationCubit: Cancelling notification for taken dose');
        await AwesomeNotificationService.cancelMedicationReminder(
          medicationId.hashCode + doseIndex,
        );
      }

      // Check if the medication is now fully complete
      final medications = await _getMedications();
      final med = medications.where((m) => m.id == medicationId).isNotEmpty
          ? medications.firstWhere((m) => m.id == medicationId)
          : null;
      if (med != null && med.isFullyComplete) {
        print('MedicationCubit: Medication is fully complete, deleting...');
        await _deleteMedication(medicationId);
      }

      await loadMedications();
    } catch (e) {
      print('MedicationCubit: Error marking dose: $e');
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      print('MedicationCubit: Deleting medication: $medicationId');

      // Get the medication details before deleting for logging
      final medications = await _getMedications();
      final medicationToDelete = medications.firstWhere(
        (m) => m.id == medicationId,
        orElse: () => throw Exception('Medication not found: $medicationId'),
      );
      print(
        'MedicationCubit: Found medication to delete: ${medicationToDelete.name}',
      );
      print(
        'MedicationCubit: Medication canBeDeleted: ${medicationToDelete.canBeDeleted}',
      );
      print(
        'MedicationCubit: Medication isFullyComplete: ${medicationToDelete.isFullyComplete}',
      );

      // Cancel all notifications for this medication before deleting
      print(
        'MedicationCubit: Cancelling notifications for medication: $medicationId',
      );
      for (int i = 0; i < medicationToDelete.doses.length; i++) {
        await AwesomeNotificationService.cancelMedicationReminder(
          medicationId.hashCode + i,
        );
      }

      // Delete the medication
      print('MedicationCubit: Calling deleteMedication use case');
      await _deleteMedication(medicationId);
      print('MedicationCubit: Medication deleted successfully');

      // Reload medications
      print('MedicationCubit: Reloading medications after deletion');
      await loadMedications();
      print('MedicationCubit: Medications reloaded successfully');
    } catch (e) {
      print('MedicationCubit: Error deleting medication: $e');
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
        print(
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
        print('MedicationCubit: No fully completed medications to clean up');
      }
    } catch (e) {
      print('MedicationCubit: Error cleaning up medications: $e');
      emit(MedicationError(e.toString()));
    }
  }
}
