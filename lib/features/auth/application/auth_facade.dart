import 'package:amitabha/features/auth/domain/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../domain/auth_repository.dart';
import '../domain/auth_provider.dart';
import '../data/firestore_user_repository.dart';


class AuthFacade {
  final AuthRepository auth;
  final FirestoreUserRepository users;

  AuthFacade({required this.auth, required this.users});

  Future<fb.UserCredential> signInWithGoogle() async {
    final cred = await auth.signInWithGoogle();
    final u = cred.user;
    if (u != null) {
      final appUser = AppUser.fromFirebaseUser(u, primary: AuthProvider.google);
      await users.upsertUserDocFromModel(appUser);
    }
    return cred;
  }

  Future<fb.UserCredential> signInWithApple() async {
    final cred = await auth.signInWithApple();
    final u = cred.user;
    if (u != null) {
      final appUser = AppUser.fromFirebaseUser(u, primary: AuthProvider.apple);
      await users.upsertUserDocFromModel(appUser);
    }
    return cred;
  }
}