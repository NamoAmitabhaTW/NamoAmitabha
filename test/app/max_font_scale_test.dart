// test/app/max_font_scale_test.dart
//
// 守住「平板放大倍率 × 使用者輔助字級」的乘積不爆版、不裁字。
// 文字被裁不會拋例外，所以除了看例外，還直接比對渲染後的字寬與格子寬。

import 'dart:io';
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:amitabha/core/layout/layout_scale.dart';
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/core/widgets/content_width.dart';
import 'package:amitabha/features/announcements/presentation/widgets/simple_markdown.dart';
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/background/domain/background_item.dart';
import 'package:amitabha/features/background/presentation/widgets/background_card.dart';
import 'package:amitabha/features/dedication/dedication.dart';
import 'package:amitabha/features/dedication/presentation/widgets/dedication_karaoke.dart';
import 'package:amitabha/features/records/records.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import '../helpers/asr_controller.dart';
import '../helpers/fake_path_provider.dart';
import '../helpers/real_fonts.dart';

const _androidMaxFontScale = 2.0;

const _iosDynamicType = <String, double>{
  '預設': 1.0,
  'AX1': 28 / 17,
  'AX2': 33 / 17,
  'AX3': 40 / 17,
  'AX4': 47 / 17,
  'AX5': 53 / 17,
};

const _iosMaxFontScale = 53 / 17;

const _tablets = <String, Size>{
  'iPad 直向': Size(820, 1180),
  'iPad 橫向': Size(1180, 820),
  'iPad mini': Size(744, 1133),
};

const _locales = <String, Locale>{
  'zh': Locale('zh', 'TW'),
  'en': Locale('en'),
  'ja': Locale('ja'),
  'ko': Locale('ko'),
  'vi': Locale('vi'),
  'de': Locale('de'),
  'fr': Locale('fr'),
};

Widget _app({
  required Widget home,
  required double fontScale,
  Locale locale = const Locale('zh', 'TW'),
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => fileBackedAsrController()),
    Provider(create: (_) => const RecordsController(FileDailyRepository())),
    ChangeNotifierProvider(create: (_) => LocaleController()),
    ChangeNotifierProvider(
      create: (_) => DedicationController(const FileDedicationPreferences()),
    ),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(fontScale)),
      child: child!,
    ),
    home: home,
  ),
);

void _sizeView(WidgetTester tester, Size logical) {
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
}

