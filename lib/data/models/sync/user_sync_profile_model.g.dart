// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_sync_profile_model.dart';

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
      lastSuccessfulSyncAt: fields[6] as DateTime?,
      lastAttemptedSyncAt: fields[7] as DateTime?,
      lastSyncErrorCode: fields[8] as String?,
      statusViewStateIndex: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserSyncProfileModel obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.statusViewStateIndex);
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
