// test/features/settings/presentation/language_sheet_layout_test.dart
//
// 守住 showAppBottomSheet 的高度契約：最矮螢幕加最大字級下，最後一項仍完整可見。
// 預設的 9/16 高度只給 360dp，而清單需要 489dp，最後兩項會掉出畫面。

import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/core/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _tightestPhone = Size(360, 640);

const double _maxFontScale = 2.0;

void main() {
  testWidgets('語系清單在最矮螢幕＋最大字級下，最後一項仍完整可見', (tester) async {
    await tester.binding.setSurfaceSize(_tightestPhone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final langs = LocaleController.supportedLanguages;
    expect(langs, isNotEmpty, reason: '語系清單是空的，這個測試就沒有意義了');

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: _tightestPhone,
            textScaler: TextScaler.linear(_maxFontScale),
          ),
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppBottomSheet(
                  context: context,
                  builder: (_) => ListView(
                    shrinkWrap: true,
                    children: [
                      const ListTile(title: Text('follow-system')),
                      const Divider(height: 1),
                      for (final lang in langs)
                        ListTile(
                          leading: const Icon(Icons.translate),
                          title: Text(lang.endonym),
                        ),
                    ],
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    for (final lang in langs) {
      final finder = find.text(lang.endonym);
      expect(finder, findsOneWidget, reason: '${lang.endonym} 沒有被渲染');

      final rect = tester.getRect(finder);
      expect(
        rect.bottom,
        lessThanOrEqualTo(_tightestPhone.height),
        reason:
            '${lang.endonym} 落在畫面外（bottom=${rect.bottom.toStringAsFixed(1)} > '
            '${_tightestPhone.height}）。面板高度可能又被鎖成螢幕的 9/16——'
            '確認 showAppBottomSheet 仍有 isScrollControlled: true，'
            '且 maxHeightFactor 沒有被調小。',
      );
      expect(
        rect.top,
        greaterThanOrEqualTo(0),
        reason: '${lang.endonym} 被推出畫面上緣（top=${rect.top.toStringAsFixed(1)}）',
      );
    }
  });
}
