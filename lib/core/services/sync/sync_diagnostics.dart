import 'dart:developer';

import '../../../data/datasources/sync_state_local_data_source.dart';
import '../../../domain/entities/sync/sync_types.dart';
import '../../../domain/entities/sync/user_sync_profile.dart';

class SyncDiagnostics {
  final SyncStateLocalDataSource? _syncState;

  const SyncDiagnostics([this._syncState]);

  Future<UserSyncProfile?> getProfile(String userId) async {
    return _syncState?.getProfile(userId);
  }

  void logStartupMode({
    required bool firebaseConfigured,
    required bool localOnly,
  }) {
    log(
      'SyncDiagnostics.startup firebaseConfigured=$firebaseConfigured localOnly=$localOnly',
      name: 'sync',
    );
  }

  void logSyncEvent({
    required SyncTrigger trigger,
    required String phase,
    int? pushedCount,
    int? pulledCount,
    int? retryCount,
    String? failureClass,
  }) {
    log(
      'SyncDiagnostics.event trigger=${trigger.name} phase=$phase pushed=$pushedCount pulled=$pulledCount retry=$retryCount failure=$failureClass',
      name: 'sync',
    );
  }
}
