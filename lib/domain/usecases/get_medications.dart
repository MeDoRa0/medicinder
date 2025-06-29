import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class GetMedications {
  final MedicationRepository repository;

  GetMedications(this.repository);

  Future<List<Medication>> call() async {
    return await repository.getMedications();
  }
}
