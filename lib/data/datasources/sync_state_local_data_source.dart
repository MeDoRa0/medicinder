import 'package:hive/hive.dart';

import '../../domain/entities/sync/conflict_metadata.dart';
import '../../domain/entities/sync/sync_status_view_state.dart';
import '../../domain/entities/sync/user_sync_profile.dart';
import '../models/sync/conflict_metadata_model.dart';
import '../models/sync/user_sync_profile_model.dart';

class SyncStateLocalDataSource {
  final Box<UserSyncProfileModel> _profileBox;
  final Box<ConflictMetadataModel> _conflictBox;

  SyncStateLocalDataSource(this._profileBox, this._conflictBox);

  Future<SyncStatusViewState> getStatus([String? userId]) async {
    if (userId == null) {
      final profiles = _profileBox.values.toList(growable: false);
      final profile = profiles.isEmpty ? null : profiles.first;
      return profile?.toEntity().statusViewState ?? SyncStatusViewState.notSignedIn;
    }
    final profile = _profileBox.get(userId);
    return profile?.toEntity().statusViewState ?? SyncStatusViewState.notSignedIn;
  }

  Future<void> setStatus(SyncStatusViewState status) async {
    final profiles = _profileBox.values.toList(growable: false);
    final profile = profiles.isEmpty ? null : profiles.first;
    if (profile == null) {
      return;
    }
    final entity = profile.toEntity().copyWith(
      statusViewState: status,
      updatedAt: DateTime.now(),
    );
    await _profileBox.put(entity.userId, UserSyncProfileModel.fromEntity(entity));
  }

  Future<UserSyncProfile?> getProfile(String userId) async {
    return _profileBox.get(userId)?.toEntity();
  }

  Future<void> saveProfile(UserSyncProfile profile) async {
    await _profileBox.put(
      profile.userId,
      UserSyncProfileModel.fromEntity(profile),
    );
  }

  Future<List<ConflictMetadata>> getConflictsForEntity(String entityId) async {
    return _conflictBox.values
        .map((item) => item.toEntity())
        .where((item) => item.entityId == entityId)
        .toList();
  }

  Future<void> saveConflict(ConflictMetadata conflict) async {
    final key =
        '${conflict.entityType.name}:${conflict.entityId}:${conflict.resolvedAt.toIso8601String()}';
    await _conflictBox.put(key, ConflictMetadataModel.fromEntity(conflict));
  }
}
