// test/dedication_layout_test.dart
import 'package:amitabha/features/dedication/dedication_controller.dart';
import 'package:amitabha/features/dedication/dedication_gatha.dart';
import 'package:amitabha/features/dedication/screens/dedication_screen.dart';
import 'package:amitabha/features/dedication/widgets/dedication_karaoke.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'helpers/real_fonts.dart';

const _iPhone = Size(390, 844);
const _iPadPortrait = Size(820, 1180);

const _baseFontSize = 30.0;
const _baseLetterSpacing = 3.0;

const _cellToGlyph = 2.0;

const _zhTw = Locale('zh', 'TW');

TextStyle _verseStyle(double scale) => TextStyle(
  fontSize: _baseFontSize * scale,
  height: 1.5,
  letterSpacing: _baseLetterSpacing * scale,
);

Future<void> _pumpKaraoke(
  WidgetTester tester, {
  required String text,
  required String lang,
  required double width,
  double scale = 1.0,
}) async {
  final style = _verseStyle(scale);

  tester.view
    ..devicePixelRatio = 1.0
    ..physicalSize = Size(width + 200, 1800);
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: DedicationKaraoke(
              text: text,
              languageCode: lang,
              baseStyle: style,
              fillStyle: style,
              rowSpacing: 12 * scale,
              scale: scale,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpScreen(WidgetTester tester, Size logical) async {
  tester.view
    ..devicePixelRatio = 2.0
    ..physicalSize = logical * 2.0
    ..padding = const FakeViewPadding(top: 48, bottom: 40);
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio()
      ..resetPadding();
  });

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => DedicationController(),
      child: MaterialApp(
        locale: _zhTw,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DedicationScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 800));
}

TextStyle? _verseSpanStyle(RenderParagraph p) {
  final root = p.text;
  if (root is! TextSpan) return null;
  TextSpan? node = root;
  TextStyle? innermost;
  while (node != null) {
    if (node.style != null) innermost = node.style;
    final children = node.children;
    if (children == null || children.isEmpty) break;
    final first = children.first;
    node = first is TextSpan ? first : null;
  }
  return innermost;
}

