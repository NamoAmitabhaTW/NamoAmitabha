//main.dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'flavors.dart';

void main() async {
  final bootT0 = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    debugPrint('[startup] first frame in ${DateTime.now().difference(bootT0).inMilliseconds} ms');
  });
  const flavorName = String.fromEnvironment('appFlavor', defaultValue: 'debug');
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == flavorName,
    orElse: () => Flavor.dev,
  );
  runApp(const App());
}
