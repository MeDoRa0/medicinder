// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_cycle_state_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncCycleStateModelAdapter extends TypeAdapter<SyncCycleStateModel> {
  @override
  final int typeId = 6;

  @override
  SyncCycleStateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final triggerNameField = fields.containsKey(2) ? fields[2] : null;
    final statusNameField = fields.containsKey(5) ? fields[5] : null;

    String triggerName;
    if (triggerNameField is String) {
      triggerName = triggerNameField;
    } else if (triggerNameField is int &&
        triggerNameField >= 0 &&
        triggerNameField < SyncTrigger.values.length) {
      triggerName = SyncTrigger.values[triggerNameField].name;
    } else {
      triggerName = SyncTrigger.appStartup.name;
    }

    String statusName;
    if (statusNameField is String) {
      statusName = statusNameField;
    } else if (statusNameField is int &&
        statusNameField >= 0 &&
        statusNameField < SyncCycleStatus.values.length) {
      statusName = SyncCycleStatus.values[statusNameField].name;
    } else {
      statusName = SyncCycleStatus.idle.name;
    }

    return SyncCycleStateModel(
      cycleId: fields[0] as String,
      userId: fields[1] as String,
      triggerName: triggerName,
      startedAt: fields[3] as DateTime,
      completedAt: fields[4] as DateTime?,
      statusName: statusName,
      pushedCount: fields[6] as int,
      pulledCount: fields[7] as int,
      failedCount: fields[8] as int,
      failureClass: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncCycleStateModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.cycleId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.triggerName)
      ..writeByte(3)
      ..write(obj.startedAt)
      ..writeByte(4)
      ..write(obj.completedAt)
      ..writeByte(5)
      ..write(obj.statusName)
      ..writeByte(6)
      ..write(obj.pushedCount)
      ..writeByte(7)
      ..write(obj.pulledCount)
      ..writeByte(8)
      ..write(obj.failedCount)
      ..writeByte(9)
      ..write(obj.failureClass);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncCycleStateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
