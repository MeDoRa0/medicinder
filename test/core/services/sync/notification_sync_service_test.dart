import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/notification_sync_service.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/core/services/notification_optimizer.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/domain/repositories/medication_repository.dart';

class _FakeMedicationRepository implements MedicationRepository {
  final Map<String, Medication> medications = {};

  @override
  Future<void> addMedication(Medication medication) async {}
  @override
  Future<void> deleteMedication(String id) async {}
  @override
  Future<Medication?> getMedicationById(
    String id, {
    bool includeDeleted = false,
  }) async {
    return medications[id];
  }
  @override
  Future<List<Medication>> getMedications({bool includeDeleted = false}) async => [];
  @override
  Future<void> purgeMedication(String id) async {}
  @override
  Future<void> resetDailyDoses() async {}
  @override
  Future<void> saveSyncedMedication(Medication medication) async {}
  @override
  Future<void> updateDoseStatus(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {}
  @override
  Future<void> updateMedication(Medication medication) async {}
}

class _FakeNotificationOptimizer implements NotificationOptimizer {
  final List<Medication> capturedGenerateMedications = [];
  final List<String> capturedCancelIds = [];
  bool cancelAllCalled = false;
  bool mockIsAllowed = true;

  @override
  Future<void> scheduleNextDoseNotification(Medication medication, {BuildContext? context}) async {
    capturedGenerateMedications.add(medication);
  }

  @override
  Future<void> batchScheduleNotifications(List<Medication> medications, {BuildContext? context}) async {}

  @override
  Future<int> cancelMedicationNotifications(String medicationId) async {
    capturedCancelIds.add(medicationId);
    return 1;
  }

  @override
  Future<void> clearAllNotifications() async {
    cancelAllCalled = true;
  }

  @override
  Future<List<NotificationModel>> getScheduledNotifications() async => [];

  @override
  Map<String, dynamic> getCacheStats() => {};

  @override
  Future<bool> isNotificationAllowed() async => mockIsAllowed;
}

void main() {
  group('NotificationSync Service', () {
    late _FakeMedicationRepository repository;
    late _FakeNotificationOptimizer optimizer;
    late NotificationSyncService service;

    setUp(() {
      repository = _FakeMedicationRepository();
      optimizer = _FakeNotificationOptimizer();
      service = NotificationSyncService(
        medicationRepository: repository,
        notificationOptimizer: optimizer,
        syncDiagnostics: const SyncDiagnostics(),
      );
      optimizer.mockIsAllowed = true;
    });

    test('returns early if changedMedicationIds is empty', () async {
      final summary = await service.regenerateNotifications(changedMedicationIds: []);
      expect(summary.medicationsProcessed, 0);
      expect(summary.permissionDenied, isFalse);
    });

    test('ignores changed IDs if not found in repository', () async {
      final summary = await service.regenerateNotifications(changedMedicationIds: ['not-found']);
      expect(summary.medicationsProcessed, 1);
      expect(summary.failures, 0);
      expect(summary.notificationsCancelled, 1);
      expect(optimizer.capturedGenerateMedications, isEmpty);
    });

    test('regenerates notifications for existing medications', () async {
      final now = DateTime(2026, 4, 1);
      final med = Medication.create(
        id: 'med-1',
        name: 'Aspirin',
        usage: 'take one',
        dosage: '100mg',
        type: MedicationType.pill,
        timingType: MedicationTimingType.specificTime,
        doses: [MedicationDose(time: now.add(const Duration(hours: 1)), taken: false)],
        totalDays: 2,
        startDate: now,
        now: now,
      );
      repository.medications['med-1'] = med;

      final summary = await service.regenerateNotifications(changedMedicationIds: ['med-1']);

      expect(summary.medicationsProcessed, 1);
      expect(summary.failures, 0);
      expect(optimizer.capturedCancelIds, contains('med-1'));
      expect(optimizer.capturedGenerateMedications.first.id, 'med-1');
      expect(optimizer.cancelAllCalled, isFalse);
    });

    test('returns permissionDenied if user denies notification permission', () async {
      optimizer.mockIsAllowed = false;
      final summary = await service.regenerateNotifications(changedMedicationIds: ['med-1']);

      expect(summary.permissionDenied, isTrue);
    });

    test('cancelAllMedicationNotifications delegates to optimizer', () async {
      await service.cancelAllMedicationNotifications();
      expect(optimizer.cancelAllCalled, isTrue);
    });
  });
}
