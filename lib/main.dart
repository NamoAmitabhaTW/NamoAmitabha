import 'package:flutter/material.dart';
import 'app.dart';
import 'flavors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] init skipped: $e');
  } 

  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('[Auth] Anonymous sign-in failed: $e');
  }

  const flavorName = String.fromEnvironment('appFlavor', defaultValue: 'debug');
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == flavorName,
    orElse: () => Flavor.dev,
  );
  runApp(const App());
}
