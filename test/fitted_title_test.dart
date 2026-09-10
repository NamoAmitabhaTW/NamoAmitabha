import 'package:amitabha/core/widgets/fitted_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const double _minFontSize = 14;

const _realTitles = {
  'de': 'Rezitations-Hintergrund',
  'fr': 'Arrière-plan de récitation',
  'en': 'Chanting Background',
  'vi': 'Hình nền niệm Phật',
  'zh': '念佛背景',
};

Future<RenderParagraph> _pump(
  WidgetTester tester,
  String text, {
  required double width,
  required double fontScale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(fontScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: FittedTitle(text, minFontSize: _minFontSize),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.renderObject<RenderParagraph>(find.byType(RichText));
}

double _renderedFontSize(WidgetTester tester, RenderParagraph para) {
  final declared = para.text.style?.fontSize ?? 0;
  final fitted = find.byType(FittedBox);
  if (fitted.evaluate().isEmpty) {
    return declared;
  }

  final box = tester.renderObject<RenderBox>(fitted);
  final scale = box.size.width / para.size.width;
  return para.textScaler.scale(declared) * scale;
}

void main() {
  group('空間足夠時：等比縮小塞下，不出現「…」', () {
    for (final entry in _realTitles.entries) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        testWidgets('${entry.key} @ 字級 $scale', (tester) async {
          final width = entry.value.length * _minFontSize * 1.1;
          final para = await _pump(
            tester,
            entry.value,
            width: width,
            fontScale: scale,
          );

          expect(
            para.didExceedMaxLines,
            isFalse,
            reason:
                '「${entry.value}」(${entry.key}) 在字級 $scale 被截斷成「…」，'
                '但寬度足夠讓它縮到下限之上。FittedTitle 應該先等比縮小，'
                '只有縮到 $_minFontSize 仍塞不下才可截斷。',
          );
        });
      }
    }
  });

  testWidgets('空間不足時：停在下限並截斷，不無底線縮小', (tester) async {
    const absurd =
        'Ein außergewöhnlich langer Titel der niemals in eine AppBar passt';

    final para = await _pump(tester, absurd, width: 200, fontScale: 1.0);

    expect(para.didExceedMaxLines, isTrue, reason: '縮到下限仍塞不下時應該截斷');
    expect(
      para.text.style?.fontSize,
      _minFontSize,
      reason:
          '截斷時字級應停在下限 $_minFontSize，實際為 ${para.text.style?.fontSize}。'
          '低於下限代表仍在無底線縮小，標題會小到看不清。',
    );
  });

  testWidgets('不變量：任何寬度與字級組合下，實際字級都不低於下限', (tester) async {
    for (final text in _realTitles.values) {
      for (final width in const [60.0, 120.0, 240.0, 480.0, 960.0]) {
        for (final scale in const [1.0, 1.3, 2.0]) {
          final para = await _pump(
            tester,
            text,
            width: width,
            fontScale: scale,
          );
          final rendered = _renderedFontSize(tester, para);

          expect(
            rendered,
            greaterThanOrEqualTo(_minFontSize - 0.01),
            reason:
                '「$text」在寬度 $width、字級 $scale 下被縮到 '
                '${rendered.toStringAsFixed(2)}，低於可讀下限 $_minFontSize。',
          );
        }
      }
    }
  });
}
