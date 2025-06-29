// NOTE: Make sure to add flutter_bloc: ^8.1.2 to your pubspec.yaml dependencies.
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medication.dart';
import '../../domain/usecases/add_medication.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/update_dose_status.dart';
import '../../domain/usecases/delete_medication.dart';

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
       super(MedicationInitial());

  Future<void> loadMedications() async {
    emit(MedicationLoading());
    try {
      final medications = await _getMedications();
      
      // Automatically clean up completed medications
      final completedMedications = medications.where((m) => !m.isActive).toList();
      if (completedMedications.isNotEmpty) {
        for (final medication in completedMedications) {
          await _deleteMedication(medication.id);
        }
        // Reload medications after cleanup
        final updatedMedications = await _getMedications();
        emit(MedicationLoaded(updatedMedications));
      } else {
        emit(MedicationLoaded(medications));
      }
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> addNewMedication(Medication medication) async {
    try {
      await _addMedication(medication);
      await loadMedications();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> markDoseTaken(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {
    try {
      await _updateDoseStatus(medicationId, doseIndex, taken);
      await loadMedications();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _deleteMedication(medicationId);
      await loadMedications();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> cleanupCompletedMedications() async {
    try {
      final medications = await _getMedications();
      final completedMedications = medications
          .where((m) => !m.isActive)
          .toList();

      // Delete all completed medications
      for (final medication in completedMedications) {
        await _deleteMedication(medication.id);
      }

      // Reload medications after cleanup
      if (completedMedications.isNotEmpty) {
        await loadMedications();
      }
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }
}
