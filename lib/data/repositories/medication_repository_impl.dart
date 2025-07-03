import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_local_data_source.dart';
import 'dart:developer';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationLocalDataSource localDataSource;

  MedicationRepositoryImpl(this.localDataSource);

  @override
  Future<List<Medication>> getMedications() async {
    return await localDataSource.getAllMedications();
  }

  @override
  Future<void> addMedication(Medication medication) async {
    await localDataSource.addMedication(medication);
  }

  @override
  Future<void> updateMedication(Medication medication) async {
    await localDataSource.updateMedication(medication);
  }

  @override
  Future<void> deleteMedication(String id) async {
    await localDataSource.deleteMedication(id);
  }

  @override
  Future<void> updateDoseStatus(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {
    await localDataSource.updateDoseStatus(medicationId, doseIndex, taken);
  }
}
