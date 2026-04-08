import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/auth/app_entry_session.dart';
import '../../../domain/usecases/auth/clear_app_entry_state.dart';
import '../../../domain/usecases/auth/continue_as_guest.dart';
import '../../../domain/usecases/auth/restore_app_entry_session.dart';
import '../../../domain/usecases/auth/sign_in_with_google.dart';
import 'auth_entry_state.dart';

class AuthEntryCubit extends Cubit<AuthEntryState> {
  final RestoreAppEntrySession _restoreAppEntrySession;
  final ContinueAsGuest _continueAsGuest;
  final ClearAppEntryState _clearAppEntryState;
  final SignInWithGoogle _signInWithGoogle;

  AuthEntryCubit({
    required RestoreAppEntrySession restoreAppEntrySession,
    required ContinueAsGuest continueAsGuest,
    required ClearAppEntryState clearAppEntryState,
    required SignInWithGoogle signInWithGoogle,
  }) : _restoreAppEntrySession = restoreAppEntrySession,
       _continueAsGuest = continueAsGuest,
       _clearAppEntryState = clearAppEntryState,
       _signInWithGoogle = signInWithGoogle,
       super(const AuthEntryState.initial());

  Future<void> restoreSession() async {
    emit(
      state.copyWith(
        session: const AppEntrySession.restoring(),
        busy: false,
        clearInProgressMode: true,
        clearUnavailableMode: true,
        clearFeedbackCode: true,
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
        clearInProgressMode: true,
        clearUnavailableMode: true,
        clearFeedbackCode: true,
      ),
    );
    final session = await _continueAsGuest();
    log('Auth entry resolved as guest.');
    emit(state.copyWith(session: session, busy: false));
  }

  void onDisabledProviderTap(AppEntryMode entryMode) {
    final feedbackMessage = switch (entryMode) {
      AppEntryMode.google => 'google_unavailable',
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
        feedbackCode: feedbackMessage,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    emit(
      state.copyWith(
        busy: true,
        inProgressMode: AppEntryMode.google,
        clearUnavailableMode: true,
        clearFeedbackCode: true,
      ),
    );
    log('Auth entry Google sign-in started.');
    final session = await _signInWithGoogle();
    if (session.status == AppEntrySessionStatus.authenticated) {
      log('Auth entry Google sign-in succeeded.');
      emit(
        state.copyWith(
          session: session,
          busy: false,
          clearInProgressMode: true,
        ),
      );
      return;
    }

    final feedbackCode = session.failureCode ?? 'GOOGLE_SIGN_IN_FAILED';
    log('Auth entry Google sign-in ended with code=$feedbackCode');
    emit(
      state.copyWith(
        session: const AppEntrySession.unresolved(),
        busy: false,
        clearInProgressMode: true,
        feedbackCode: feedbackCode,
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
        clearInProgressMode: true,
        clearUnavailableMode: true,
        clearFeedbackCode: true,
      ),
    );
  }
}
