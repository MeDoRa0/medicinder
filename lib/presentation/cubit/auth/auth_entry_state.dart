import 'package:equatable/equatable.dart';

import '../../../domain/entities/auth/app_entry_session.dart';

class AuthEntryState extends Equatable {
  final AppEntrySession session;
  final bool busy;
  final AppEntryMode? inProgressMode;
  final AppEntryMode? unavailableMode;
  final String? feedbackCode;

  const AuthEntryState({
    required this.session,
    this.busy = false,
    this.inProgressMode,
    this.unavailableMode,
    this.feedbackCode,
  });

  const AuthEntryState.initial() : this(session: const AppEntrySession.restoring());

  AuthEntryState copyWith({
    AppEntrySession? session,
    bool? busy,
    AppEntryMode? inProgressMode,
    bool clearInProgressMode = false,
    AppEntryMode? unavailableMode,
    bool clearUnavailableMode = false,
    String? feedbackCode,
    bool clearFeedbackCode = false,
  }) {
    return AuthEntryState(
      session: session ?? this.session,
      busy: busy ?? this.busy,
      inProgressMode: clearInProgressMode
          ? null
          : inProgressMode ?? this.inProgressMode,
      unavailableMode: clearUnavailableMode
          ? null
          : unavailableMode ?? this.unavailableMode,
      feedbackCode: clearFeedbackCode
          ? null
          : feedbackCode ?? this.feedbackCode,
    );
  }

  @override
  List<Object?> get props => [
    session,
    busy,
    inProgressMode,
    unavailableMode,
    feedbackCode,
  ];
}
