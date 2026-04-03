// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncOperationModelAdapter extends TypeAdapter<SyncOperationModel> {
  @override
  final int typeId = 2;

  @override
  SyncOperationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncOperationModel(
      id: fields[0] as String,
      entityTypeIndex: fields[1] as int,
      entityId: fields[2] as String,
      typeIndex: fields[3] as int,
      createdAt: fields[4] as DateTime,
      lastAttemptAt: fields[5] as DateTime?,
      attemptCount: (fields[6] as int?) ?? 0,
      errorMessage: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperationModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityTypeIndex)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastAttemptAt)
      ..writeByte(6)
      ..write(obj.attemptCount)
      ..writeByte(7)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
