import 'package:flutter/material.dart';
import 'app.dart';
import 'flavors.dart';

void main() {
  const flavorName = String.fromEnvironment('appFlavor', defaultValue: 'staging');
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == flavorName,
    orElse: () => Flavor.dev, 
  );
  runApp(const App());
}
