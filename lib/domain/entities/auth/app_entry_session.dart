import 'package:equatable/equatable.dart';

enum AppEntrySessionStatus { restoring, unresolved, guest, authenticated, failure }

enum AppEntryMode { none, guest, google, apple }

class AppEntrySession extends Equatable {
  final AppEntrySessionStatus status;
  final AppEntryMode entryMode;
  final bool isResolved;
  final bool restoredFromStorage;
  final String? failureCode;
  final String? failureMessage;

  const AppEntrySession._({
    required this.status,
    required this.entryMode,
    required this.isResolved,
    required this.restoredFromStorage,
    this.failureCode,
    this.failureMessage,
  });

  const AppEntrySession.restoring()
    : this._(
        status: AppEntrySessionStatus.restoring,
        entryMode: AppEntryMode.none,
        isResolved: false,
        restoredFromStorage: false,
      );

  const AppEntrySession.unresolved({bool restoredFromStorage = false})
    : this._(
        status: AppEntrySessionStatus.unresolved,
        entryMode: AppEntryMode.none,
        isResolved: false,
        restoredFromStorage: restoredFromStorage,
      );

  const AppEntrySession.guest({bool restoredFromStorage = false})
    : this._(
        status: AppEntrySessionStatus.guest,
        entryMode: AppEntryMode.guest,
        isResolved: true,
        restoredFromStorage: restoredFromStorage,
      );

  const AppEntrySession.authenticated({
    required AppEntryMode entryMode,
    bool restoredFromStorage = false,
  }) : this._(
         status: AppEntrySessionStatus.authenticated,
         entryMode: entryMode,
         isResolved: true,
         restoredFromStorage: restoredFromStorage,
       );

  const AppEntrySession.failure({
    String? failureCode,
    String? failureMessage,
    bool restoredFromStorage = true,
  }) : this._(
         status: AppEntrySessionStatus.failure,
         entryMode: AppEntryMode.none,
         isResolved: false,
         restoredFromStorage: restoredFromStorage,
         failureCode: failureCode,
         failureMessage: failureMessage,
       );

  @override
  List<Object?> get props => [
    status,
    entryMode,
    isResolved,
    restoredFromStorage,
    failureCode,
    failureMessage,
  ];
}
