import 'package:flutter/material.dart';

const Set<String> kGathaPunct = {'，', '。', '、', '；', '：', '？', '！'};

/// 將多行文字切成：每行的「字格」清單，標點黏回前一字。
/// 供方塊字（中日韓）的等寬均分逐字填色排版使用。
List<List<String>> splitGathaLines(String src) {
  final lines = <List<String>>[];
  for (final raw in src.split('\n')) {
    final cells = <String>[];
    for (final ch in raw.characters) {
      if (kGathaPunct.contains(ch) && cells.isNotEmpty) {
        cells.last = '${cells.last}$ch';
      } else {
        cells.add(ch);
      }
    }
    lines.add(cells);
  }
  return lines;
}
