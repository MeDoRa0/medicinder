import 'dart:developer';

import 'package:hive/hive.dart';

import '../../domain/entities/sync/conflict_metadata.dart';
import '../../domain/entities/sync/sync_cycle_state.dart';
import '../../domain/entities/sync/sync_status_view_state.dart';
import '../../domain/entities/sync/user_sync_profile.dart';
import '../models/sync/conflict_metadata_model.dart';
import '../models/sync/sync_cycle_state_model.dart';
import '../models/sync/user_sync_profile_model.dart';

class SyncStateLocalDataSource {
  final Box<UserSyncProfileModel> _profileBox;
  final Box<ConflictMetadataModel> _conflictBox;
  final Box<SyncCycleStateModel> _syncCycleBox;

  SyncStateLocalDataSource(
    this._profileBox,
    this._conflictBox,
    this._syncCycleBox,
  );

  Future<SyncStatusViewState> getStatus([String? userId]) async {
    if (userId == null) {
      final profiles = _profileBox.values.toList(growable: false);
      final profile = profiles.isEmpty ? null : profiles.first;
      return profile?.toEntity().statusViewState ?? SyncStatusViewState.signedOut;
    }
    final profile = _profileBox.get(userId);
    return profile?.toEntity().statusViewState ?? SyncStatusViewState.signedOut;
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
    await _profileBox.put(
        entity.userId, UserSyncProfileModel.fromEntity(entity));
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

  Future<List<ConflictMetadata>> getConflictsForEntity(
    String entityId, {
    String? userId,
  }) async {
    return _conflictBox.values
        .map((item) {
          try {
            return item.toEntity();
          } catch (e) {
            // Log and skip corrupted conflict metadata records
            // This handles migration issues with missing userId in legacy data
            log('SyncStateLocalDataSource: Skipping corrupted conflict metadata: $e',
                name: 'SyncStateLocalDataSource');
            return null;
          }
        })
        .where((item) =>
            item != null &&
            item.entityId == entityId &&
            (userId == null || item.userId == userId))
        .cast<ConflictMetadata>()
        .toList();
  }

  Future<void> saveConflict(ConflictMetadata conflict) async {
    final key =
        '${conflict.userId}:${conflict.entityType.name}:${conflict.entityId}:${conflict.resolvedAt.toIso8601String()}';
    await _conflictBox.put(key, ConflictMetadataModel.fromEntity(conflict));
  }

  Future<SyncCycleState?> getLatestCycle(String userId) async {
    final cycles = _syncCycleBox.values
        .where((c) => c.userId == userId)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return cycles.isEmpty ? null : cycles.first.toEntity();
  }

  Future<void> saveCycle(SyncCycleState cycle) async {
    await _syncCycleBox.put(
      cycle.cycleId,
      SyncCycleStateModel.fromEntity(cycle),
    );
  }
}

