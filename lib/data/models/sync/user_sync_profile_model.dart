import 'package:hive/hive.dart';

import '../../../domain/entities/sync/sync_status_view_state.dart';
import '../../../domain/entities/sync/user_sync_profile.dart';

part 'user_sync_profile_model.g.dart';

@HiveType(typeId: 3)
class UserSyncProfileModel extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  List<String> providerIds;

  @HiveField(2)
  bool syncEnabled;

  @HiveField(3)
  bool workspaceReady;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  DateTime? lastSuccessfulSyncAt;

  @HiveField(7)
  DateTime? lastAttemptedSyncAt;

  @HiveField(8)
  String? lastSyncErrorCode;

  @HiveField(9)
  int statusViewStateIndex;

  UserSyncProfileModel({
    required this.userId,
    this.providerIds = const <String>[],
    required this.syncEnabled,
    this.workspaceReady = false,
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
      providerIds: profile.providerIds,
      syncEnabled: profile.syncEnabled,
      workspaceReady: profile.workspaceReady,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      lastSuccessfulSyncAt: profile.lastSuccessfulSyncAt,
      lastAttemptedSyncAt: profile.lastAttemptedSyncAt,
      lastSyncErrorCode: profile.lastSyncErrorCode,
      statusViewStateIndex: profile.statusViewState.index,
    );
  }

  UserSyncProfile toEntity() {
    final statusViewState =
        statusViewStateIndex >= 0 &&
                statusViewStateIndex < SyncStatusViewState.values.length
            ? SyncStatusViewState.values[statusViewStateIndex]
            : SyncStatusViewState.values.first;

    return UserSyncProfile(
      userId: userId,
      providerIds: providerIds,
      syncEnabled: syncEnabled,
      workspaceReady: workspaceReady,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt,
      lastAttemptedSyncAt: lastAttemptedSyncAt,
      lastSyncErrorCode: lastSyncErrorCode,
      statusViewState: statusViewState,
    );
  }
}
