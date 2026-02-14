import 'package:hive/hive.dart';
import '../../domain/entities/medication.dart';
import '../models/medication_model.dart';
import 'dart:developer';

class MedicationLocalDataSource {
  final Box<MedicationModel> _box;

  MedicationLocalDataSource(this._box);

  // CRUD Operations
  Future<List<Medication>> getAllMedications() async {
    try {
      final models = _box.values.toList();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      // If there's an error reading medications, clear the box and return empty list
      await _box.clear();
      return [];
    }
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
    await _box.delete(id);
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

          updatedMedication = Medication(
            id: medication.id,
            name: medication.name,
            usage: medication.usage,
            dosage: medication.dosage,
            type: medication.type,
            timingType: medication.timingType,
            doses: updatedDoses,
            totalDays: medication.totalDays,
            startDate: medication.startDate,
            repeatForever: medication.repeatForever,
          );
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
        final resetMedication = medication.resetDailyDoses();
        await updateMedication(resetMedication);
      }
    } catch (e) {
      log('Error resetting daily doses: $e');
    }
  }
}
