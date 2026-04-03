import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicinder/core/services/sync/connectivity_signal_service.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/repositories/sync_repository.dart';
import 'package:medicinder/domain/usecases/sync/sign_in_for_sync.dart';
import 'package:medicinder/domain/usecases/sync/sign_out_from_sync.dart';
import 'package:medicinder/domain/usecases/sync/watch_auth_session.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_cubit.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_state.dart';
import 'package:medicinder/presentation/widgets/sync/sync_status_banner.dart';

void main() {
  testWidgets('tapping retry button in banner triggers cubit retry', (tester) async {
    final authRepository = _FakeAuthRepository();
    final syncRepository = _FakeSyncRepository();
    final cubit = _MockSyncStatusCubit(
      signInForSync: SignInForSync(authRepository),
      signOutFromSync: SignOutFromSync(authRepository),
      watchAuthSession: WatchAuthSession(authRepository),
      syncRepository: syncRepository,
      syncDiagnostics: const SyncDiagnostics(),
      connectivitySignal: _FakeConnectivitySignalService(),
    )..seed(
        const SyncStatusState(
          viewState: SyncStatusViewState.syncFailed,
          userId: 'user-123',
          message: 'Sync failed',
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: const Scaffold(body: SyncStatusBanner()),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(cubit.retryCalled, isTrue);
  });
}

class _MockSyncStatusCubit extends SyncStatusCubit {
  bool retryCalled = false;

  _MockSyncStatusCubit({
    required super.signInForSync,
    required super.signOutFromSync,
    required super.watchAuthSession,
    required super.syncRepository,
    required super.syncDiagnostics,
    required super.connectivitySignal,
  });

  void seed(SyncStatusState state) => emit(state);

  @override
  Future<void> retry() async {
    retryCalled = true;
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> getCurrentSession() async => const AuthSession.signedOut();
  @override
  Future<AuthSession> signInForSync() async => const AuthSession.ready('u1');
  @override
  Future<void> signOutFromSync() async {}
  @override
  Stream<AuthSession> watchSession() async* { yield const AuthSession.signedOut(); }
}

class _FakeSyncRepository implements SyncRepository {
  @override
  Future<SyncResult> syncNow(SyncTrigger trigger) async => const SyncResult(success: true);
  @override
  Future<SyncResult> synchronize() async => const SyncResult(success: true);
  @override
  Future<void> handleAuthChanged(AuthSession session) async {}
  @override
  Future<void> handleConnectivityRestored() async {}
}

class _FakeConnectivitySignalService implements ConnectivitySignalService {
  @override
  Stream<void> get onReconnect => const Stream.empty();
  @override
  void dispose() {}
}
