// test/tablet_scale_test.dart
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:amitabha/core/layout/layout_scale.dart';
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/features/announcements/widgets/simple_markdown.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/features/background/background_item.dart';
import 'package:amitabha/features/background/widgets/background_card.dart';
import 'package:amitabha/features/dedication/dedication_controller.dart';
import 'package:amitabha/features/dedication/screens/dedication_editor_screen.dart';
import 'package:amitabha/features/settings/screens/settings_screen.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'helpers/real_fonts.dart';

const _phoneWidths = <String, double>{
  'Android 小螢幕 360dp': 360,
  'iPhone SE 375pt': 375,
  'iPhone 14 390pt': 390,
  'Pixel 7 412dp': 412,
  'iPhone 16 Pro Max 440pt': 440,
  '平板斷點邊界 600': 600,
};

const _tablet = Size(820, 1180);

Future<void> _pumpAt(WidgetTester tester, Size logical, Widget child) async {
  tester.view
    ..devicePixelRatio = 2.0
    ..physicalSize = logical * 2.0;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh', 'TW'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
  await tester.pump();
}

double? _innerFontSize(InlineSpan? root) {
  if (root is! TextSpan) return null;
  TextSpan? node = root;
  double? size;
  while (node != null) {
    if (node.style?.fontSize != null) size = node.style!.fontSize;
    final children = node.children;
    if (children == null || children.isEmpty) break;
    final first = children.first;
    node = first is TextSpan ? first : null;
  }
  return size;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  group('layoutScale 契約', () {
    Future<double> scaleAt(WidgetTester tester, double shortestSide) async {
      late double result;
      await _pumpAt(
        tester,
        Size(shortestSide, shortestSide * 2),
        Builder(
          builder: (context) {
            result = layoutScale(context);
            return const SizedBox();
          },
        ),
      );
      return result;
    }

    _phoneWidths.forEach((label, width) {
      testWidgets('$label 恆為 1.0', (tester) async {
        expect(await scaleAt(tester, width), 1.0);
      });
    });

    testWidgets('平板從斷點線性升到上限，不是一過斷點就跳滿', (tester) async {
      final mini = await scaleAt(tester, 744);
      final ipad = await scaleAt(tester, 820);
      final big = await scaleAt(tester, 1024);

      expect(ipad, kDefaultMaxScale);
      expect(big, kDefaultMaxScale, reason: '超過 kFullScaleWidth 應夾在上限');
      expect(mini, greaterThan(1.0), reason: '小平板也該放大，只是幅度較小');
      expect(mini, lessThan(kDefaultMaxScale), reason: '小平板不該和 12.9 吋放一樣多');
    });
  });

  group('公告內文 markdown', () {
    const base = 18.0;

    Future<List<double>> sizes(
      WidgetTester tester,
      Size s,
      double scale,
    ) async {
      await _pumpAt(
        tester,
        s,
        Scaffold(
          body: SingleChildScrollView(
            child: SimpleMarkdown(
              data: '# 標題\n\n內文段落\n\n> 附註',
              baseFontSize: base,
              scale: scale,
            ),
          ),
        ),
      );

      final out = <double>[
        for (final p in tester.renderObjectList<RenderParagraph>(
          find.byType(RichText),
        ))
          ?_innerFontSize(p.text),
        for (final w in tester.widgetList<SelectableText>(
          find.byType(SelectableText),
        ))
          ?_innerFontSize(w.textSpan),
      ];
      return out;
    }

    testWidgets('scale=1 時與加入縮放前完全相同', (tester) async {
      final got = await sizes(tester, const Size(390, 844), 1.0);

      expect(got, containsAll(<double>[base + 6, base, base - 4]));
    });

    testWidgets('平板倍率下標題階層等比放大，不會被壓扁', (tester) async {
      final got = await sizes(tester, _tablet, kDefaultMaxScale);
      expect(
        got,
        containsAll(<double>[
          (base + 6) * kDefaultMaxScale,
          base * kDefaultMaxScale,
          (base - 4) * kDefaultMaxScale,
        ]),
        reason: '只放大基準、不放大 ±N 的位移，標題階層會在平板上被壓扁',
      );
    });
  });

  group('背景卡片', () {
    const titleSize = 20.0;
    const btnSize = 16.0;

    BackgroundItem item() => BackgroundItem(
      id: 'test',
      name: '測試背景',
      type: BackgroundType.image,
      thumbnail: AppAssets.lotusDivider,
      isBuiltin: true,
    );

    Future<void> pumpCard(WidgetTester tester, Size s) => _pumpAt(
      tester,
      s,
      Scaffold(
        body: Center(
          child: BackgroundCard(
            item: item(),
            isActive: false,
            onDownload: () {},
            onCancel: () {},
            onUse: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    double titleFontSize(WidgetTester tester) =>
        tester.widget<Text>(find.text('測試背景')).style!.fontSize!;

    _phoneWidths.forEach((label, width) {
      testWidgets('$label 卡片字級不變', (tester) async {
        await pumpCard(tester, Size(width, width * 2));
        expect(titleFontSize(tester), titleSize);
      });
    });

    testWidgets('平板卡片字級與按鈕字級一起放大', (tester) async {
      await pumpCard(tester, _tablet);
      expect(titleFontSize(tester), titleSize * kDefaultMaxScale);

      final btn =
          tester
                  .widgetList<Widget>(
                    find.byWidgetPredicate((w) => w is OutlinedButton),
                  )
                  .first
              as OutlinedButton;
      final style = btn.style!.textStyle!.resolve({});
      expect(style!.fontSize, btnSize * kDefaultMaxScale);
    });
  });

  group('語系底部彈窗', () {
    Future<double> tileFontSize(WidgetTester tester, Size logical) async {
      tester.view
        ..devicePixelRatio = 2.0
        ..physicalSize = logical * 2.0;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AsrSessionController()),
            ChangeNotifierProvider(create: (_) => LocaleController()),
          ],
          child: MaterialApp(
            locale: const Locale('zh', 'TW'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump();

      final t = AppLocalizations.of(
        tester.element(find.byType(SettingsScreen)),
      );

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Image && w.semanticLabel == t.language,
        ),
        warnIfMissed: false,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      return tester
          .widgetList<ListTile>(find.byType(ListTile))
          .first
          .titleTextStyle!
          .fontSize!;
    }

    const materialBodyLarge = 16.0;

    testWidgets('手機維持 Material 預設字級', (tester) async {
      expect(
        await tileFontSize(tester, const Size(390, 844)),
        materialBodyLarge,
      );
    });

    testWidgets('平板放大 $kDefaultMaxScale 倍', (tester) async {
      expect(
        await tileFontSize(tester, _tablet),
        materialBodyLarge * kDefaultMaxScale,
      );
    });
  });

  group('迴向偈編輯頁', () {
    const titleSize = 22.0;
    const cjkVerseSize = 30.0;

    Future<void> pumpEditor(WidgetTester tester, Size s) async {
      tester.view
        ..devicePixelRatio = 2.0
        ..physicalSize = s * 2.0;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => DedicationController(),
          child: MaterialApp(
            locale: const Locale('zh', 'TW'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DedicationEditorScreen(),
          ),
        ),
      );
      await tester.pump();
    }

    double editFontSize(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).style!.fontSize!;

    double titleFontSize(WidgetTester tester) =>
        tester.widget<Text>(find.text('編輯迴向偈')).style!.fontSize!;

    _phoneWidths.forEach((label, width) {
      testWidgets('$label 編輯區字級不變', (tester) async {
        await pumpEditor(tester, Size(width, width * 2));
        expect(editFontSize(tester), cjkVerseSize);
      });
    });

    testWidgets('平板編輯區與標題一起放大', (tester) async {
      await pumpEditor(tester, _tablet);
      expect(editFontSize(tester), cjkVerseSize * kDefaultMaxScale);
      expect(titleFontSize(tester), titleSize * kDefaultMaxScale);
    });

    testWidgets('編輯區字級與迴向顯示頁一致（所見即所得）', (tester) async {
      await pumpEditor(tester, _tablet);
      expect(editFontSize(tester), cjkVerseSize * kDefaultMaxScale);
    });
  });
}
