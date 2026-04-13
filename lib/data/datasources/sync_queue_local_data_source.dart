import 'dart:async';
import 'package:hive/hive.dart';

import '../../domain/entities/sync/pending_change.dart';
import '../../domain/entities/sync_operation.dart';
import '../../domain/entities/sync/sync_types.dart';
import '../models/sync/pending_change_model.dart';
import '../models/sync_operation_model.dart';

class SyncQueueLocalDataSource {
  final Box<SyncOperationModel> _legacyOperationBox;
  final Box<PendingChangeModel> _pendingChangeBox;
  final _pendingChangesController = StreamController<void>.broadcast();

  SyncQueueLocalDataSource(this._legacyOperationBox, this._pendingChangeBox);

  Stream<void> get onPendingChangeAdded => _pendingChangesController.stream;

  Future<List<PendingChange>> getEffectivePendingChanges({
    String? userId,
  }) async {
    final pendingChanges = await listPendingChanges(userId: userId);
    if (pendingChanges.isNotEmpty) {
      return await _coalescePendingChanges(pendingChanges);
    }

    final legacyChanges = _legacyOperationBox.values
        .map((model) => model.toEntity())
        .map((operation) => _convertLegacyOperation(operation, userId))
        .where((change) {
          final status = change.status;
          if (status != SyncOperationStatus.pending &&
              status != SyncOperationStatus.inFlight) {
            return false;
          }
          if (change.attemptCount >= 9) {
            return false;
          }
          if (change.lastAttemptAt != null) {
            final backoffSeconds = 1 << change.attemptCount;
            final cappedBackoffSeconds = backoffSeconds > 300
                ? 300
                : backoffSeconds;
            final nextRetryAt = change.lastAttemptAt!.add(
              Duration(seconds: cappedBackoffSeconds),
            );
            if (DateTime.now().isBefore(nextRetryAt)) {
              return false;
            }
          }
          return true;
        })
        .toList();

    legacyChanges.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return legacyChanges;
  }

  PendingChange _convertLegacyOperation(
    SyncOperation operation,
    String? userId,
  ) {
    return PendingChange(
      changeId: operation.id,
      entityType: operation.entityType,
      entityId: operation.entityId,
      operation: operation.type,
      queuedAt: operation.createdAt,
      sourceUpdatedAt: operation.createdAt,
      attemptCount: operation.attemptCount,
      lastAttemptAt: operation.lastAttemptAt,
      status: SyncOperationStatus.pending,
      userId: userId,
      errorMessage: operation.errorMessage,
    );
  }

  Future<List<PendingChange>> _coalescePendingChanges(
    List<PendingChange> changes,
  ) async {
    if (changes.isEmpty) return changes;

    final List<PendingChange> coalesced = [];
    final List<String> toDelete = [];

    for (final change in changes) {
      final entityId = change.entityId;
      final previousIndex = coalesced.lastIndexWhere(
        (c) => c.entityId == entityId,
      );

      if (previousIndex == -1) {
        coalesced.add(change);
        continue;
      }

      final previous = coalesced[previousIndex];
      final previousIsUpdateOrCreate =
          previous.operation == SyncOperationType.update ||
          previous.operation == SyncOperationType.create;
      final currentIsUpdate = change.operation == SyncOperationType.update;

      if (previousIsUpdateOrCreate && currentIsUpdate) {
        toDelete.add(previous.changeId);
        coalesced[previousIndex] = change.copyWith(
          operation: previous.operation,
          queuedAt: previous.queuedAt,
        );
      } else if (previous.operation == SyncOperationType.create &&
          change.operation == SyncOperationType.delete) {
        toDelete.add(previous.changeId);
        coalesced[previousIndex] = change.copyWith(
          operation: SyncOperationType.delete,
          queuedAt: previous.queuedAt,
          clearPayload: true,
        );
      } else {
        coalesced.add(change);
      }
    }

    if (toDelete.isNotEmpty) {
      await _pendingChangeBox.deleteAll(toDelete);
    }

    return coalesced;
  }

  Future<void> enqueue(SyncOperation operation) async {
    await _legacyOperationBox.put(
      operation.id,
      SyncOperationModel.fromEntity(operation),
    );
  }

  Future<void> enqueuePendingChange(PendingChange change) async {
    await _pendingChangeBox.put(
      change.changeId,
      PendingChangeModel.fromEntity(change),
    );
    if (change.status == SyncOperationStatus.pending &&
        change.attemptCount == 0) {
      _pendingChangesController.add(null);
    }
  }

  Future<List<PendingChange>> listPendingChanges({String? userId}) async {
    final changes =
        _pendingChangeBox.values
            .map((model) => model.toEntity())
            .where((change) => userId == null || change.userId == userId)
            .toList()
          ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return changes;
  }

  Future<void> markPendingChangeInFlight(String changeId) async {
    final current = _pendingChangeBox.get(changeId)?.toEntity();
    if (current == null) {
      return;
    }
    await enqueuePendingChange(
      current.copyWith(
        status: SyncOperationStatus.inFlight,
        lastAttemptAt: DateTime.now(),
        attemptCount: current.attemptCount + 1,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> markPendingChangeFailed(
    String changeId, {
    required String errorMessage,
  }) async {
    final current = _pendingChangeBox.get(changeId)?.toEntity();
    if (current == null) {
      return;
    }
    final newAttemptCount = current.attemptCount + 1;
    await enqueuePendingChange(
      current.copyWith(
        status: newAttemptCount >= 9
            ? SyncOperationStatus.failed
            : SyncOperationStatus.pending,
        lastAttemptAt: DateTime.now(),
        attemptCount: newAttemptCount,
        errorMessage: errorMessage,
      ),
    );
  }

  Future<void> markPendingChangeSucceeded(String changeId) async {
    await _pendingChangeBox.delete(changeId);
  }

  int countPermanentlyFailedChanges({String? userId}) {
    return _pendingChangeBox.values.map((model) => model.toEntity()).where((
      change,
    ) {
      if (userId != null && change.userId != userId) return false;
      return change.status == SyncOperationStatus.failed ||
          change.attemptCount >= 9;
    }).length;
  }

  Future<List<PendingChange>> getPermanentlyFailedChanges({
    String? userId,
  }) async {
    final changes =
        _pendingChangeBox.values.map((model) => model.toEntity()).where((
          change,
        ) {
          if (userId != null && change.userId != userId) return false;
          return change.status == SyncOperationStatus.failed ||
              change.attemptCount >= 9;
        }).toList()..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return changes;
  }
}
