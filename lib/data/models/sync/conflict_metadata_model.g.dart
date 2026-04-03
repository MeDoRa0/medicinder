// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conflict_metadata_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConflictMetadataModelAdapter extends TypeAdapter<ConflictMetadataModel> {
  @override
  final int typeId = 5;

  @override
  ConflictMetadataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConflictMetadataModel(
      entityTypeIndex: fields[0] as int,
      entityId: fields[1] as String,
      userId: fields[7] as String,
      localUpdatedAt: fields[2] as DateTime,
      remoteUpdatedAt: fields[3] as DateTime,
      winningSource: fields[4] as String,
      resolutionStrategyIndex: fields[5] as int,
      resolvedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ConflictMetadataModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.entityTypeIndex)
      ..writeByte(1)
      ..write(obj.entityId)
      ..writeByte(2)
      ..write(obj.localUpdatedAt)
      ..writeByte(3)
      ..write(obj.remoteUpdatedAt)
      ..writeByte(4)
      ..write(obj.winningSource)
      ..writeByte(5)
      ..write(obj.resolutionStrategyIndex)
      ..writeByte(6)
      ..write(obj.resolvedAt)
      ..writeByte(7)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConflictMetadataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
