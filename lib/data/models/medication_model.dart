import 'package:hive/hive.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/sync_metadata.dart';

part 'medication_model.g.dart';

@HiveType(typeId: 0)
class MedicationDoseModel extends HiveObject {
  @HiveField(0)
  DateTime? time;

  @HiveField(1)
  int? contextIndex; // MealContext index

  @HiveField(2)
  bool taken;

  @HiveField(3)
  DateTime? takenDate; // Date when the dose was taken

  @HiveField(4)
  int? offsetMinutes; // Minutes before/after meal (when context != null)

  MedicationDoseModel({
    this.time,
    this.contextIndex,
    this.taken = false,
    this.takenDate,
    this.offsetMinutes,
  });

  factory MedicationDoseModel.fromEntity(MedicationDose dose) =>
      MedicationDoseModel(
        time: dose.time,
        contextIndex: dose.context?.index,
        taken: dose.taken,
        takenDate: dose.takenDate,
        offsetMinutes: dose.offsetMinutes,
      );

  MedicationDose toEntity() => MedicationDose(
    time: time,
    context: contextIndex != null ? MealContext.values[contextIndex!] : null,
    taken: taken,
    takenDate: takenDate,
    offsetMinutes: offsetMinutes,
  );
}

@HiveType(typeId: 1)
class MedicationModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String usage;

  @HiveField(4)
  String dosage;

  @HiveField(5)
  int typeIndex; // MedicationType index

  @HiveField(6)
  int timingTypeIndex; // MedicationTimingType index

  @HiveField(7)
  List<MedicationDoseModel> doses;

  @HiveField(8)
  int totalDays;

  @HiveField(9)
  DateTime startDate;

  @HiveField(10)
  bool repeatForever;

  @HiveField(11)
  bool isDeleted;

  @HiveField(12)
  DateTime? deletedAt;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  @HiveField(15)
  DateTime? lastSyncedAt;

  @HiveField(16)
  int syncStatusIndex;

  @HiveField(17)
  int syncVersion;

  MedicationModel({
    required this.id,
    this.userId,
    required this.name,
    required this.usage,
    required this.dosage,
    required this.typeIndex,
    required this.timingTypeIndex,
    required this.doses,
    required this.totalDays,
    required this.startDate,
    this.repeatForever = false,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    this.syncStatusIndex = 0,
    this.syncVersion = 1,
  });

  factory MedicationModel.fromEntity(Medication med) => MedicationModel(
    id: med.id,
    userId: med.userId,
    name: med.name,
    usage: med.usage,
    dosage: med.dosage,
    typeIndex: med.type.index,
    timingTypeIndex: med.timingType.index,
    doses: med.doses.map(MedicationDoseModel.fromEntity).toList(),
    totalDays: med.totalDays,
    startDate: med.startDate,
    repeatForever: med.repeatForever,
    isDeleted: med.isDeleted,
    deletedAt: med.deletedAt ?? med.syncMetadata.deletedAt,
    createdAt: med.syncMetadata.createdAt,
    updatedAt: med.syncMetadata.updatedAt,
    lastSyncedAt: med.syncMetadata.lastSyncedAt,
    syncStatusIndex: med.syncMetadata.status.index,
    syncVersion: med.syncMetadata.syncVersion,
  );

  Medication toEntity() => Medication(
    id: id,
    userId: userId,
    name: name,
    usage: usage,
    dosage: dosage,
    type: MedicationType.values[typeIndex],
    timingType: MedicationTimingType.values[timingTypeIndex],
    doses: doses.map((d) => d.toEntity()).toList(),
    totalDays: totalDays,
    startDate: startDate,
    repeatForever: repeatForever,
    isDeleted: isDeleted,
    deletedAt: deletedAt,
    syncMetadata: SyncMetadata(
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSyncedAt: lastSyncedAt,
      deletedAt: deletedAt,
      status: SyncStatus.values[syncStatusIndex],
      syncVersion: syncVersion,
    ),
  );
}
