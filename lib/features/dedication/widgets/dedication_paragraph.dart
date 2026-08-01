// amitabha/lib/features/dedication/widgets/dedication_paragraph.dart
import 'package:flutter/material.dart';

const Set<String> kGathaPunct = {'，', '。', '、', '；', '：', '？', '！'};

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
