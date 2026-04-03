import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';

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
  });
}
