import 'sync_status_view_state.dart';

class UserSyncProfile {
  final String userId;
  final bool syncEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastAttemptedSyncAt;
  final String? lastSyncErrorCode;
  final SyncStatusViewState statusViewState;

  const UserSyncProfile({
    required this.userId,
    required this.syncEnabled,
    required this.createdAt,
    required this.updatedAt,
    required this.statusViewState,
    this.lastSuccessfulSyncAt,
    this.lastAttemptedSyncAt,
    this.lastSyncErrorCode,
  });

  UserSyncProfile copyWith({
    String? userId,
    bool? syncEnabled,
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
      syncEnabled: syncEnabled ?? this.syncEnabled,
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
