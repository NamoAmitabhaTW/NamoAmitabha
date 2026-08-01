// amitabha/lib/features/dedication/dedication_style.dart
import 'package:flutter/material.dart';

/// 迴向頁「暖紙泥金」設計語彙（顏色、字型）。
class DedicationStyle {
  // 明體（子集化字型）。日文用日文字形，其餘用繁中；跨語系互為 fallback，
  // 韓文諺文由 KR 明體補齊。
  static const String _tc = 'NotoSerifGatha';
  static const String _jp = 'NotoSerifGathaJP';
  static const String _kr = 'NotoSerifGathaKR';

  /// 依語系取得主要字型（日文優先日文字形）。
  static String fontFamilyFor(String lang) => lang == 'ja' ? _jp : _tc;

  /// 依語系取得 fallback 順序，補齊主要字型缺少的字。
  static List<String> fontFallbackFor(String lang) =>
      lang == 'ja' ? const [_tc, _kr] : const [_jp, _kr];

  // 暖紙：中心較亮、邊緣較深，帶光感。
  static const Color paperCenter = Color(0xFFFFFDF6);
  static const Color paperEdge = Color(0xFFEFE1C4);

  // 墨（未填字）。
  static const Color ink = Color(0xFF3A2E25);

  // 泥金（已填字 / 點綴 / 按鈕）。
  static const Color gold = Color(0xFFB2842E);
  static const Color goldLight = Color(0xFFDCB765);
  static const Color goldDeep = Color(0xFF8A6320);
}
