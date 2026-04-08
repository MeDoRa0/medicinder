import 'package:equatable/equatable.dart';

import '../../../domain/entities/auth/app_entry_session.dart';

class AuthEntryState extends Equatable {
  final AppEntrySession session;
  final bool busy;
  final AppEntryMode? unavailableMode;
  final String? feedbackMessage;

  const AuthEntryState({
    required this.session,
    this.busy = false,
    this.unavailableMode,
    this.feedbackMessage,
  });

  const AuthEntryState.initial() : this(session: const AppEntrySession.restoring());

  AuthEntryState copyWith({
    AppEntrySession? session,
    bool? busy,
    AppEntryMode? unavailableMode,
    bool clearUnavailableMode = false,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return AuthEntryState(
      session: session ?? this.session,
      busy: busy ?? this.busy,
      unavailableMode: clearUnavailableMode
          ? null
          : unavailableMode ?? this.unavailableMode,
      feedbackMessage: clearFeedbackMessage
          ? null
          : feedbackMessage ?? this.feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [session, busy, unavailableMode, feedbackMessage];
}
