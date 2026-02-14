import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class UpdateMedication {
  final MedicationRepository repository;

  UpdateMedication(this.repository);

  Future<void> call(Medication medication) async {
    await repository.updateMedication(medication);
  }
}
