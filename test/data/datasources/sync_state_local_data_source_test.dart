import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:medicinder/data/datasources/sync_state_local_data_source.dart';
import 'package:medicinder/data/models/sync/conflict_metadata_model.dart';
import 'package:medicinder/data/models/sync/sync_cycle_state_model.dart';
import 'package:medicinder/data/models/sync/user_sync_profile_model.dart';
import 'package:medicinder/domain/entities/sync/conflict_metadata.dart';
import 'package:medicinder/domain/entities/sync/sync_cycle_state.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/entities/sync/user_sync_profile.dart';

// Minimal in-memory Box fake for testing without Hive initialization.
class _FakeBox<E> implements Box<E> {
  final Map<dynamic, E> _store = {};

  @override
  E? get(dynamic key, {E? defaultValue}) => _store[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, E value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _store.remove(key);
  }

  @override
  Iterable<E> get values => _store.values;

  @override
  Iterable<dynamic> get keys => _store.keys;

  @override
  bool get isEmpty => _store.isEmpty;

  @override
  bool get isNotEmpty => _store.isNotEmpty;

  @override
  int get length => _store.length;

  // --- Stub out the rest of the Box interface ---
  @override
  bool get isOpen => true;

  @override
  bool get lazy => false;

  @override
  String get name => 'fake';

  @override
  String? get path => null;

  @override
  bool containsKey(dynamic key) => _store.containsKey(key);

  @override
  Future<int> clear() async {
    final count = _store.length;
    _store.clear();
    return count;
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> compact() async {}

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (final k in keys) {
      _store.remove(k);
    }
  }

  @override
  Future<int> deleteAt(int index) async {
    final key = _store.keys.elementAt(index);
    _store.remove(key);
    return 1;
  }

  @override
  Future<void> deleteFromDisk() async {}

  @override
  E? getAt(int index) => _store.values.elementAt(index);

  @override
  Map<dynamic, E> toMap() => Map.of(_store);

  @override
  Future<void> putAll(Map<dynamic, E> entries) async {
    _store.addAll(entries);
  }

  @override
  Future<int> putAt(int index, E value) async {
    final key = _store.keys.elementAt(index);
    _store[key] = value;
    return index;
  }

  @override
  Future<int> add(E value) async {
    final key = _store.length;
    _store[key] = value;
    return key;
  }

  @override
  Future<Iterable<int>> addAll(Iterable<E> values) async {
    final keys = <int>[];
    for (final v in values) {
      keys.add(await add(v));
    }
    return keys;
  }

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  Iterable<E> valuesBetween({dynamic startKey, dynamic endKey}) {
    return _store.values;
  }

  @override
  dynamic keyAt(int index) => _store.keys.elementAt(index);
}

SyncStateLocalDataSource _buildDataSource({
  _FakeBox<UserSyncProfileModel>? profileBox,
  _FakeBox<ConflictMetadataModel>? conflictBox,
  _FakeBox<SyncCycleStateModel>? cycleBox,
}) {
  return SyncStateLocalDataSource(
    profileBox ?? _FakeBox<UserSyncProfileModel>(),
    conflictBox ?? _FakeBox<ConflictMetadataModel>(),
    cycleBox ?? _FakeBox<SyncCycleStateModel>(),
  );
}

UserSyncProfile _buildProfile({
  String userId = 'user-1',
  SyncStatusViewState statusViewState = SyncStatusViewState.ready,
}) {
  final now = DateTime(2026, 4, 1);
  return UserSyncProfile(
    userId: userId,
    syncEnabled: true,
    createdAt: now,
    updatedAt: now,
    statusViewState: statusViewState,
  );
}

ConflictMetadata _buildConflict({
  String entityId = 'med-1',
  String userId = 'user-1',
  String winningSource = 'remote',
}) {
  final now = DateTime(2026, 4, 1, 10);
  return ConflictMetadata(
    entityType: SyncEntityType.medication,
    entityId: entityId,
    userId: userId,
    localUpdatedAt: now.subtract(const Duration(hours: 1)),
    remoteUpdatedAt: now,
    winningSource: winningSource,
    resolvedAt: now,
  );
}

