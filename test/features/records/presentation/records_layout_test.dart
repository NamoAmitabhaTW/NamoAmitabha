// test/features/records/presentation/records_layout_test.dart
//
// 守住記錄頁在平板上的字級會跟著畫布一起放大。
// 手機那條斷言最重要：縮放下限是 1.0，基準寬度上字級必須與加入縮放前完全相同。

import 'dart:io';
import 'package:amitabha/core/layout/layout_scale.dart';
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/records/records.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import '../../../helpers/asr_controller.dart';
import '../../../helpers/fake_path_provider.dart';
import '../../../helpers/real_fonts.dart';

const _dateSize = 19.0;
const _countSize = 32.0;
const _unitSize = 15.0;

const _iPhoneSE = Size(375, 667);
const _iPhone14 = Size(390, 844);
const _pixel7 = Size(412, 915);
const _iPhoneProMax = Size(440, 956);
const _iPadPortrait = Size(820, 1180);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('records_layout_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);

    final repo = FileDailyRepository();
    await repo.addCount('20260908', 81);
    await repo.addCount('20260909', 12345);
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  Future<void> pumpAt(WidgetTester tester, Size logical) async {
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

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => fileBackedAsrController()),
            Provider(
              create: (_) => const RecordsController(FileDailyRepository()),
            ),
            ChangeNotifierProvider(create: (_) => LocaleController()),
          ],
          child: MaterialApp(
            locale: const Locale('zh', 'TW'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RecordsScreen(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
  }

  final dateFinder = find.byWidgetPredicate(
    (w) => w is Text && (w.data ?? '').startsWith('2026/'),
  );

  final countFinder = find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains('12345'),
  );

  double dateFontSize(WidgetTester tester) =>
      tester.firstWidget<Text>(dateFinder).style!.fontSize!;

  List<TextSpan> leafSpans(InlineSpan root) {
    final out = <TextSpan>[];
    void walk(InlineSpan span) {
      if (span is! TextSpan) return;
      final children = span.children;
      if (children == null || children.isEmpty) {
        if ((span.text ?? '').isNotEmpty) out.add(span);
        return;
      }
      children.forEach(walk);
    }

    walk(root);
    return out;
  }

  (double, double) countFontSizes(WidgetTester tester) {
    final paragraph = tester.firstRenderObject<RenderParagraph>(countFinder);
    final spans = leafSpans(paragraph.text);
    return (spans[0].style!.fontSize!, spans[1].style!.fontSize!);
  }

  // 任何一個字級改回寫死的常數，這裡就會失敗。
  group('手機：版面縮放夾在 1.0，字級與加入縮放前完全相同', () {
    for (final (label, size) in [
      ('iPhone SE', _iPhoneSE),
      ('iPhone 14', _iPhone14),
      ('Pixel 7（412dp）', _pixel7),
      ('iPhone 16 Pro Max（440pt）', _iPhoneProMax),
    ]) {
      testWidgets(label, (tester) async {
        await pumpAt(tester, size);

        expect(dateFontSize(tester), _dateSize);
        final (count, unit) = countFontSizes(tester);
        expect(count, _countSize);
        expect(unit, _unitSize);
      });
    }
  });

  // 放大後不得誤觸 _RecordTile 的上下堆疊門檻。
  group('平板：字級跟著畫布一起放大', () {
    testWidgets('iPad 直向套用 $kDefaultMaxScale 倍', (tester) async {
      await pumpAt(tester, _iPadPortrait);

      expect(dateFontSize(tester), _dateSize * kDefaultMaxScale);
      final (count, unit) = countFontSizes(tester);
      expect(count, _countSize * kDefaultMaxScale);
      expect(unit, _unitSize * kDefaultMaxScale);
    });

    testWidgets('放大後不會誤觸上下堆疊', (tester) async {
      await pumpAt(tester, _iPadPortrait);

      expect(
        tester.getTopLeft(countFinder.first).dx,
        greaterThan(tester.getTopLeft(dateFinder.first).dx + 1),
        reason: '兩者左緣相同代表被拆成上下兩行了',
      );
    });
  });

  testWidgets('這頁不覆寫全 app 上限', (tester) async {
    await pumpAt(tester, _iPadPortrait);
    expect(dateFontSize(tester) / _dateSize, kDefaultMaxScale);
  });
}
