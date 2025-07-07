import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_local_data_source.dart';
import '../../core/error/failures.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationLocalDataSource localDataSource;

  MedicationRepositoryImpl(this.localDataSource);

  @override
  Future<List<Medication>> getMedications() async {
    try {
      return await localDataSource.getAllMedications();
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> addMedication(Medication medication) async {
    try {
      await localDataSource.addMedication(medication);
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> updateMedication(Medication medication) async {
    try {
      await localDataSource.updateMedication(medication);
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> deleteMedication(String id) async {
    try {
      await localDataSource.deleteMedication(id);
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> updateDoseStatus(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {
    try {
      await localDataSource.updateDoseStatus(medicationId, doseIndex, taken);
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> resetDailyDoses() async {
    try {
      await localDataSource.resetDailyDoses();
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }
}
