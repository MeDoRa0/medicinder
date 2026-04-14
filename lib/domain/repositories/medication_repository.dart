import '../entities/medication.dart';
import '../entities/medication_history.dart';

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
  Future<void> assignLocalMedicationsToUser(String userId);

  /// Retrieves records from the last 24 hours, sorted from most recent to oldest.
  Future<List<MedicationHistory>> getLastTakenMedicines();

  /// Retrieves records from the last 24 hours as a reactive stream.
  Stream<List<MedicationHistory>> getLastTakenMedicinesStream();
}
