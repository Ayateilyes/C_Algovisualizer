import 'package:firebase_auth/firebase_auth.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

/// The three possible authentication states for the app.
/// The app always starts as anonymous — there is never an unauthenticated state.
enum AuthStatus {
  /// Anonymous user — silently signed in, no personal data saved
  anonymous,

  /// Linked to Google — progress will be persisted under a real UID
  linked,

  /// Transitional — Google sign-in is in progress
  linking,
}

class AuthState {
  const AuthState({required this.status, this.user, this.errorMessage});

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  bool get isAnonymous => status == AuthStatus.anonymous;
  bool get isLinked => status == AuthStatus.linked;
  bool get isLinking => status == AuthStatus.linking;
  String? get uid => user?.uid;
  String? get displayName => user?.displayName;
  String? get email => user?.email;
  String? get photoUrl => user?.photoURL;

  AuthState copyWith({AuthStatus? status, User? user, String? errorMessage}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
      );

  @override
  String toString() => 'AuthState(status: $status, uid: $uid, email: $email)';
}
