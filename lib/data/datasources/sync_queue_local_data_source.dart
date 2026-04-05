import 'package:hive/hive.dart';

import '../../domain/entities/sync/pending_change.dart';
import '../../domain/entities/sync/sync_types.dart';
import '../models/sync/pending_change_model.dart';

class SyncQueueLocalDataSource {
  final Box<PendingChangeModel> _pendingChangeBox;

  SyncQueueLocalDataSource(this._pendingChangeBox);

  Future<List<PendingChange>> getEffectivePendingChanges({
    String? userId,
  }) async {
    final changes = await listPendingChanges(userId: userId);
    final eligible = changes.where((change) {
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
    }).toList();

    return _coalescePendingChanges(eligible);
  }

  List<PendingChange> _coalescePendingChanges(List<PendingChange> changes) {
    if (changes.isEmpty) return changes;

    final List<PendingChange> coalesced = [];

    for (final change in changes) {
      final entityId = change.entityId;
      final previousIndex = coalesced.lastIndexWhere((c) => c.entityId == entityId);

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
        coalesced[previousIndex] = change.copyWith(
          operation: previous.operation,
          queuedAt: previous.queuedAt,
        );
      } else if (previous.operation == SyncOperationType.create &&
          change.operation == SyncOperationType.delete) {
        coalesced[previousIndex] = change.copyWith(
          operation: SyncOperationType.delete,
          queuedAt: previous.queuedAt,
          clearPayload: true,
        );
      } else {
        coalesced.add(change);
      }
    }

    return coalesced;
  }

  Future<void> enqueuePendingChange(PendingChange change) async {
    await _pendingChangeBox.put(
      change.changeId,
      PendingChangeModel.fromEntity(change),
    );
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
