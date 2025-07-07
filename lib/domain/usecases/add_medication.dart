import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class AddMedication {
  final MedicationRepository repository;

  AddMedication(this.repository);

  Future<void> call(Medication? medication) async {
    if (medication == null) {
      throw ArgumentError('Medication cannot be null');
    }
    await repository.addMedication(medication);
  }
}
