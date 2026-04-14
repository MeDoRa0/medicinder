import 'package:equatable/equatable.dart';

import '../../../data/datasources/auth/apple_auth_provider_data_source.dart';
import '../../../domain/entities/auth/app_entry_session.dart';

class AuthEntryState extends Equatable {
  final AppEntrySession session;
  final bool busy;
  final AppEntryMode? inProgressMode;
  final AppEntryMode? unavailableMode;
  final String? feedbackCode;
  final AppleAuthAvailability appleAvailability;

  const AuthEntryState({
    required this.session,
    this.busy = false,
    this.inProgressMode,
    this.unavailableMode,
    this.feedbackCode,
    this.appleAvailability = AppleAuthAvailability.unsupportedRunner,
  });

  const AuthEntryState.initial()
    : this(session: const AppEntrySession.restoring());

  AuthEntryState copyWith({
    AppEntrySession? session,
    bool? busy,
    AppEntryMode? inProgressMode,
    bool clearInProgressMode = false,
    AppEntryMode? unavailableMode,
    bool clearUnavailableMode = false,
    String? feedbackCode,
    bool clearFeedbackCode = false,
    AppleAuthAvailability? appleAvailability,
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
      appleAvailability: appleAvailability ?? this.appleAvailability,
    );
  }

  @override
  List<Object?> get props => [
    session,
    busy,
    inProgressMode,
    unavailableMode,
    feedbackCode,
    appleAvailability,
  ];
}
