// Smoke tests:驗證主要畫面能建立、本地化正常、空資料狀態正確。
//
// 說明:仍不 pump 整個 App()——ASR 已抽成 controller(P3),但
// ChantingBackground 的 video_player 在測試環境會碰原生 plugin channel。
// 完整 App smoke test 留待日後為 video 層加測試接縫時補上;
// controller 的行為已由 asr_session_controller_test.dart 覆蓋。
import 'dart:io';

import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/features/records/screens/records_screen.dart';
import 'package:amitabha/features/settings/screens/settings_screen.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_path_provider.dart';

/// 提供畫面需要的 Provider 與本地化環境。
Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AsrSessionController()),
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
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();

    // 用實際生效語系的字串來驗證,不與特定語言綁死
    final ctx = tester.element(find.byType(SettingsScreen));
    final t = AppLocalizations.of(ctx);

    expect(find.text(t.language), findsOneWidget);
    expect(find.text(t.bgScreenTitle), findsOneWidget);
  });

  testWidgets('RecordsScreen 空資料時顯示「尚無紀錄」與統計卡', (tester) async {
    // RecordsScreen 的 FutureBuilder 走真實檔案 IO,
    // 用 runAsync 讓 IO 在測試的 fake async 之外真正完成。
    await tester.runAsync(() async {
      await tester.pumpWidget(_wrap(const RecordsScreen()));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    final ctx = tester.element(find.byType(RecordsScreen));
    final t = AppLocalizations.of(ctx);

    // 空資料 → 顯示無紀錄文案,且統計卡的總數為 0
    expect(find.text(t.noRecords), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    // 載入完成 → 不應殘留進度圈
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}