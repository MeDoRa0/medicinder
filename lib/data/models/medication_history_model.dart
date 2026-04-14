import 'package:hive/hive.dart';
import '../../domain/entities/medication_history.dart';

part 'medication_history_model.g.dart';

@HiveType(typeId: 7)
class MedicationHistoryModel {
  @HiveField(0)
  final String medicineId;

  @HiveField(1)
  final String medicineName;

  @HiveField(2)
  final String dose;

  @HiveField(3)
  final DateTime takenAt;

  MedicationHistoryModel({
    required this.medicineId,
    required this.medicineName,
    required this.dose,
    required this.takenAt,
  });

  factory MedicationHistoryModel.fromEntity(MedicationHistory entity) {
    return MedicationHistoryModel(
      medicineId: entity.medicineId,
      medicineName: entity.medicineName,
      dose: entity.dose,
      takenAt: entity.takenAt,
    );
  }

  MedicationHistory toEntity() {
    return MedicationHistory(
      medicineId: medicineId,
      medicineName: medicineName,
      dose: dose,
      takenAt: takenAt,
    );
  }
}
