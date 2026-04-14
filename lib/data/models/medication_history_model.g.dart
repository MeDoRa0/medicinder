// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationHistoryModelAdapter
    extends TypeAdapter<MedicationHistoryModel> {
  @override
  final int typeId = 7;

  @override
  MedicationHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationHistoryModel(
      medicineId: fields[0] as String,
      medicineName: fields[1] as String,
      dose: fields[2] as String,
      takenAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationHistoryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.medicineId)
      ..writeByte(1)
      ..write(obj.medicineName)
      ..writeByte(2)
      ..write(obj.dose)
      ..writeByte(3)
      ..write(obj.takenAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
