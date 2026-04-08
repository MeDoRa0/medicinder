import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/connectivity_signal_service.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/data/datasources/sync_queue_local_data_source.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/entities/sync/pending_change.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/entities/sync_operation.dart';
import 'package:medicinder/domain/repositories/app_entry_repository.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/repositories/medication_repository.dart';
import 'package:medicinder/domain/repositories/sync_repository.dart';
import 'package:medicinder/domain/usecases/add_medication.dart';
import 'package:medicinder/domain/usecases/auth/clear_app_entry_state.dart';
import 'package:medicinder/domain/usecases/auth/continue_as_guest.dart';
import 'package:medicinder/domain/usecases/auth/restore_app_entry_session.dart';
import 'package:medicinder/domain/usecases/delete_medication.dart';
import 'package:medicinder/domain/usecases/get_medications.dart';
import 'package:medicinder/domain/usecases/reset_daily_doses.dart';
import 'package:medicinder/domain/usecases/sync/sign_in_for_sync.dart';
import 'package:medicinder/domain/usecases/sync/sign_out_from_sync.dart';
import 'package:medicinder/domain/usecases/sync/watch_auth_session.dart';
import 'package:medicinder/domain/usecases/update_dose_status.dart';
import 'package:medicinder/domain/usecases/update_medication.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/cubit/auth/auth_entry_cubit.dart';
import 'package:medicinder/presentation/cubit/medication_cubit.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_cubit.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_state.dart';
import 'package:medicinder/presentation/pages/app_launch_router_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_notification_sync_service.dart';

