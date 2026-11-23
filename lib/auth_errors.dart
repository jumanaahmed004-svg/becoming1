import 'package:firebase_auth/firebase_auth.dart';

/// Turns Firebase error codes into friendly messages.
String authMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'This email is already registered. Try logging in instead.';
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'network-request-failed':
      return 'No internet connection. Please try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'operation-not-allowed':
    case 'configuration-not-found':
      return 'Email sign-in is not enabled in Firebase yet.';
    default:
      return 'Something went wrong (${e.code}). Please try again.';
  }
}

final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
