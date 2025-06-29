import 'package:hive/hive.dart';
import '../../domain/entities/medication.dart';

part 'medication_model.g.dart';

@HiveType(typeId: 0)
class MedicationDoseModel extends HiveObject {
  @HiveField(0)
  DateTime? time;

  @HiveField(1)
  int? contextIndex; // MealContext index

  @HiveField(2)
  bool taken;

  MedicationDoseModel({this.time, this.contextIndex, this.taken = false});

  factory MedicationDoseModel.fromEntity(MedicationDose dose) =>
      MedicationDoseModel(
        time: dose.time,
        contextIndex: dose.context?.index,
        taken: dose.taken,
      );

  MedicationDose toEntity() => MedicationDose(
    time: time,
    context: contextIndex != null ? MealContext.values[contextIndex!] : null,
    taken: taken,
  );
}

@HiveType(typeId: 1)
class MedicationModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String usage;

  @HiveField(3)
  String dosage;

  @HiveField(4)
  int typeIndex; // MedicationType index

  @HiveField(5)
  int timingTypeIndex; // MedicationTimingType index

  @HiveField(6)
  List<MedicationDoseModel> doses;

  @HiveField(7)
  int totalDays;

  @HiveField(8)
  DateTime startDate;

  MedicationModel({
    required this.id,
    required this.name,
    required this.usage,
    required this.dosage,
    required this.typeIndex,
    required this.timingTypeIndex,
    required this.doses,
    required this.totalDays,
    required this.startDate,
  });

  factory MedicationModel.fromEntity(Medication med) => MedicationModel(
    id: med.id,
    name: med.name,
    usage: med.usage,
    dosage: med.dosage,
    typeIndex: med.type.index,
    timingTypeIndex: med.timingType.index,
    doses: med.doses.map(MedicationDoseModel.fromEntity).toList(),
    totalDays: med.totalDays,
    startDate: med.startDate,
  );

  Medication toEntity() => Medication(
    id: id,
    name: name,
    usage: usage,
    dosage: dosage,
    type: MedicationType.values[typeIndex],
    timingType: MedicationTimingType.values[timingTypeIndex],
    doses: doses.map((d) => d.toEntity()).toList(),
    totalDays: totalDays,
    startDate: startDate,
  );
}
