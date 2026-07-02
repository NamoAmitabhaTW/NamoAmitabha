//app.dart
import 'package:amitabha/core/core/theme/theme_controller.dart';
import 'package:amitabha/features/background/background_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
/* import 'flavors.dart'; */
import 'download_model.dart';
/* import 'features/auth/application/auth_facade.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/firestore_user_repository.dart'; */
import 'l10n/generated/app_localizations.dart';
import 'package:amitabha/home/presentation/home_shell.dart';
import 'package:amitabha/app/application/app_state.dart';
import 'core/localization/locale_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadModel()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => BackgroundController()..load(),
          lazy: false,
        ),
      ],
      child: Builder(
        builder: (context) {
          // 由 LocaleController 取得目前選擇；null 代表「跟隨系統」
          final locale = context.watch<LocaleController>().locale;
          final themeData = context.watch<ThemeController>().themeData;
          return MaterialApp(
            locale: locale, // null => 跟隨系統
            // 把所有「繁體」系統語系統一映射到 zh_TW
            localeListResolutionCallback: (locales, supported) {
              final prefs = locales ?? const <Locale>[];

              // 按使用者偏好順序，逐一嘗試匹配
              for (final l in prefs) {
                // 中文：統一各種繁體寫法到 zh-TW
                if (l.languageCode == 'zh') {
                  if (l.scriptCode == 'Hant' ||
                      l.countryCode == 'TW' ||
                      l.countryCode == 'HK' ||
                      l.countryCode == 'MO') {
                    return const Locale('zh', 'TW');
                  }
                  // 簡體或其他中文變體 → 你只支援繁中，這裡也回繁中（或依你需求）
                  return const Locale('zh', 'TW');
                }

                // 非中文：只要語言碼在 supportedLocales 裡，就用它（忽略地區）
                for (final s in supported) {
                  if (s.languageCode == l.languageCode) {
                    return s; // ja_TW → 匹配到 Locale('ja')
                  }
                }
                // 這個偏好語言不支援 → 繼續看下一個偏好
              }

              // 全部偏好都不支援 → fallback
              return const Locale('zh', 'TW');
            },
            onGenerateTitle: (ctx) => AppLocalizations.of(ctx).amitabha,
            theme: themeData,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeShell(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  /* Widget _flavorBanner({required Widget child, bool show = true}) => show
      ? Banner(
          location: BannerLocation.topStart,
          message: F.name,
          color: Colors.green.withAlpha(150),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.0,
            letterSpacing: 1.0,
          ),
          textDirection: TextDirection.ltr,
          child: child,
        )
      : child; */
}

typedef MyApp = App;
