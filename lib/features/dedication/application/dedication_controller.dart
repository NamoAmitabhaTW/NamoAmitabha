// lib/features/dedication/application/dedication_controller.dart
import 'package:amitabha/features/dedication/data/dedication_prefs.dart';
import 'package:amitabha/features/dedication/domain/dedication_gatha.dart';
import 'package:flutter/foundation.dart';

class DedicationController extends ChangeNotifier {
  final Map<String, String> _overrides = {};

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final m = await DedicationPrefs.loadOverrides();
      _overrides
        ..clear()
        ..addAll(m);
    } catch (e) {
      debugPrint('[dedication] load failed: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  String textFor(String languageCode) {
    final ov = _overrides[languageCode];
    if (ov != null && ov.trim().isNotEmpty) return ov;
    return defaultDedicationGatha(languageCode);
  }

  Future<void> saveFor(String languageCode, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty ||
        trimmed == defaultDedicationGatha(languageCode).trim()) {
      if (!_overrides.containsKey(languageCode)) return;
      _overrides.remove(languageCode);
    } else {
      if (_overrides[languageCode] == trimmed) return;
      _overrides[languageCode] = trimmed;
    }
    notifyListeners();
    try {
      await DedicationPrefs.saveOverrides(_overrides);
    } catch (e) {
      debugPrint('[dedication] save failed: $e');
    }
  }
}
