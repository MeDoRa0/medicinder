import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class AddMedication {
  final MedicationRepository repository;

  AddMedication(this.repository);

  Future<void> call(Medication medication) async {
    await repository.addMedication(medication);
  }
}
