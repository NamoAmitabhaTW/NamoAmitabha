// test/features/settings/presentation/settings_screen_test.dart
// 最低限度的組裝檢查：設定頁與記錄頁在正常 Provider 組裝下畫得出來。
// 記錄頁另外確認空資料會落到空狀態——顯示「尚無紀錄」與 0 的統計卡，
// 而不是卡在轉圈圈。

import 'dart:io';
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/records/records.dart';
import 'package:amitabha/features/settings/presentation/screens/settings_screen.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import '../../../helpers/asr_controller.dart';
import '../../../helpers/fake_path_provider.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => fileBackedAsrController()),
      Provider(create: (_) => const RecordsController(FileDailyRepository())),
      ChangeNotifierProvider(create: (_) => LocaleController()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('namo_widget_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  testWidgets('SettingsScreen 顯示語言與背景設定項', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    final ctx = tester.element(find.byType(SettingsScreen));
    final t = AppLocalizations.of(ctx);

    expect(find.bySemanticsLabel(t.language), findsOneWidget);
    expect(find.bySemanticsLabel(t.bgScreenTitle), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('RecordsScreen 空資料時顯示「尚無紀錄」與統計卡', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(_wrap(const RecordsScreen()));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    final ctx = tester.element(find.byType(RecordsScreen));
    final t = AppLocalizations.of(ctx);

    expect(find.text(t.noRecords), findsOneWidget);
    expect(find.text('0'), findsWidgets);

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
