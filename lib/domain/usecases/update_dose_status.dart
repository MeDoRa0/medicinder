import '../repositories/medication_repository.dart';

class UpdateDoseStatus {
  final MedicationRepository repository;

  UpdateDoseStatus(this.repository);

  Future<void> call(String medicationId, int doseIndex, bool taken) async {
    await repository.updateDoseStatus(medicationId, doseIndex, taken);
  }
}
