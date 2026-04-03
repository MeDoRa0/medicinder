import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/sync/connectivity_signal_service.dart';
import '../../../core/services/sync/sync_diagnostics.dart';
import '../../../domain/entities/sync/auth_session.dart';
import '../../../domain/entities/sync/sync_status_view_state.dart';
import '../../../domain/entities/sync/sync_types.dart';
import '../../../domain/repositories/sync_repository.dart';
import '../../../domain/usecases/sync/sign_in_for_sync.dart';
import '../../../domain/usecases/sync/sign_out_from_sync.dart';
import '../../../domain/usecases/sync/watch_auth_session.dart';
import 'sync_status_state.dart';

class SyncStatusCubit extends Cubit<SyncStatusState> {
  final SignInForSync _signInForSync;
  final SignOutFromSync _signOutFromSync;
  final WatchAuthSession _watchAuthSession;
  final SyncRepository _syncRepository;
  final SyncDiagnostics _syncDiagnostics;
  final ConnectivitySignalService _connectivitySignal;
  StreamSubscription<AuthSession>? _sessionSubscription;
  StreamSubscription<void>? _connectivitySubscription;
  bool _hasSeenSessionEvent = false;
  String? _ignoreNextSignedInUserId;

  SyncStatusCubit({
    required SignInForSync signInForSync,
    required SignOutFromSync signOutFromSync,
    required WatchAuthSession watchAuthSession,
    required SyncRepository syncRepository,
    required SyncDiagnostics syncDiagnostics,
    required ConnectivitySignalService connectivitySignal,
  }) : _signInForSync = signInForSync,
       _signOutFromSync = signOutFromSync,
       _watchAuthSession = watchAuthSession,
       _syncRepository = syncRepository,
       _syncDiagnostics = syncDiagnostics,
       _connectivitySignal = connectivitySignal,
       super(const SyncStatusState.initial());

  void initialize() {
    _sessionSubscription ??= _watchAuthSession().listen((session) {
      unawaited(_handleStreamSessionChanged(session));
    });
    _connectivitySubscription ??= _connectivitySignal.onReconnect.listen((_) {
      unawaited(handleConnectivityRestored());
    });
  }

