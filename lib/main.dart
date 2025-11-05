//main.dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'flavors.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge：內容延伸到系統列
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 僅設定系統列「圖示」對比；顏色保持透明，交給內容 & Insets
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.dark,           // 視 UI 決定
    systemNavigationBarIconBrightness: Brightness.dark, // 視 UI 決定
  ));

  const flavorName = String.fromEnvironment('appFlavor', defaultValue: 'debug');
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == flavorName,
    orElse: () => Flavor.dev,
  );
  runApp(const App());
}