/* //amitabha/lib/core/firebase_bootstrap.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseBootstrap {
  static FirebaseApp? _app;

  static bool get isReady => _app != null;

  static Future<void> ensureReady() async {
    if (_app != null) return;
    _app = await Firebase.initializeApp();
  }

  static Future<void> ensureAnonymousSignedIn() async {
    await ensureReady();
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }
} */