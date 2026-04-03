import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:medicinder/data/datasources/sync_queue_local_data_source.dart';
import 'package:medicinder/data/models/sync/pending_change_model.dart';
import 'package:medicinder/data/models/sync_operation_model.dart';
import 'package:medicinder/domain/entities/sync/pending_change.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/entities/sync_operation.dart'
    hide SyncEntityType, SyncOperationType;

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

SyncQueueLocalDataSource _buildQueue({
  _FakeBox<SyncOperationModel>? legacyBox,
  _FakeBox<PendingChangeModel>? pendingBox,
}) {
  return SyncQueueLocalDataSource(
    legacyBox ?? _FakeBox<SyncOperationModel>(),
    pendingBox ?? _FakeBox<PendingChangeModel>(),
  );
}

PendingChange _buildPendingChange({
  String changeId = 'change-1',
  String entityId = 'med-1',
  SyncOperationType operation = SyncOperationType.create,
  String? userId = 'user-1',
  SyncOperationStatus status = SyncOperationStatus.pending,
}) {
  final now = DateTime(2026, 4, 1, 8);
  return PendingChange(
    changeId: changeId,
    entityType: SyncEntityType.medication,
    entityId: entityId,
    operation: operation,
    queuedAt: now,
    sourceUpdatedAt: now,
    userId: userId,
    status: status,
  );
}

void main() {
  group('SyncQueueLocalDataSource', () {
    group('getEffectivePendingChanges', () {
      test('returns pending changes when they exist', () async {
        final queue = _buildQueue();
        final change = _buildPendingChange(changeId: 'c-1', userId: 'user-1');
        await queue.enqueuePendingChange(change);

        final result = await queue.getEffectivePendingChanges(userId: 'user-1');

        expect(result, hasLength(1));
        expect(result.first.changeId, 'c-1');
      });

      test('returns empty list when no pending changes and no legacy operations', () async {
        final queue = _buildQueue();

        final result = await queue.getEffectivePendingChanges(userId: 'user-1');

        expect(result, isEmpty);
      });

      test('falls back to legacy operations when no pending changes exist', () async {
        final legacyBox = _FakeBox<SyncOperationModel>();
        final queue = _buildQueue(legacyBox: legacyBox);

        // Add a legacy SyncOperation
        final legacyOp = SyncOperation(
          id: 'legacy-op-1',
          entityType: SyncEntityType.medication,
          entityId: 'med-legacy',
          type: SyncOperationType.update,
          createdAt: DateTime(2026, 4, 1, 8),
        );
        await queue.enqueue(legacyOp);

        final result = await queue.getEffectivePendingChanges(userId: 'user-1');

        expect(result, hasLength(1));
        expect(result.first.changeId, 'legacy-op-1');
        expect(result.first.entityId, 'med-legacy');
        expect(result.first.operation, SyncOperationType.update);
        expect(result.first.userId, 'user-1');
        expect(result.first.status, SyncOperationStatus.pending);
      });

      test('legacy fallback maps delete operation correctly', () async {
        final queue = _buildQueue();
        final legacyOp = SyncOperation(
          id: 'legacy-del-1',
          entityType: SyncEntityType.medication,
          entityId: 'med-del',
          type: SyncOperationType.delete,
          createdAt: DateTime(2026, 4, 1, 9),
        );
        await queue.enqueue(legacyOp);

        final result = await queue.getEffectivePendingChanges();

        expect(result.first.operation, SyncOperationType.delete);
      });

      test('legacy fallback maps create operation correctly', () async {
        final queue = _buildQueue();
        final legacyOp = SyncOperation(
          id: 'legacy-create-1',
          entityType: SyncEntityType.medication,
          entityId: 'med-create',
          type: SyncOperationType.create,
          createdAt: DateTime(2026, 4, 1, 9),
        );
        await queue.enqueue(legacyOp);

        final result = await queue.getEffectivePendingChanges();

        expect(result.first.operation, SyncOperationType.create);
      });

      test('prefers pending changes over legacy operations when both exist', () async {
        final queue = _buildQueue();
        // Add a pending change
        await queue.enqueuePendingChange(
          _buildPendingChange(changeId: 'new-c-1', userId: 'user-1'),
        );
        // Also add a legacy operation
        await queue.enqueue(
          SyncOperation(
            id: 'legacy-op-old',
            entityType: SyncEntityType.medication,
            entityId: 'med-old',
            type: SyncOperationType.update,
            createdAt: DateTime(2026, 4, 1, 8),
          ),
        );

        final result = await queue.getEffectivePendingChanges(userId: 'user-1');

        // Should only return the pending change, not the legacy operation
        expect(result, hasLength(1));
        expect(result.first.changeId, 'new-c-1');
      });
    });

    group('enqueuePendingChange and listPendingChanges', () {
      test('enqueued changes are listed', () async {
        final queue = _buildQueue();
        await queue.enqueuePendingChange(
          _buildPendingChange(changeId: 'c-1', userId: 'user-1'),
        );
        await queue.enqueuePendingChange(
          _buildPendingChange(changeId: 'c-2', userId: 'user-1'),
        );

        final result = await queue.listPendingChanges(userId: 'user-1');

        expect(result, hasLength(2));
      });

      test('listPendingChanges filters by userId', () async {
        final queue = _buildQueue();
        await queue.enqueuePendingChange(
          _buildPendingChange(changeId: 'c-1', userId: 'user-A'),
        );
        await queue.enqueuePendingChange(
          _buildPendingChange(changeId: 'c-2', userId: 'user-B'),
        );

        final result = await queue.listPendingChanges(userId: 'user-A');

        expect(result, hasLength(1));
        expect(result.first.changeId, 'c-1');
      });
    });

    group('markPendingChangeSucceeded', () {
      test('removes the change from the queue', () async {
        final queue = _buildQueue();
        await queue.enqueuePendingChange(_buildPendingChange(changeId: 'c-1'));

        await queue.markPendingChangeSucceeded('c-1');

        final remaining = await queue.listPendingChanges();
        expect(remaining, isEmpty);
      });
    });

    group('markPendingChangeFailed', () {
      test('updates status to failed and increments attempt count', () async {
        final queue = _buildQueue();
        await queue.enqueuePendingChange(
          _buildPendingChange(changeId: 'c-1', userId: 'user-1'),
        );

        await queue.markPendingChangeFailed(
          'c-1',
          errorMessage: 'Network error',
        );

        final changes = await queue.listPendingChanges();
        final updated = changes.first;
        expect(updated.status, SyncOperationStatus.failed);
        expect(updated.attemptCount, 1);
        expect(updated.errorMessage, 'Network error');
      });

      test('does nothing when changeId does not exist', () async {
        final queue = _buildQueue();

        // Should not throw
        await queue.markPendingChangeFailed(
          'nonexistent',
          errorMessage: 'error',
        );
      });
    });
  });
}