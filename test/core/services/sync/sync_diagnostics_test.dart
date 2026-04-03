import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/data/datasources/sync_state_local_data_source.dart';
import 'package:medicinder/data/models/sync/conflict_metadata_model.dart';
import 'package:medicinder/data/models/sync/sync_cycle_state_model.dart';
import 'package:medicinder/data/models/sync/user_sync_profile_model.dart';
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
  Future<void> delete(dynamic key) async => _store.remove(key);

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
  Future<void> clear() async => _store.clear();

  @override
  Future<void> close() async {}

  @override
  Future<void> compact() async {}

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (final k in keys) _store.remove(k);
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
  Future<void> putAll(Map<dynamic, E> entries) async => _store.addAll(entries);

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
    for (final v in values) keys.add(await add(v));
    return keys;
  }

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  Iterable<E> valuesBetween({dynamic startKey, dynamic endKey}) => _store.values;

  @override
  dynamic keyAt(int index) => _store.keys.elementAt(index);
}

SyncStateLocalDataSource _buildSyncState() {
  return SyncStateLocalDataSource(
    _FakeBox<UserSyncProfileModel>(),
    _FakeBox<ConflictMetadataModel>(),
    _FakeBox<SyncCycleStateModel>(),
  );
}

void main() {
  group('SyncDiagnostics', () {
    test('logs sync events without medication payloads', () {
      const diagnostics = SyncDiagnostics();
      // This test is primarily to ensure it doesn't crash and follows the constitution (no payloads).
      diagnostics.logSyncEvent(
        trigger: SyncTrigger.appStartup,
        phase: 'started',
      );
    });

    test('getProfile returns null when no syncState is provided', () async {
      const diagnostics = SyncDiagnostics();

      final profile = await diagnostics.getProfile('user-1');

      expect(profile, isNull);
    });

    test('getProfile delegates to syncState and returns the stored profile', () async {
      final syncState = _buildSyncState();
      final storedProfile = UserSyncProfile(
        userId: 'user-1',
        syncEnabled: true,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
        statusViewState: SyncStatusViewState.ready,
      );
      await syncState.saveProfile(storedProfile);

      final diagnostics = SyncDiagnostics(syncState);
      final profile = await diagnostics.getProfile('user-1');

      expect(profile, isNotNull);
      expect(profile!.userId, 'user-1');
      expect(profile.statusViewState, SyncStatusViewState.ready);
    });

    test('getProfile returns null when syncState has no profile for userId', () async {
      final syncState = _buildSyncState();
      final diagnostics = SyncDiagnostics(syncState);

      final profile = await diagnostics.getProfile('nonexistent-user');

      expect(profile, isNull);
    });

    test('logSyncEvent with all optional parameters does not throw', () {
      const diagnostics = SyncDiagnostics();

      diagnostics.logSyncEvent(
        trigger: SyncTrigger.connectivityRestored,
        phase: 'completed',
        pushedCount: 3,
        pulledCount: 2,
        retryCount: 1,
        failureClass: 'network_timeout',
      );
    });
  });
}