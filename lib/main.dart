//main.dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'flavors.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge：內容延伸到系統列
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  const flavorName = String.fromEnvironment('appFlavor', defaultValue: 'debug');
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == flavorName,
    orElse: () => Flavor.dev,
  );
  runApp(const App());
}
