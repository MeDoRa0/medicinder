import '../repositories/medication_repository.dart';

class ResetDailyDoses {
  final MedicationRepository repository;

  ResetDailyDoses(this.repository);

  Future<void> call() async {
    await repository.resetDailyDoses();
  }
}
