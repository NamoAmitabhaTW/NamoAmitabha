/* //amitabha/lib/features/auth/data/firebase_auth_repository.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/services.dart' show PlatformException;
import '../domain/auth_error.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance; 
  final gsi.GoogleSignIn _gsi = gsi.GoogleSignIn.instance;
  
  // ===== Google =====
  @override
  Future<fb.UserCredential> signInWithGoogle() async {
    try {
      gsi.GoogleSignInAccount? account;
      final f = _gsi.attemptLightweightAuthentication();
      if (f != null) {
        account = await f;
      }

      account ??= await _gsi.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final idToken = account.authentication.idToken;

      final cred = fb.GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: null,
      );
      return await _auth.signInWithCredential(cred);
    } on gsi.GoogleSignInException catch (e) {
      if (e.code == gsi.GoogleSignInExceptionCode.canceled) {
        throw const AuthException(AuthError.cancelled);
      }
      throw const AuthException(AuthError.failed);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const AuthException(AuthError.network);
      }
      throw const AuthException(AuthError.failed);
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('network'))
        throw const AuthException(AuthError.network);
      if (code.contains('canceled') || code.contains('cancelled')) {
        throw const AuthException(AuthError.cancelled);
      }
      throw const AuthException(AuthError.failed);
    }
  }

  // ===== Apple =====
  Future<fb.UserCredential> signInWithApple() async {
    final rawNonce = _randomNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCred = fb.OAuthProvider(
      'apple.com',
    ).credential(idToken: apple.identityToken, rawNonce: rawNonce);
    final cred = await _auth.signInWithCredential(oauthCred);

    final displayName = [
      apple.givenName ?? '',
      apple.familyName ?? '',
    ].where((s) => s.isNotEmpty).join(' ').trim();

    if (displayName.isNotEmpty &&
        cred.user != null &&
        cred.user!.displayName == null) {
      await cred.user!.updateDisplayName(displayName);
    }
    return cred;
  }

  String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rnd = Random.secure();
    return List.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = sha256.convert(utf8.encode(input)).bytes;
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<void> signOut() async {
    try {
      await _gsi.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();
}
 */