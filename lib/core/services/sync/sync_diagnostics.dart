import 'dart:developer';

import '../../../domain/entities/sync/sync_types.dart';

class SyncDiagnostics {
  const SyncDiagnostics();

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
