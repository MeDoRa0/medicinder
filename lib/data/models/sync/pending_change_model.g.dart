// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_change_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingChangeModelAdapter extends TypeAdapter<PendingChangeModel> {
  @override
  final int typeId = 4;

  @override
  PendingChangeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingChangeModel(
      changeId: fields[0] as String,
      entityTypeIndex: fields[1] as int,
      entityId: fields[2] as String,
      operationIndex: fields[3] as int,
      queuedAt: fields[5] as DateTime,
      sourceUpdatedAt: fields[6] as DateTime,
      payload: (fields[4] as Map?)?.cast<String, dynamic>(),
      attemptCount: fields[7] as int,
      lastAttemptAt: fields[8] as DateTime?,
      statusIndex: fields[9] as int,
      userId: fields[10] as String?,
      errorMessage: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingChangeModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.changeId)
      ..writeByte(1)
      ..write(obj.entityTypeIndex)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.operationIndex)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.queuedAt)
      ..writeByte(6)
      ..write(obj.sourceUpdatedAt)
      ..writeByte(7)
      ..write(obj.attemptCount)
      ..writeByte(8)
      ..write(obj.lastAttemptAt)
      ..writeByte(9)
      ..write(obj.statusIndex)
      ..writeByte(10)
      ..write(obj.userId)
      ..writeByte(11)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingChangeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
