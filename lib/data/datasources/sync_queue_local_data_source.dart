import 'package:hive/hive.dart';

import '../../domain/entities/sync/pending_change.dart';
import '../../domain/entities/sync/sync_types.dart';
import '../../domain/entities/sync_operation.dart';
import '../models/sync/pending_change_model.dart';
import '../models/sync_operation_model.dart';

class SyncQueueLocalDataSource {
  final Box<SyncOperationModel> _legacyBox;
  final Box<PendingChangeModel> _pendingChangeBox;

  SyncQueueLocalDataSource(this._legacyBox, this._pendingChangeBox);

  Future<List<SyncOperation>> getPendingOperations() async {
    final operations = _legacyBox.values.map((model) => model.toEntity()).toList();
    operations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return operations;
  }

  Future<void> enqueue(SyncOperation operation) async {
    await _legacyBox.put(operation.id, SyncOperationModel.fromEntity(operation));
  }

  Future<void> remove(String operationId) async {
    await _legacyBox.delete(operationId);
  }

  Future<void> replace(SyncOperation operation) async {
    await _legacyBox.put(operation.id, SyncOperationModel.fromEntity(operation));
  }

  Future<void> enqueuePendingChange(PendingChange change) async {
    await _pendingChangeBox.put(
      change.changeId,
      PendingChangeModel.fromEntity(change),
    );
  }

  Future<List<PendingChange>> listPendingChanges({String? userId}) async {
    final changes = _pendingChangeBox.values
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
    await enqueuePendingChange(
      current.copyWith(
        status: SyncOperationStatus.failed,
        lastAttemptAt: DateTime.now(),
        attemptCount: current.attemptCount + 1,
        errorMessage: errorMessage,
      ),
    );
  }

  Future<void> markPendingChangeSucceeded(String changeId) async {
    await _pendingChangeBox.delete(changeId);
  }
}
