/* //amitabha/lib/features/auth/application/auth_facade.dart
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:amitabha/features/auth/domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_provider.dart';
import '../domain/auth_error.dart'; 
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

  Stream<fb.User?> authStateChanges() => auth.authStateChanges();
  Future<void> signOut() => auth.signOut();

  Future<void> deleteAccountAndData() async {
    final u = fb.FirebaseAuth.instance.currentUser;

    if (u == null) return;

    try {
      await users.deleteAllUserData(u.uid);
    } catch (_) {
      
    }
  
    try {
      await u.delete(); 
      return;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _reauth(u);       
        await u.delete();       
        return;
      }
      throw AuthException(AuthError.failed, e.message);
    }
  }

  Future<void> _reauth(fb.User u) async {
    final providers = u.providerData.map((p) => p.providerId).toList();

    if (providers.contains('google.com')) {
      final g = gsi.GoogleSignIn.instance;

      
      gsi.GoogleSignInAccount? account;
      final f = g.attemptLightweightAuthentication();
      if (f != null) {
        account = await f;
      }

      
      account ??= await g.authenticate(scopeHint: const ['email', 'profile']);

      final idToken = (await account.authentication).idToken;
      if (idToken == null) {
        throw const AuthException(AuthError.failed, '取回 Google idToken 失敗');
      }

      final cred = fb.GoogleAuthProvider.credential(idToken: idToken);
      await u.reauthenticateWithCredential(cred);
      return;
    }

    if (providers.contains('apple.com')) {
      final rawNonce = _randomNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );

      final cred = fb.OAuthProvider('apple.com')
          .credential(idToken: apple.identityToken, rawNonce: rawNonce);
      await u.reauthenticateWithCredential(cred);
      return;
    }

    
    throw const AuthException(
      AuthError.failed,
      '目前的登入方式無法自動重新驗證，請先重新登入後再試。',
    );
  }

  String _randomNonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = sha256.convert(utf8.encode(input)).bytes;
    return base64Url.encode(bytes).replaceAll('=', '');
  }
} */