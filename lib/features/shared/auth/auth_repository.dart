import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// All Firebase Auth calls are isolated here.
/// Notifiers call repository methods; widgets never touch Firebase directly.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Current Firebase user (may be anonymous or linked)
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Sign in anonymously. Should only be called once in main() before runApp.
  Future<void> signInAnonymously() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  /// Link the current anonymous account to Google.
  /// Returns null on success, or an error message string on failure.
  Future<String?> linkWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      await _auth.currentUser?.linkWithProvider(googleProvider);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('linkWithGoogle error: ${e.code} — ${e.message}');
      return _mapErrorCode(e.code);
    } catch (e) {
      debugPrint('linkWithGoogle unknown error: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Unlink Google from the current account (revert to pure anonymous).
  Future<String?> unlinkGoogle() async {
    try {
      await _auth.currentUser?.unlink(GoogleAuthProvider.PROVIDER_ID);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapErrorCode(e.code);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  /// Sign out (will lose progress if still anonymous).
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Returns true if the current user has a Google provider linked.
  bool get isLinkedToGoogle {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any(
      (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
  }

  String _mapErrorCode(String code) {
    switch (code) {
      case 'credential-already-in-use':
        return 'This Google account is already linked to another user.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'provider-already-linked':
        return 'Google is already linked to this account.';
      case 'no-such-provider':
        return 'Google is not linked to this account.';
      case 'cancelled':
      case 'sign_in_canceled':
        return 'Sign-in cancelled.';
      default:
        return 'Authentication failed: $code';
    }
  }
}
