// lib/features/dedication/domain/dedication_preferences.dart
abstract class DedicationPreferences {
  Future<Map<String, String>> loadOverrides();

  Future<void> saveOverrides(Map<String, String> overrides);
}
