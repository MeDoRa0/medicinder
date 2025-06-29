import 'package:hive/hive.dart';
import '../../domain/entities/medication.dart';
import '../models/medication_model.dart';

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
        final updatedDoses = List<MedicationDose>.from(medication.doses);
        updatedDoses[doseIndex] = MedicationDose(
          time: updatedDoses[doseIndex].time,
          context: updatedDoses[doseIndex].context,
          taken: taken,
        );

        final updatedMedication = Medication(
          id: medication.id,
          name: medication.name,
          usage: medication.usage,
          dosage: medication.dosage,
          type: medication.type,
          timingType: medication.timingType,
          doses: updatedDoses,
          totalDays: medication.totalDays,
          startDate: medication.startDate,
        );

        await updateMedication(updatedMedication);
      }
    }
  }
}
