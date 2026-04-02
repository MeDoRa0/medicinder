import '../entities/medication.dart';

abstract class MedicationRepository {
  Future<void> addMedication(Medication medication);
  Future<List<Medication>> getMedications({bool includeDeleted = false});
  Future<Medication?> getMedicationById(
    String id, {
    bool includeDeleted = false,
  });
  Future<void> updateMedication(Medication medication);
  Future<void> deleteMedication(String id);
  Future<void> updateDoseStatus(String medicationId, int doseIndex, bool taken);
  Future<void> resetDailyDoses();
  Future<void> saveSyncedMedication(Medication medication);
  Future<void> purgeMedication(String id);
}
