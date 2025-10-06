import 'package:flutter/material.dart';
import 'app.dart';
import 'flavors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signInAnonymously();

  const flavorName = String.fromEnvironment('appFlavor', defaultValue: 'staging');
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == flavorName,
    orElse: () => Flavor.dev, 
  );
  runApp(const App());
}
