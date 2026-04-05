import 'sync_status_view_state.dart';
import 'sync_types.dart';

class UserSyncProfile {
  final String userId;
  final List<String> providerIds;
  final bool syncEnabled;
  final bool workspaceReady;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastAttemptedSyncAt;
  final String? lastSyncErrorCode;
  final SyncStatusViewState statusViewState;

  // Added lifecycle fields
  final SyncCycleStatus engineStatus;
  final SyncTrigger? lastTrigger;
  final DateTime? lastStartedAt;
  final DateTime? lastCompletedAt;
  final DateTime? lastSuccessAt;
  final DateTime? lastFailureAt;
  final String? message;
  final int lastPushedCount;
  final int lastPulledCount;
  final int lastFailedCount;

  const UserSyncProfile({
    required this.userId,
    this.providerIds = const <String>[],
    required this.syncEnabled,
    this.workspaceReady = false,
    required this.createdAt,
    required this.updatedAt,
    required this.statusViewState,
    this.lastSuccessfulSyncAt,
    this.lastAttemptedSyncAt,
    this.lastSyncErrorCode,
    this.engineStatus = SyncCycleStatus.idle,
    this.lastTrigger,
    this.lastStartedAt,
    this.lastCompletedAt,
    this.lastSuccessAt,
    this.lastFailureAt,
    this.message,
    this.lastPushedCount = 0,
    this.lastPulledCount = 0,
    this.lastFailedCount = 0,
  });

  UserSyncProfile copyWith({
    String? userId,
    List<String>? providerIds,
    bool? syncEnabled,
    bool? workspaceReady,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSuccessfulSyncAt,
    bool clearLastSuccessfulSyncAt = false,
    DateTime? lastAttemptedSyncAt,
    bool clearLastAttemptedSyncAt = false,
    String? lastSyncErrorCode,
    bool clearLastSyncErrorCode = false,
    SyncStatusViewState? statusViewState,
    SyncCycleStatus? engineStatus,
    SyncTrigger? lastTrigger,
    bool clearLastTrigger = false,
    DateTime? lastStartedAt,
    bool clearLastStartedAt = false,
    DateTime? lastCompletedAt,
    bool clearLastCompletedAt = false,
    DateTime? lastSuccessAt,
    bool clearLastSuccessAt = false,
    DateTime? lastFailureAt,
    bool clearLastFailureAt = false,
    String? message,
    bool clearMessage = false,
    int? lastPushedCount,
    int? lastPulledCount,
    int? lastFailedCount,
  }) {
    return UserSyncProfile(
      userId: userId ?? this.userId,
      providerIds: providerIds ?? this.providerIds,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      workspaceReady: workspaceReady ?? this.workspaceReady,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSuccessfulSyncAt: clearLastSuccessfulSyncAt
          ? null
          : (lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt),
      lastAttemptedSyncAt: clearLastAttemptedSyncAt
          ? null
          : (lastAttemptedSyncAt ?? this.lastAttemptedSyncAt),
      lastSyncErrorCode: clearLastSyncErrorCode
          ? null
          : (lastSyncErrorCode ?? this.lastSyncErrorCode),
      statusViewState: statusViewState ?? this.statusViewState,
      engineStatus: engineStatus ?? this.engineStatus,
      lastTrigger: clearLastTrigger ? null : (lastTrigger ?? this.lastTrigger),
      lastStartedAt: clearLastStartedAt
          ? null
          : (lastStartedAt ?? this.lastStartedAt),
      lastCompletedAt: clearLastCompletedAt
          ? null
          : (lastCompletedAt ?? this.lastCompletedAt),
      lastSuccessAt: clearLastSuccessAt
          ? null
          : (lastSuccessAt ?? this.lastSuccessAt),
      lastFailureAt: clearLastFailureAt
          ? null
          : (lastFailureAt ?? this.lastFailureAt),
      message: clearMessage ? null : (message ?? this.message),
      lastPushedCount: lastPushedCount ?? this.lastPushedCount,
      lastPulledCount: lastPulledCount ?? this.lastPulledCount,
      lastFailedCount: lastFailedCount ?? this.lastFailedCount,
    );
  }
}