List<String> _clippedTexts(WidgetTester tester) {
  final clipped = <String>[];
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject;
    if (paragraph is! RenderParagraph || !paragraph.hasSize) continue;
    if (paragraph.size.width <= 0 || paragraph.size.height <= 0) continue;

    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      maxLines: paragraph.maxLines,
      textAlign: paragraph.textAlign,
      ellipsis: paragraph.overflow == TextOverflow.ellipsis ? '\u2026' : null,
    )..layout(maxWidth: paragraph.size.width);

    if (painter.height > paragraph.size.height + 0.5) {
      final text = paragraph.text.toPlainText();
      clipped.add(
        '「${text.length > 12 ? '${text.substring(0, 12)}…' : text}」'
        ' 高度 ${paragraph.size.height.toStringAsFixed(1)}'
        ' < 自然 ${painter.height.toStringAsFixed(1)}',
      );
    }
  }
  return clipped;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  late Directory tempRoot;
  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('max_font_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);

    await FileDailyRepository().addCount('20260908', 88888);
  });
  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  final backgroundItem = BackgroundItem(
    id: 'probe',
    name: '預設背景',
    type: BackgroundType.image,
    thumbnail: AppAssets.lotusDivider,
    isBuiltin: true,
  );

  final pages = <String, Widget>{
    '迴向頁': const DedicationScreen(),
    '記錄頁': const RecordsScreen(),
    '迴向偈編輯頁': const DedicationEditorScreen(),
    '公告內文': const Scaffold(
      body: SingleChildScrollView(
        child: SimpleMarkdown(
          data: '# 標題\n\n這是一段公告內文，用來測試排版。\n\n- 項目一\n- 項目二\n\n> 附註',
        ),
      ),
    ),
    '背景選擇卡片': Scaffold(
      body: Builder(
        builder: (context) {
          final s = layoutScale(context);
          return ContentWidth(
            maxWidth: 600 * s,
            child: ListView(
              padding: EdgeInsets.all(16 * s),
              children: [
                BackgroundCard(
                  item: backgroundItem,
                  isActive: false,
                  onDownload: () {},
                  onCancel: () {},
                  onUse: () {},
                  onDelete: () {},
                ),
              ],
            ),
          );
        },
      ),
    ),
  };

  // 每個頁面 × 平板 × 字級的組合，斷言不拋 overflow 例外。
  group('平板 × 最大輔助字級：不爆版', () {
    const devices = <String, Size>{..._tablets, 'iPhone 14': Size(390, 844)};
    for (final scale in [_androidMaxFontScale, _iosMaxFontScale]) {
      for (final page in pages.entries) {
        for (final device in devices.entries) {
          testWidgets('${page.key} @ ${device.key} x$scale', (tester) async {
            _sizeView(tester, device.value);
            await tester.runAsync(() async {
              await tester.pumpWidget(_app(home: page.value, fontScale: scale));
              await Future<void>.delayed(const Duration(milliseconds: 150));
            });
            await tester.pump(const Duration(milliseconds: 900));

            expect(
              tester.takeException(),
              isNull,
              reason: '${page.key} 在 ${device.key} × 字級 $scale 下爆版',
            );
            expect(
              _clippedTexts(tester),
              isEmpty,
              reason:
                  '${page.key} 在 ${device.key} × 字級 $scale 下有文字被'
                  '容器裁掉。容器高度要用 minHeight 而不是寫死的 height。',
            );
          });
        }
      }
    }
  });

  // 七語系全跑，涵蓋念佛、記錄、設定、迴向、公告、背景六個畫面。
  group('所有語系 × 最大字級：不爆版、不裁字', () {
    const devices = <String, Size>{
      'iPhone SE': Size(375, 667),
      'iPad 直向': Size(820, 1180),
    };

    for (final locale in _locales.entries) {
      for (final device in devices.entries) {
        for (final page in pages.entries) {
          testWidgets('${page.key} @ ${device.key} / ${locale.key}', (
            tester,
          ) async {
            _sizeView(tester, device.value);
            await tester.runAsync(() async {
              await tester.pumpWidget(
                _app(
                  home: page.value,
                  fontScale: _iosMaxFontScale,
                  locale: locale.value,
                ),
              );
              await Future<void>.delayed(const Duration(milliseconds: 150));
            });
            await tester.pump(const Duration(milliseconds: 900));

            expect(
              tester.takeException(),
              isNull,
              reason: '${page.key} / ${locale.key} 在 ${device.key} 爆版',
            );
            expect(
              _clippedTexts(tester),
              isEmpty,
              reason: '${page.key} / ${locale.key} 在 ${device.key} 有文字被裁',
            );
          });
        }
      }
    }
  });

  // 直接量測字寬與格子寬——這是唯一抓得到「安靜裁字」的方式。
  group('方塊字偈文：字不會被格子裁掉', () {
    ({double advance, double cell, double effective}) measure(
      WidgetTester tester,
      double fontScale,
    ) {
      final karaoke = find.byType(DedicationKaraoke);
      final row = find.descendant(of: karaoke, matching: find.byType(Row));
      const charsPerLine = 5;
      final cell = tester.getSize(row.first).width / charsPerLine;

      final textFinder = find.descendant(
        of: karaoke,
        matching: find.byType(RichText),
      );
      final paragraph = tester.firstRenderObject<RenderParagraph>(textFinder);
      final style = (paragraph.text as TextSpan).style!;

      final scaler = MediaQuery.textScalerOf(tester.firstElement(textFinder));
      final rendered = scaler.scale(style.fontSize!);

      return (
        advance: rendered + (style.letterSpacing ?? 0),
        cell: cell,
        effective: rendered / style.fontSize!,
      );
    }

    for (final device in <String, Size>{
      'iPad 直向': _tablets['iPad 直向']!,
      'iPhone 14': const Size(390, 844),
      'iPhone SE': const Size(375, 667),
    }.entries) {
      for (final level in _iosDynamicType.entries) {
        testWidgets('${device.key} × ${level.key}'
            '（x${level.value.toStringAsFixed(3)}）', (tester) async {
          _sizeView(tester, device.value);
          await tester.pumpWidget(
            _app(home: const DedicationScreen(), fontScale: level.value),
          );
          await tester.pump(const Duration(milliseconds: 900));

          final m = measure(tester, level.value);
          expect(
            m.advance,
            lessThanOrEqualTo(m.cell + 0.01),
            reason:
                '字寬 ${m.advance.toStringAsFixed(1)} 超過格子 '
                '${m.cell.toStringAsFixed(1)}，每個字都會被裁掉',
          );
        });
      }
    }

    testWidgets('平板不會被封頂（上限高於 iOS 能給的最大值）', (tester) async {
      _sizeView(tester, _tablets['iPad 直向']!);
      await tester.pumpWidget(
        _app(home: const DedicationScreen(), fontScale: _iosMaxFontScale),
      );
      await tester.pump(const Duration(milliseconds: 900));

      expect(
        measure(tester, _iosMaxFontScale).effective,
        moreOrLessEquals(_iosMaxFontScale, epsilon: 0.001),
        reason: '平板容得下 AX5，不該被封頂',
      );
    });

    testWidgets('手機在 AX5 會被封頂，而不是被裁掉', (tester) async {
      _sizeView(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(home: const DedicationScreen(), fontScale: _iosMaxFontScale),
      );
      await tester.pump(const Duration(milliseconds: 900));

      final m = measure(tester, _iosMaxFontScale);
      expect(
        m.effective,
        lessThan(_iosMaxFontScale),
        reason: '手機容不下 AX5，應該被封頂',
      );
      expect(
        m.effective,
        greaterThan(2.0),
        reason: '封頂值不該低於 Android 的最大字級，否則等於倒退',
      );
    });
  });
}
