import 'package:hive/hive.dart';

import '../../../domain/entities/sync/sync_status_view_state.dart';
import '../../../domain/entities/sync/user_sync_profile.dart';

part 'user_sync_profile_model.g.dart';

@HiveType(typeId: 3)
class UserSyncProfileModel extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  bool syncEnabled;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  DateTime? lastSuccessfulSyncAt;

  @HiveField(5)
  DateTime? lastAttemptedSyncAt;

  @HiveField(6)
  String? lastSyncErrorCode;

  @HiveField(7)
  int statusViewStateIndex;

  UserSyncProfileModel({
    required this.userId,
    required this.syncEnabled,
    required this.createdAt,
    required this.updatedAt,
    required this.statusViewStateIndex,
    this.lastSuccessfulSyncAt,
    this.lastAttemptedSyncAt,
    this.lastSyncErrorCode,
  });

  factory UserSyncProfileModel.fromEntity(UserSyncProfile profile) {
    return UserSyncProfileModel(
      userId: profile.userId,
      syncEnabled: profile.syncEnabled,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      lastSuccessfulSyncAt: profile.lastSuccessfulSyncAt,
      lastAttemptedSyncAt: profile.lastAttemptedSyncAt,
      lastSyncErrorCode: profile.lastSyncErrorCode,
      statusViewStateIndex: profile.statusViewState.index,
    );
  }

  UserSyncProfile toEntity() {
    return UserSyncProfile(
      userId: userId,
      syncEnabled: syncEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt,
      lastAttemptedSyncAt: lastAttemptedSyncAt,
      lastSyncErrorCode: lastSyncErrorCode,
      statusViewState: SyncStatusViewState.values[statusViewStateIndex],
    );
  }
}
