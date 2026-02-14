// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationDoseModelAdapter extends TypeAdapter<MedicationDoseModel> {
  @override
  final int typeId = 0;

  @override
  MedicationDoseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationDoseModel(
      time: fields[0] as DateTime?,
      contextIndex: fields[1] as int?,
      taken: fields[2] as bool,
      takenDate: fields[3] as DateTime?,
      offsetMinutes: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationDoseModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.contextIndex)
      ..writeByte(2)
      ..write(obj.taken)
      ..writeByte(3)
      ..write(obj.takenDate)
      ..writeByte(4)
      ..write(obj.offsetMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationDoseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedicationModelAdapter extends TypeAdapter<MedicationModel> {
  @override
  final int typeId = 1;

  @override
  MedicationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationModel(
      id: fields[0] as String,
      name: fields[1] as String,
      usage: fields[2] as String,
      dosage: fields[3] as String,
      typeIndex: fields[4] as int,
      timingTypeIndex: fields[5] as int,
      doses: (fields[6] as List).cast<MedicationDoseModel>(),
      totalDays: fields[7] as int,
      startDate: fields[8] as DateTime,
      repeatForever: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.usage)
      ..writeByte(3)
      ..write(obj.dosage)
      ..writeByte(4)
      ..write(obj.typeIndex)
      ..writeByte(5)
      ..write(obj.timingTypeIndex)
      ..writeByte(6)
      ..write(obj.doses)
      ..writeByte(7)
      ..write(obj.totalDays)
      ..writeByte(8)
      ..write(obj.startDate)
      ..writeByte(9)
      ..write(obj.repeatForever);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