SyncCycleState _buildCycle({
  String cycleId = 'cycle-1',
  String userId = 'user-1',
  SyncCycleStatus status = SyncCycleStatus.succeeded,
  DateTime? startedAt,
}) {
  return SyncCycleState(
    cycleId: cycleId,
    userId: userId,
    trigger: SyncTrigger.appStartup,
    startedAt: startedAt ?? DateTime(2026, 4, 1, 10),
    status: status,
  );
}

void main() {
  group('SyncStateLocalDataSource', () {
    group('getStatus', () {
      test('returns signedOut when no profiles exist', () async {
        final ds = _buildDataSource();

        final status = await ds.getStatus();

        expect(status, SyncStatusViewState.signedOut);
      });

      test(
        'returns signedOut when no profiles exist for given userId',
        () async {
          final ds = _buildDataSource();

          final status = await ds.getStatus('user-1');

          expect(status, SyncStatusViewState.signedOut);
        },
      );

      test('returns profile status when profile exists for userId', () async {
        final ds = _buildDataSource();
        await ds.saveProfile(
          _buildProfile(
            userId: 'user-1',
            statusViewState: SyncStatusViewState.syncFailed,
          ),
        );

        final status = await ds.getStatus('user-1');

        expect(status, SyncStatusViewState.syncFailed);
      });

      test('returns first profile status when no userId given', () async {
        final ds = _buildDataSource();
        await ds.saveProfile(
          _buildProfile(
            userId: 'user-1',
            statusViewState: SyncStatusViewState.syncing,
          ),
        );

        final status = await ds.getStatus();

        expect(status, SyncStatusViewState.syncing);
      });
    });

    group('saveProfile and getProfile', () {
      test('saves and retrieves a profile by userId', () async {
        final ds = _buildDataSource();
        final profile = _buildProfile(userId: 'user-abc');

        await ds.saveProfile(profile);
        final retrieved = await ds.getProfile('user-abc');

        expect(retrieved, isNotNull);
        expect(retrieved!.userId, 'user-abc');
      });

      test('returns null when no profile exists for userId', () async {
        final ds = _buildDataSource();

        final result = await ds.getProfile('nonexistent');

        expect(result, isNull);
      });

      test('overwrites existing profile with same userId', () async {
        final ds = _buildDataSource();
        final initial = _buildProfile(
          userId: 'user-1',
          statusViewState: SyncStatusViewState.syncing,
        );
        final updated = _buildProfile(
          userId: 'user-1',
          statusViewState: SyncStatusViewState.ready,
        );

        await ds.saveProfile(initial);
        await ds.saveProfile(updated);
        final retrieved = await ds.getProfile('user-1');

        expect(retrieved!.statusViewState, SyncStatusViewState.ready);
      });
    });

    group('setStatus', () {
      test('does nothing when no profiles exist', () async {
        final ds = _buildDataSource();

        // Should not throw
        await ds.setStatus(SyncStatusViewState.syncFailed);
      });

      test('updates status for the first profile found', () async {
        final ds = _buildDataSource();
        await ds.saveProfile(_buildProfile(userId: 'user-1'));

        await ds.setStatus(SyncStatusViewState.syncFailed);

        final profile = await ds.getProfile('user-1');
        expect(profile!.statusViewState, SyncStatusViewState.syncFailed);
      });
    });

    group('saveConflict and getConflictsForEntity', () {
      test('saves and retrieves conflicts by entityId', () async {
        final ds = _buildDataSource();
        final conflict = _buildConflict(entityId: 'med-1', userId: 'user-1');

        await ds.saveConflict(conflict);
        final results = await ds.getConflictsForEntity('med-1');

        expect(results, hasLength(1));
        expect(results.first.entityId, 'med-1');
        expect(results.first.userId, 'user-1');
      });

      test('returns empty list when no conflicts for entityId', () async {
        final ds = _buildDataSource();
        await ds.saveConflict(_buildConflict(entityId: 'med-1'));

        final results = await ds.getConflictsForEntity('med-99');

        expect(results, isEmpty);
      });

      test('filters by userId when provided', () async {
        final ds = _buildDataSource();
        await ds.saveConflict(
          _buildConflict(entityId: 'med-1', userId: 'user-A'),
        );
        // Force a different key by using a different resolvedAt
        final conflictB = ConflictMetadata(
          entityType: SyncEntityType.medication,
          entityId: 'med-1',
          userId: 'user-B',
          localUpdatedAt: DateTime(2026, 4, 1, 9),
          remoteUpdatedAt: DateTime(2026, 4, 1, 10),
          winningSource: 'remote',
          resolvedAt: DateTime(2026, 4, 1, 10, 30),
        );
        await ds.saveConflict(conflictB);

        final resultsA = await ds.getConflictsForEntity(
          'med-1',
          userId: 'user-A',
        );
        final resultsB = await ds.getConflictsForEntity(
          'med-1',
          userId: 'user-B',
        );

        expect(resultsA, hasLength(1));
        expect(resultsA.first.userId, 'user-A');
        expect(resultsB, hasLength(1));
        expect(resultsB.first.userId, 'user-B');
      });

      test('returns all conflicts for entity when userId is null', () async {
        final ds = _buildDataSource();
        await ds.saveConflict(
          _buildConflict(entityId: 'med-1', userId: 'user-A'),
        );
        final conflictB = ConflictMetadata(
          entityType: SyncEntityType.medication,
          entityId: 'med-1',
          userId: 'user-B',
          localUpdatedAt: DateTime(2026, 4, 1, 9),
          remoteUpdatedAt: DateTime(2026, 4, 1, 10),
          winningSource: 'local',
          resolvedAt: DateTime(2026, 4, 2, 10),
        );
        await ds.saveConflict(conflictB);

        final results = await ds.getConflictsForEntity('med-1');

        expect(results, hasLength(2));
      });

      test('uses userId-scoped key so multiple conflicts can coexist', () async {
        final ds = _buildDataSource();
        final conflict1 = _buildConflict(entityId: 'med-1', userId: 'user-1');
        // Same entityId, same userId, same resolvedAt => same key => overwrite
        await ds.saveConflict(conflict1);
        await ds.saveConflict(conflict1);

        final results = await ds.getConflictsForEntity(
          'med-1',
          userId: 'user-1',
        );

        // Duplicate key results in one entry (overwrite)
        expect(results, hasLength(1));
      });
    });

    group('saveCycle and getLatestCycle', () {
      test('saves and retrieves the latest cycle for a user', () async {
        final ds = _buildDataSource();
        final cycle = _buildCycle(cycleId: 'cycle-1', userId: 'user-1');

        await ds.saveCycle(cycle);
        final latest = await ds.getLatestCycle('user-1');

        expect(latest, isNotNull);
        expect(latest!.cycleId, 'cycle-1');
        expect(latest.userId, 'user-1');
      });

      test('returns null when no cycles exist for user', () async {
        final ds = _buildDataSource();

        final latest = await ds.getLatestCycle('user-unknown');

        expect(latest, isNull);
      });

      test('returns most recent cycle when multiple cycles exist', () async {
        final ds = _buildDataSource();
        final older = _buildCycle(
          cycleId: 'cycle-old',
          userId: 'user-1',
          startedAt: DateTime(2026, 4, 1, 9),
        );
        final newer = _buildCycle(
          cycleId: 'cycle-new',
          userId: 'user-1',
          startedAt: DateTime(2026, 4, 1, 10),
        );

        await ds.saveCycle(older);
        await ds.saveCycle(newer);
        final latest = await ds.getLatestCycle('user-1');

        expect(latest!.cycleId, 'cycle-new');
      });

      test('does not return cycles from a different user', () async {
        final ds = _buildDataSource();
        await ds.saveCycle(_buildCycle(cycleId: 'cycle-1', userId: 'user-A'));

        final latest = await ds.getLatestCycle('user-B');

        expect(latest, isNull);
      });

      test('overwrites cycle with same cycleId', () async {
        final ds = _buildDataSource();
        final initial = _buildCycle(
          cycleId: 'cycle-1',
          userId: 'user-1',
          status: SyncCycleStatus.running,
        );
        final updated = _buildCycle(
          cycleId: 'cycle-1',
          userId: 'user-1',
          status: SyncCycleStatus.succeeded,
        );

        await ds.saveCycle(initial);
        await ds.saveCycle(updated);
        final latest = await ds.getLatestCycle('user-1');

        expect(latest!.status, SyncCycleStatus.succeeded);
      });
    });
  });
}
