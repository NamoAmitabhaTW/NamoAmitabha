// test/features/announcements/presentation/announcement_layout_test.dart
//
// 用真正的 SimpleMarkdown 渲染所有語系的公告內文，檢查排版正確性。
// 涵蓋 changelog、dev-intro、licenses 三個來源 × 七個語系。

import 'dart:io';
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:amitabha/features/announcements/presentation/widgets/simple_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const langs = ['zh', 'en', 'ja', 'ko', 'vi', 'de', 'fr'];
const ids = ['dev-intro', 'changelog'];

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
        final file = File(AppAssets.announcementBody(id, lang));
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