List<RenderParagraph> _versePargraphs(WidgetTester tester) => tester
    .renderObjectList<RenderParagraph>(
      find.descendant(
        of: find.byType(DedicationKaraoke),
        matching: find.byType(RichText),
      ),
    )
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  group('方塊字：行寬鎖在字寬的固定比例', () {
    for (final (label, width, scale) in [
      ('手機基準', 334.0, 1.0),
      ('平板直向', 736.0, 1.5),
      ('更寬的視窗', 1100.0, 1.5),
    ]) {
      testWidgets('$label：每格寬 = 單字寬 × $_cellToGlyph', (tester) async {
        await _pumpKaraoke(
          tester,
          text: kGathaZh,
          lang: 'zh',
          width: width,
          scale: scale,
        );

        final row = find.descendant(
          of: find.byType(DedicationKaraoke),
          matching: find.byType(Row),
        );
        final rowWidth = tester.getSize(row.first).width;

        const charsPerLine = 5;
        final glyph = (_baseFontSize + _baseLetterSpacing) * scale;
        expect(
          rowWidth / charsPerLine / glyph,
          moreOrLessEquals(_cellToGlyph, epsilon: 0.01),
          reason: '每格寬 ÷ 單字寬應固定，否則螢幕愈寬字距愈鬆',
        );
      });
    }

    testWidgets('可用寬度小於上限時，不會撐破父層', (tester) async {
      await _pumpKaraoke(tester, text: kGathaZh, lang: 'zh', width: 200);
      final row = find.descendant(
        of: find.byType(DedicationKaraoke),
        matching: find.byType(Row),
      );
      expect(tester.getSize(row.first).width, lessThanOrEqualTo(200));
    });
  });

  group('迴向頁：八行中文偈文放得下且垂直置中', () {
    for (final (label, size) in [
      ('iPhone', _iPhone),
      ('iPad 直向', _iPadPortrait),
    ]) {
      testWidgets('$label 不需捲動，且上下留白相等', (tester) async {
        await _pumpScreen(tester, size);

        final karaoke = find.byType(DedicationKaraoke);
        final scroller = find.byType(SingleChildScrollView);
        final content = tester.getSize(karaoke);
        final viewport = tester.getSize(scroller);

        expect(
          content.height,
          lessThanOrEqualTo(viewport.height),
          reason: '偈文超出視窗就必須捲動才讀得完，_maxScale 開太大了',
        );

        final top =
            tester.getTopLeft(karaoke).dy - tester.getTopLeft(scroller).dy;
        final bottom = viewport.height - top - content.height;
        expect(
          top,
          moreOrLessEquals(bottom, epsilon: 1.0),
          reason: '放得下時應垂直置中，而不是靠頂、留白全積在底部',
        );
      });
    }

    testWidgets('標題有明確行高（垂直預算才算得準）', (tester) async {
      await _pumpScreen(tester, _iPadPortrait);
      final title = tester.widget<Text>(find.text('迴向偈'));
      expect(
        title.style?.height,
        isNotNull,
        reason: '標題行高若交給字型度量決定，_maxScale 的垂直預算就無法計算',
      );
    });
  });

  group('拉丁排版', () {
    testWidgets('不吃方塊字的字距', (tester) async {
      await _pumpKaraoke(tester, text: kGathaVi, lang: 'vi', width: 900);
      final style = _verseSpanStyle(_versePargraphs(tester).first);
      expect(style?.letterSpacing, 0, reason: '為方塊字訂的字距套到拉丁字母上會拆散單字、白白吃掉行寬');
    });

    testWidgets('越南文逐句成行，不被自然換行拆開', (tester) async {
      const width = 900.0;
      await _pumpKaraoke(tester, text: kGathaVi, lang: 'vi', width: width);

      final paragraphs = _versePargraphs(tester);
      expect(
        paragraphs.length,
        kGathaVi.split('\n').length,
        reason: '每一句應各自成為一個段落',
      );
      for (final p in paragraphs) {
        expect(p.didExceedMaxLines, isFalse, reason: '句子被截斷了');
        expect(
          p.size.width,
          lessThanOrEqualTo(width + 0.5),
          reason: '句子溢出可用寬度',
        );
      }
    });

    testWidgets('放不下時整塊等比縮小，各句字級仍一致', (tester) async {
      const width = 400.0;
      await _pumpKaraoke(tester, text: kGathaVi, lang: 'vi', width: width);

      final paragraphs = _versePargraphs(tester);
      expect(paragraphs.length, kGathaVi.split('\n').length);

      final sizes = paragraphs.map((p) => _verseSpanStyle(p)?.fontSize).toSet();
      expect(sizes.length, 1, reason: '偈頌各句字級必須一致，不能只縮過長的那一句');
      expect(sizes.single, lessThan(22.0), reason: '這個寬度應該要縮才放得下');

      for (final p in paragraphs) {
        expect(p.size.width, lessThanOrEqualTo(width + 0.5));
      }
    });

    testWidgets('縮到下限仍放不下時，改回自然換行', (tester) async {
      await _pumpKaraoke(tester, text: kGathaVi, lang: 'vi', width: 200);

      expect(_versePargraphs(tester).length, 1, reason: '縮到看不清比斷句更糟，到下限就該改回換行');
    });

    testWidgets('英譯是散文，維持整段自然換行', (tester) async {
      await _pumpKaraoke(tester, text: kGathaEn, lang: 'en', width: 900);
      expect(
        _versePargraphs(tester).length,
        1,
        reason: '英譯段落間有空行、換行位置無所謂，不該被當成逐句偈頌',
      );
    });
  });
}
