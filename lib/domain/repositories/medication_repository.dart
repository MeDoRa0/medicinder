import '../entities/medication.dart';

abstract class MedicationRepository {
  Future<void> addMedication(Medication medication);
  Future<List<Medication>> getMedications();
  Future<void> updateMedication(Medication medication);
  Future<void> deleteMedication(String id);
  Future<void> updateDoseStatus(String medicationId, int doseIndex, bool taken);
}
