// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_sync_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSyncProfileModelAdapter extends TypeAdapter<UserSyncProfileModel> {
  @override
  final int typeId = 3;

  @override
  UserSyncProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSyncProfileModel(
      userId: fields[0] as String,
      providerIds: (fields[1] as List).cast<String>(),
      syncEnabled: fields[2] as bool,
      workspaceReady: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      statusViewStateIndex: fields[9] as int,
      lastSuccessfulSyncAt: fields[6] as DateTime?,
      lastAttemptedSyncAt: fields[7] as DateTime?,
      lastSyncErrorCode: fields[8] as String?,
      engineStatusIndex: fields[10] as int,
      lastTriggerIndex: fields[11] as int?,
      lastStartedAt: fields[12] as DateTime?,
      lastCompletedAt: fields[13] as DateTime?,
      lastSuccessAt: fields[14] as DateTime?,
      lastFailureAt: fields[15] as DateTime?,
      message: fields[16] as String?,
      lastPushedCount: fields[17] as int,
      lastPulledCount: fields[18] as int,
      lastFailedCount: fields[19] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserSyncProfileModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.providerIds)
      ..writeByte(2)
      ..write(obj.syncEnabled)
      ..writeByte(3)
      ..write(obj.workspaceReady)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.lastSuccessfulSyncAt)
      ..writeByte(7)
      ..write(obj.lastAttemptedSyncAt)
      ..writeByte(8)
      ..write(obj.lastSyncErrorCode)
      ..writeByte(9)
      ..write(obj.statusViewStateIndex)
      ..writeByte(10)
      ..write(obj.engineStatusIndex)
      ..writeByte(11)
      ..write(obj.lastTriggerIndex)
      ..writeByte(12)
      ..write(obj.lastStartedAt)
      ..writeByte(13)
      ..write(obj.lastCompletedAt)
      ..writeByte(14)
      ..write(obj.lastSuccessAt)
      ..writeByte(15)
      ..write(obj.lastFailureAt)
      ..writeByte(16)
      ..write(obj.message)
      ..writeByte(17)
      ..write(obj.lastPushedCount)
      ..writeByte(18)
      ..write(obj.lastPulledCount)
      ..writeByte(19)
      ..write(obj.lastFailedCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSyncProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
