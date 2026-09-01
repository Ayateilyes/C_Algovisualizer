import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Watches Firebase auth state changes and exposes link/unlink actions.
/// Business logic only — no Firebase calls directly; delegates to AuthRepository.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo)
    : super(
        AuthState(
          status: _resolveStatus(_repo.currentUser),
          user: _repo.currentUser,
        ),
      ) {
    // Subscribe to real-time auth state changes from Firebase
    _subscription = _repo.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _repo;
  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _onAuthChanged(User? user) {
    if (user == null) {
      // Shouldn't normally happen — app always has anon user
      state = const AuthState(status: AuthStatus.anonymous);
      return;
    }
    state = AuthState(
      status: _resolveStatus(user),
      user: user,
      errorMessage: null,
    );
  }

  static AuthStatus _resolveStatus(User? user) {
    if (user == null) return AuthStatus.anonymous;
    final hasGoogle = user.providerData.any(
      (p) => p.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
    return hasGoogle ? AuthStatus.linked : AuthStatus.anonymous;
  }

  /// Link the anonymous account to Google.
  /// Triggers the Google sign-in popup/redirect.
  Future<void> linkWithGoogle() async {
    // Set linking state so UI shows a loading indicator
    state = state.copyWith(status: AuthStatus.linking);

    final error = await _repo.linkWithGoogle();

    if (error != null) {
      // Revert to previous status on failure
      state = AuthState(
        status: _resolveStatus(_repo.currentUser),
        user: _repo.currentUser,
        errorMessage: error,
      );
    }
    // On success, _onAuthChanged fires automatically from the stream
  }

  /// Unlink Google (revert to anonymous).
  Future<void> unlinkGoogle() async {
    final error = await _repo.unlinkGoogle();
    if (error != null) {
      state = state.copyWith(errorMessage: error);
    }
  }

  /// Clear any error message after it has been shown to the user.
  void clearError() => state = state.copyWith(errorMessage: null);
}
