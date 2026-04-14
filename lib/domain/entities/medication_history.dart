import 'package:equatable/equatable.dart';

class MedicationHistory extends Equatable {
  final String medicineId;
  final String medicineName;
  final String dose;
  final DateTime takenAt;

  const MedicationHistory({
    required this.medicineId,
    required this.medicineName,
    required this.dose,
    required this.takenAt,
  });

  @override
  List<Object?> get props => [medicineId, medicineName, dose, takenAt];
}
