import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/auth/app_entry_session.dart';
import '../../../domain/usecases/auth/clear_app_entry_state.dart';
import '../../../domain/usecases/auth/continue_as_guest.dart';
import '../../../domain/usecases/auth/restore_app_entry_session.dart';
import 'auth_entry_state.dart';

class AuthEntryCubit extends Cubit<AuthEntryState> {
  final RestoreAppEntrySession _restoreAppEntrySession;
  final ContinueAsGuest _continueAsGuest;
  final ClearAppEntryState _clearAppEntryState;

  AuthEntryCubit({
    required RestoreAppEntrySession restoreAppEntrySession,
    required ContinueAsGuest continueAsGuest,
    required ClearAppEntryState clearAppEntryState,
  }) : _restoreAppEntrySession = restoreAppEntrySession,
       _continueAsGuest = continueAsGuest,
       _clearAppEntryState = clearAppEntryState,
       super(const AuthEntryState.initial());

  Future<void> restoreSession() async {
    emit(
      state.copyWith(
        session: const AppEntrySession.restoring(),
        busy: false,
        clearUnavailableMode: true,
        clearFeedbackMessage: true,
      ),
    );
    final session = await _restoreAppEntrySession();
    if (session.status == AppEntrySessionStatus.failure) {
      log('Auth entry restore fell back to gate: ${session.failureMessage}');
    }
    emit(state.copyWith(session: session));
  }

  Future<void> continueAsGuest() async {
    emit(
      state.copyWith(
        busy: true,
        clearUnavailableMode: true,
        clearFeedbackMessage: true,
      ),
    );
    final session = await _continueAsGuest();
    log('Auth entry resolved as guest.');
    emit(state.copyWith(session: session, busy: false));
  }

  void onDisabledProviderTap(AppEntryMode entryMode) {
    final feedbackMessage = switch (entryMode) {
      AppEntryMode.google => 'google_coming_soon',
      AppEntryMode.apple => 'apple_coming_soon',
      _ => null,
    };
    if (feedbackMessage == null) {
      return;
    }
    log('Auth entry provider unavailable: $entryMode');
    emit(
      state.copyWith(
        unavailableMode: entryMode,
        feedbackMessage: feedbackMessage,
      ),
    );
  }

  Future<void> clearEntryState() async {
    await _clearAppEntryState();
    log('Auth entry state cleared.');
    emit(
      state.copyWith(
        session: const AppEntrySession.unresolved(),
        busy: false,
        clearUnavailableMode: true,
        clearFeedbackMessage: true,
      ),
    );
  }
}
