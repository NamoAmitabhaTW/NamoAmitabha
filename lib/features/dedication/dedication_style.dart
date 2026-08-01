// amitabha/lib/features/dedication/dedication_style.dart
import 'package:flutter/material.dart';

class DedicationStyle {
  static const String _tc = 'NotoSerifGatha';
  static const String _jp = 'NotoSerifGathaJP';
  static const String _kr = 'NotoSerifGathaKR';

  static String fontFamilyFor(String lang) => lang == 'ja' ? _jp : _tc;

  static List<String> fontFallbackFor(String lang) =>
      lang == 'ja' ? const [_tc, _kr] : const [_jp, _kr];

  static const Color paperCenter = Color(0xFFFFFDF6);
  static const Color paperEdge = Color(0xFFEFE1C4);
  static const Color ink = Color(0xFF3A2E25);
  static const Color gold = Color(0xFFB2842E);
  static const Color goldLight = Color(0xFFDCB765);
  static const Color goldDeep = Color(0xFF8A6320);
}
