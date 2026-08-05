// 用真正的 SimpleMarkdown 渲染所有語系的公告內文，檢查排版正確性：
// - 不拋例外（渲染不崩）
// - 每個來源的「- 項目」都渲染成項目符號（清單沒被誤判為段落）
// - 畫面上沒有殘留未解析的 ** / * 標記
import 'dart:io';

import 'package:amitabha/features/announcements/widgets/simple_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const langs = ['zh', 'en', 'ja', 'ko', 'vi', 'de', 'fr'];
const ids = ['dev-intro', 'changelog'];

/// 遞迴收集畫面上所有可見文字（Text / Text.rich / SelectableText.rich）。
String _visibleText(WidgetTester tester) {
  final buf = StringBuffer();
  for (final el in find.byType(RichText).evaluate()) {
    final rt = el.widget as RichText;
    buf.write(rt.text.toPlainText());
    buf.write('\n');
  }
  return buf.toString();
}

void main() {
  for (final id in ids) {
    for (final lang in langs) {
      testWidgets('$id/$lang layout', (tester) async {
        final file = File('assets/announcements/$id/$lang.md');
        expect(file.existsSync(), true, reason: 'missing ${file.path}');
        final data = file.readAsStringSync();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SimpleMarkdown(
                  data: data,
                  accentColor: const Color(0xFF8A6320),
                ),
              ),
            ),
          ),
        );
        // pumpWidget 若渲染丟例外，測試會在此失敗。

        // (1) 每個來源的清單列都應渲染成一個「•」符號。
        final sourceBullets = data
            .split('\n')
            .where((l) => RegExp(r'^\s*[-*•]\s+').hasMatch(l))
            .length;
        final renderedBullets = find.text('•').evaluate().length;
        expect(
          renderedBullets,
          sourceBullets,
          reason:
              '$id/$lang: 項目符號 rendered=$renderedBullets, source=$sourceBullets '
              '（不符代表某個清單區塊被誤判成段落）',
        );

        // (2) 畫面上不應殘留未解析的粗體/強調標記。
        final visible = _visibleText(tester);
        expect(
          visible.contains('**'),
          false,
          reason: '$id/$lang: 畫面殘留未解析的 ** 標記',
        );
      });
    }
  }
}
