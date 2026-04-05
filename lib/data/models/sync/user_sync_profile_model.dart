import 'package:hive/hive.dart';

import '../../../domain/entities/sync/sync_status_view_state.dart';
import '../../../domain/entities/sync/sync_types.dart';
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

  @HiveField(10)
  int engineStatusIndex;

  @HiveField(11)
  int? lastTriggerIndex;

  @HiveField(12)
  DateTime? lastStartedAt;

  @HiveField(13)
  DateTime? lastCompletedAt;

  @HiveField(14)
  DateTime? lastSuccessAt;

  @HiveField(15)
  DateTime? lastFailureAt;

  @HiveField(16)
  String? message;

  @HiveField(17)
  int lastPushedCount;

  @HiveField(18)
  int lastPulledCount;

  @HiveField(19)
  int lastFailedCount;

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
    this.engineStatusIndex = 0,
    this.lastTriggerIndex,
    this.lastStartedAt,
    this.lastCompletedAt,
    this.lastSuccessAt,
    this.lastFailureAt,
    this.message,
    this.lastPushedCount = 0,
    this.lastPulledCount = 0,
    this.lastFailedCount = 0,
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
      engineStatusIndex: profile.engineStatus.index,
      lastTriggerIndex: profile.lastTrigger?.index,
      lastStartedAt: profile.lastStartedAt,
      lastCompletedAt: profile.lastCompletedAt,
      lastSuccessAt: profile.lastSuccessAt,
      lastFailureAt: profile.lastFailureAt,
      message: profile.message,
      lastPushedCount: profile.lastPushedCount,
      lastPulledCount: profile.lastPulledCount,
      lastFailedCount: profile.lastFailedCount,
    );
  }

  UserSyncProfile toEntity() {
    final statusViewState =
        statusViewStateIndex >= 0 &&
            statusViewStateIndex < SyncStatusViewState.values.length
        ? SyncStatusViewState.values[statusViewStateIndex]
        : SyncStatusViewState.values.first;

    final engineStatus =
        engineStatusIndex >= 0 &&
            engineStatusIndex < SyncCycleStatus.values.length
        ? SyncCycleStatus.values[engineStatusIndex]
        : SyncCycleStatus.idle;

    final lastTrigger =
        lastTriggerIndex != null &&
            lastTriggerIndex! >= 0 &&
            lastTriggerIndex! < SyncTrigger.values.length
        ? SyncTrigger.values[lastTriggerIndex!]
        : null;

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
      engineStatus: engineStatus,
      lastTrigger: lastTrigger,
      lastStartedAt: lastStartedAt,
      lastCompletedAt: lastCompletedAt,
      lastSuccessAt: lastSuccessAt,
      lastFailureAt: lastFailureAt,
      message: message,
      lastPushedCount: lastPushedCount,
      lastPulledCount: lastPulledCount,
      lastFailedCount: lastFailedCount,
    );
  }
}
