import '../repositories/medication_repository.dart';

class DeleteMedication {
  final MedicationRepository repository;

  DeleteMedication(this.repository);

  Future<void> call(String medicationId) async {
    await repository.deleteMedication(medicationId);
  }
}
