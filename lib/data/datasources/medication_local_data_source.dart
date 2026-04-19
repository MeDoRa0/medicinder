import 'package:hive/hive.dart';
import '../../domain/entities/medication.dart';
import '../models/medication_model.dart';
import 'dart:developer';

class MedicationLocalDataSource {
  final Box<MedicationModel> _box;

  MedicationLocalDataSource(this._box);

  // CRUD Operations
  Future<List<Medication>> getAllMedications({
    bool includeDeleted = false,
  }) async {
    try {
      final models = _box.values.toList();
      final medications = models.map((model) => model.toEntity()).toList();
      if (includeDeleted) {
        return medications;
      }
      return medications.where((medication) => !medication.isDeleted).toList();
    } catch (e) {
      // If there's an error reading medications, clear the box and return empty list
      await _box.clear();
      return [];
    }
  }

  Future<Medication?> getMedicationById(
    String id, {
    bool includeDeleted = false,
  }) async {
    final model = _box.get(id);
    final medication = model?.toEntity();
    if (medication == null) {
      return null;
    }
    if (!includeDeleted && medication.isDeleted) {
      return null;
    }
    return medication;
  }

  Future<void> addMedication(Medication medication) async {
    final model = MedicationModel.fromEntity(medication);
    await _box.put(medication.id, model);
  }

  Future<void> updateMedication(Medication medication) async {
    final model = MedicationModel.fromEntity(medication);
    await _box.put(medication.id, model);
  }

  Future<void> deleteMedication(String id) async {
    final medication = await getMedicationById(id, includeDeleted: true);
    if (medication == null) {
      return;
    }
    await updateMedication(medication.markDeleted(DateTime.now()));
  }

  Future<void> updateDoseStatus(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {
    final model = _box.get(medicationId);
    if (model != null) {
      final medication = model.toEntity();
      if (doseIndex < medication.doses.length) {
        Medication updatedMedication;

        if (taken) {
          // Mark dose as taken for today
          updatedMedication = medication.markDoseTaken(doseIndex);
        } else {
          // Mark dose as not taken
          final updatedDoses = List<MedicationDose>.from(medication.doses);
          updatedDoses[doseIndex] = MedicationDose(
            time: updatedDoses[doseIndex].time,
            context: updatedDoses[doseIndex].context,
            offsetMinutes: updatedDoses[doseIndex].offsetMinutes,
            taken: false,
            takenDate: null,
          );

          updatedMedication = medication.copyWith(doses: updatedDoses);
        }

        await updateMedication(updatedMedication);
      }
    }
  }

  /// Reset daily doses for all medications (call this daily)
  Future<void> resetDailyDoses() async {
    try {
      final models = _box.values.toList();
      for (final model in models) {
        final medication = model.toEntity();
        if (!medication.isDeleted && medication.isActive) {
          final resetMedication = medication.resetDailyDoses();
          await updateMedication(resetMedication);
        }
      }
    } catch (e) {
      log('Error resetting daily doses: $e');
    }
  }

  Future<void> purgeMedication(String id) async {
    await _box.delete(id);
  }
}