  Future<void> signIn() async {
    emit(
      state.copyWith(
        viewState: SyncStatusViewState.signingIn,
        busy: true,
        clearMessage: true,
      ),
    );
    try {
      final session = await _signInForSync();
      _ignoreNextSignedInUserId = session.userId;
      await _applySessionState(session, trigger: SyncTrigger.userSignIn);
    } catch (error) {
      emit(
        state.copyWith(
          viewState: SyncStatusViewState.syncFailed,
          busy: false,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> signOut() async {
    await _signOutFromSync();
    _ignoreNextSignedInUserId = null;
    emit(
      state.copyWith(
        viewState: SyncStatusViewState.signedOut,
        busy: false,
        clearUserId: true,
        clearMessage: true,
      ),
    );
  }

  Future<void> retry() async {
    emit(
      state.copyWith(
        viewState: SyncStatusViewState.syncing,
        busy: true,
        clearMessage: true,
      ),
    );
    try {
      final result = await _syncRepository.synchronize();
      emit(
        state.copyWith(
          viewState: result.success
              ? SyncStatusViewState.ready
              : SyncStatusViewState.syncFailed,
          busy: false,
          message: result.message,
        ),
      );
      _syncDiagnostics.logSyncEvent(
        trigger: SyncTrigger.manualRetry,
        phase: 'completed',
        pushedCount: result.pushedCount,
        pulledCount: result.pulledCount,
        retryCount: result.failedCount,
        failureClass: result.success ? null : result.message,
      );
    } catch (error) {
      emit(
        state.copyWith(
          viewState: SyncStatusViewState.syncFailed,
          busy: false,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> handleConnectivityRestored() async {
    if (state.viewState == SyncStatusViewState.signedOut ||
        state.viewState == SyncStatusViewState.signingIn ||
        state.viewState == SyncStatusViewState.syncing) {
      return;
    }

    emit(
      state.copyWith(
        viewState: SyncStatusViewState.syncing,
        busy: true,
        clearMessage: true,
      ),
    );

    try {
      final result = await _syncRepository.syncNow(SyncTrigger.connectivityRestored);
      emit(
        state.copyWith(
          viewState: result.success
              ? SyncStatusViewState.ready
              : SyncStatusViewState.syncFailed,
          busy: false,
          message: result.message,
        ),
      );
      _syncDiagnostics.logSyncEvent(
        trigger: SyncTrigger.connectivityRestored,
        phase: 'completed',
        pushedCount: result.pushedCount,
        pulledCount: result.pulledCount,
        retryCount: result.failedCount,
        failureClass: result.success ? null : result.message,
      );
    } catch (error) {
      emit(
        state.copyWith(
          viewState: SyncStatusViewState.syncFailed,
          busy: false,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _handleStreamSessionChanged(AuthSession session) async {
    final currentEventIsFirst = !_hasSeenSessionEvent;
    _hasSeenSessionEvent = true;

    if (session.isSignedIn &&
        session.userId != null &&
        session.userId == _ignoreNextSignedInUserId) {
      _ignoreNextSignedInUserId = null;
      return;
    }

    final trigger = currentEventIsFirst
        ? SyncTrigger.appStartup
        : SyncTrigger.userSignIn;
    await _applySessionState(session, trigger: trigger);
  }

  Future<void> _applySessionState(
    AuthSession session, {
    required SyncTrigger trigger,
  }) async {
    switch (session.status) {
      case AuthSessionStatus.signedOut:
        _ignoreNextSignedInUserId = null;
        emit(
          state.copyWith(
            viewState: SyncStatusViewState.signedOut,
            busy: false,
            clearUserId: true,
            clearMessage: true,
          ),
        );
        return;
      case AuthSessionStatus.signingIn:
        emit(
          state.copyWith(
            viewState: SyncStatusViewState.signingIn,
            busy: true,
            clearMessage: true,
          ),
        );
        return;
      case AuthSessionStatus.signedIn:
      case AuthSessionStatus.workspaceInitializing:
        emit(
          state.copyWith(
            userId: session.userId,
            viewState: SyncStatusViewState.workspaceInitializing,
            busy: true,
            clearMessage: true,
          ),
        );
        return;
      case AuthSessionStatus.accessDenied:
        emit(
          state.copyWith(
            userId: session.userId,
            viewState: SyncStatusViewState.accessDenied,
            busy: false,
            message: session.failureMessage,
          ),
        );
        return;
      case AuthSessionStatus.failed:
        emit(
          state.copyWith(
            userId: session.userId,
            viewState: SyncStatusViewState.syncFailed,
            busy: false,
            message: session.failureMessage,
          ),
        );
        return;
      case AuthSessionStatus.ready:
        break;
    }

    emit(
      state.copyWith(
        userId: session.userId,
        viewState: SyncStatusViewState.syncing,
        busy: true,
        clearMessage: true,
      ),
    );

    try {
      final result = await _syncRepository.syncNow(trigger);
      emit(
        state.copyWith(
          userId: session.userId,
          viewState: result.success
              ? SyncStatusViewState.ready
              : SyncStatusViewState.syncFailed,
          busy: false,
          message: result.message,
        ),
      );
      _syncDiagnostics.logSyncEvent(
        trigger: trigger,
        phase: 'completed',
        pushedCount: result.pushedCount,
        pulledCount: result.pulledCount,
        retryCount: result.failedCount,
        failureClass: result.success ? null : result.message,
      );
    } catch (error) {
      emit(
        state.copyWith(
          userId: session.userId,
          viewState: SyncStatusViewState.syncFailed,
          busy: false,
          message: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}
