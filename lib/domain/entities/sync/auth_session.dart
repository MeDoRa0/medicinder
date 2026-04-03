enum AuthSessionStatus {
  signedOut,
  signingIn,
  signedIn,
  workspaceInitializing,
  ready,
  accessDenied,
  failed,
}

class AuthSession {
  final String? userId;
  final bool isSignedIn;
  final String? providerId;
  final bool workspaceReady;
  final AuthSessionStatus status;
  final String? failureCode;
  final String? failureMessage;

  const AuthSession._({
    required this.userId,
    required this.isSignedIn,
    required this.providerId,
    required this.workspaceReady,
    required this.status,
    this.failureCode,
    this.failureMessage,
  });

  const AuthSession.signedOut()
    : this._(
        userId: null,
        isSignedIn: false,
        providerId: null,
        workspaceReady: false,
        status: AuthSessionStatus.signedOut,
      );

  const AuthSession.signingIn({String? providerId})
    : this._(
        userId: null,
        isSignedIn: false,
        providerId: providerId,
        workspaceReady: false,
        status: AuthSessionStatus.signingIn,
      );

  const AuthSession.signedIn(String userId, {String? providerId})
    : this._(
        userId: userId,
        isSignedIn: true,
        providerId: providerId,
        workspaceReady: false,
        status: AuthSessionStatus.signedIn,
      );

  const AuthSession.workspaceInitializing(String userId, {String? providerId})
    : this._(
        userId: userId,
        isSignedIn: true,
        providerId: providerId,
        workspaceReady: false,
        status: AuthSessionStatus.workspaceInitializing,
      );

  const AuthSession.ready(String userId, {String? providerId})
    : this._(
        userId: userId,
        isSignedIn: true,
        providerId: providerId,
        workspaceReady: true,
        status: AuthSessionStatus.ready,
      );

  const AuthSession.accessDenied(
    String userId, {
    String? providerId,
    String? failureCode,
    String? failureMessage,
  }) : this._(
         userId: userId,
         isSignedIn: true,
         providerId: providerId,
         workspaceReady: false,
         status: AuthSessionStatus.accessDenied,
         failureCode: failureCode,
         failureMessage: failureMessage,
       );

  const AuthSession.failed({
    String? userId,
    String? providerId,
    String? failureCode,
    String? failureMessage,
  }) : this._(
         userId: userId,
         isSignedIn: userId != null,
         providerId: providerId,
         workspaceReady: false,
         status: AuthSessionStatus.failed,
         failureCode: failureCode,
         failureMessage: failureMessage,
       );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AuthSession &&
        other.userId == userId &&
        other.isSignedIn == isSignedIn &&
        other.providerId == providerId &&
        other.workspaceReady == workspaceReady &&
        other.status == status &&
        other.failureCode == failureCode &&
        other.failureMessage == failureMessage;
  }

  @override
  int get hashCode => Object.hash(
    userId,
    isSignedIn,
    providerId,
    workspaceReady,
    status,
    failureCode,
    failureMessage,
  );
}
