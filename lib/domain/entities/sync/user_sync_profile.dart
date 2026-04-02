import 'sync_status_view_state.dart';

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
    );
  }
}
