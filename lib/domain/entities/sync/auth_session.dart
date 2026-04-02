class AuthSession {
  final String? userId;
  final bool isSignedIn;

  const AuthSession._({
    required this.userId,
    required this.isSignedIn,
  });

  const AuthSession.signedOut() : this._(userId: null, isSignedIn: false);

  const AuthSession.signedIn(String userId)
    : this._(userId: userId, isSignedIn: true);
}