void main() {
  testWidgets('shows the entry gate when no stored mode exists', (tester) async {
    await _setLargeSurface(tester);
    SharedPreferences.setMockInitialValues({});
    final appEntryRepository = _FakeAppEntryRepository();
    final authCubit = _buildAuthCubit(appEntryRepository);
    await authCubit.restoreSession();

    await tester.pumpWidget(
      _RouterHarness(
        authCubit: authCubit,
        syncCubit: _buildSyncCubit(appEntryRepository),
      ),
    );
    await tester.pump();

    expect(find.text('Choose how to enter'), findsOneWidget);
  });

  testWidgets('routes restored guest users to initial settings when meal times are missing', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    SharedPreferences.setMockInitialValues({});
    final appEntryRepository = _FakeAppEntryRepository()..storedMode = 'guest';
    final authCubit = _buildAuthCubit(appEntryRepository);
    await authCubit.restoreSession();

    await tester.pumpWidget(
      _RouterHarness(
        authCubit: authCubit,
        syncCubit: _buildSyncCubit(appEntryRepository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('initialSettings')), findsOneWidget);
  });

  testWidgets('routes restored guest users to home when meal times exist', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    SharedPreferences.setMockInitialValues({
      'breakfastTime': '8:0',
      'lunchTime': '13:0',
      'dinnerTime': '19:0',
    });
    final appEntryRepository = _FakeAppEntryRepository()..storedMode = 'guest';
    final authCubit = _buildAuthCubit(appEntryRepository);
    await authCubit.restoreSession();

    await tester.pumpWidget(
      _RouterHarness(
        authCubit: authCubit,
        syncCubit: _buildSyncCubit(appEntryRepository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('homePage')), findsOneWidget);
  });

  testWidgets('falls back to the gate when an unsupported stored mode is restored', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    SharedPreferences.setMockInitialValues({});
    final appEntryRepository = _FakeAppEntryRepository()..storedMode = 'google';
    final authCubit = _buildAuthCubit(appEntryRepository);
    await authCubit.restoreSession();

    await tester.pumpWidget(
      _RouterHarness(
        authCubit: authCubit,
        syncCubit: _buildSyncCubit(appEntryRepository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose how to enter'), findsOneWidget);
    expect(
      find.text(
        'The previous sign-in mode is not supported yet. Please choose an option again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sign out clears the stored mode and returns the running app to the gate', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    SharedPreferences.setMockInitialValues({
      'breakfastTime': '8:0',
      'lunchTime': '13:0',
      'dinnerTime': '19:0',
    });
    final appEntryRepository = _FakeAppEntryRepository()..storedMode = 'guest';
    final authCubit = _buildAuthCubit(appEntryRepository);
    await authCubit.restoreSession();
    final syncCubit = _buildSyncCubit(appEntryRepository)
      ..seed(
        const SyncStatusState(
          viewState: SyncStatusViewState.ready,
          userId: 'user-123',
        ),
      );

    await tester.pumpWidget(
      _RouterHarness(
        authCubit: authCubit,
        syncCubit: syncCubit,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('homePage')), findsOneWidget);

    await syncCubit.signOut();
    await tester.pumpAndSettle();

    expect(appEntryRepository.storedMode, isNull);
    expect(find.text('Choose how to enter'), findsOneWidget);
  });
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _RouterHarness extends StatelessWidget {
  final AuthEntryCubit authCubit;
  final _SeededSyncStatusCubit syncCubit;

  const _RouterHarness({
    required this.authCubit,
    required this.syncCubit,
  });

  @override
  Widget build(BuildContext context) {
    final medicationRepository = _FakeMedicationRepository();
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthEntryCubit>.value(value: authCubit),
        BlocProvider<SyncStatusCubit>.value(value: syncCubit),
        BlocProvider(
          create: (_) => MedicationCubit(
            addMedication: AddMedication(medicationRepository),
            getMedications: GetMedications(medicationRepository),
            updateMedication: UpdateMedication(medicationRepository),
            updateDoseStatus: UpdateDoseStatus(medicationRepository),
            deleteMedication: DeleteMedication(medicationRepository),
            resetDailyDoses: ResetDailyDoses(medicationRepository),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: AppLaunchRouterPage(
          onLocaleChanged: (_) {},
          onRestartApp: () {},
        ),
      ),
    );
  }
}

AuthEntryCubit _buildAuthCubit(_FakeAppEntryRepository repository) {
  return AuthEntryCubit(
    restoreAppEntrySession: RestoreAppEntrySession(repository),
    continueAsGuest: ContinueAsGuest(repository),
    clearAppEntryState: ClearAppEntryState(repository),
  );
}

_SeededSyncStatusCubit _buildSyncCubit(_FakeAppEntryRepository repository) {
  final authRepository = _FakeAuthRepository();
  return _SeededSyncStatusCubit(
    signInForSync: SignInForSync(authRepository),
    signOutFromSync: SignOutFromSync(authRepository),
    watchAuthSession: WatchAuthSession(authRepository),
    clearAppEntryState: ClearAppEntryState(repository),
    syncRepository: _FakeSyncRepository(),
    syncDiagnostics: const SyncDiagnostics(),
    connectivitySignal: _FakeConnectivitySignalService(),
    syncQueue: _FakeSyncQueue(),
    notificationSyncService: FakeNotificationSyncService(),
  );
}

class _SeededSyncStatusCubit extends SyncStatusCubit {
  _SeededSyncStatusCubit({
    required super.signInForSync,
    required super.signOutFromSync,
    required super.watchAuthSession,
    required super.clearAppEntryState,
    required super.syncRepository,
    required super.syncDiagnostics,
    required super.connectivitySignal,
    required super.syncQueue,
    required super.notificationSyncService,
  });

  void seed(SyncStatusState state) => emit(state);
}

class _FakeAppEntryRepository implements AppEntryRepository {
  String? storedMode;

  @override
  Future<void> clearResolvedEntryMode() async {
    storedMode = null;
  }

  @override
  Future<void> persistGuestMode() async {
    storedMode = 'guest';
  }

  @override
  Future<String?> readResolvedEntryMode() async => storedMode;
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> getCurrentSession() async => const AuthSession.signedOut();

  @override
  Future<AuthSession> signInForSync() async =>
      const AuthSession.ready('user-123');

  @override
  Future<void> signOutFromSync() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield const AuthSession.signedOut();
  }
}

class _FakeSyncRepository implements SyncRepository {
  @override
  Future<SyncResult> syncNow(SyncTrigger trigger) async =>
      const SyncResult(success: true);

  @override
  Future<SyncResult> synchronize() async => const SyncResult(success: true);

  @override
  Future<void> handleAuthChanged(AuthSession session) async {}

  @override
  Future<void> handleConnectivityRestored() async {}
}

class _FakeConnectivitySignalService implements ConnectivitySignalService {
  @override
  Stream<void> get onReconnect => const Stream<void>.empty();

  @override
  Future<void> dispose() async {}
}

class _FakeSyncQueue implements SyncQueueLocalDataSource {
  @override
  Future<void> enqueuePendingChange(PendingChange change) async {}

  @override
  Future<void> enqueue(SyncOperation operation) async {}

  @override
  Future<List<PendingChange>> listPendingChanges({String? userId}) async =>
      const [];

  @override
  Future<List<PendingChange>> getEffectivePendingChanges({
    String? userId,
  }) async => const [];

  @override
  Future<void> markPendingChangeInFlight(String changeId) async {}

  @override
  Future<void> markPendingChangeFailed(
    String changeId, {
    required String errorMessage,
  }) async {}

  @override
  Future<void> markPendingChangeSucceeded(String changeId) async {}

  @override
  int countPermanentlyFailedChanges({String? userId}) => 0;

  @override
  Future<List<PendingChange>> getPermanentlyFailedChanges({
    String? userId,
  }) async => const [];
}

class _FakeMedicationRepository implements MedicationRepository {
  final List<Medication> medications = [];

  @override
  Future<void> addMedication(Medication medication) async {
    medications.add(medication);
  }

  @override
  Future<void> deleteMedication(String id) async {
    medications.removeWhere((medication) => medication.id == id);
  }

  @override
  Future<List<Medication>> getMedications({bool includeDeleted = false}) async =>
      List.unmodifiable(medications);

  @override
  Future<Medication?> getMedicationById(
    String id, {
    bool includeDeleted = false,
  }) async {
    for (final medication in medications) {
      if (medication.id == id) {
        return medication;
      }
    }
    return null;
  }

  @override
  Future<void> purgeMedication(String id) async {
    medications.removeWhere((medication) => medication.id == id);
  }

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
