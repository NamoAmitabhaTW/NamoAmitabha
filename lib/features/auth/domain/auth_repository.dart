/* //amitabha/lib/features/auth/domain/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart' as fb;

abstract class AuthRepository {
  Future<fb.UserCredential> signInWithGoogle();
  Future<fb.UserCredential> signInWithApple();
  Future<void> signOut();
  Stream<fb.User?> authStateChanges();
} */