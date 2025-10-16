//app.dart
import 'package:amitabha/core/core/theme/brand.dart';
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
      ],
      child: Builder(
        builder: (context) {
          // 由 LocaleController 取得目前選擇；null 代表「跟隨系統」
          final locale = context.watch<LocaleController>().locale;

          return MaterialApp(
            locale: locale, // null => 跟隨系統
            // 把所有「繁體」系統語系統一映射到 zh_TW
            localeListResolutionCallback: (locales, supported) {
              for (final l in locales ?? const <Locale>[]) {
                if (l.languageCode == 'zh') {
                  if (l.scriptCode == 'Hant' ||
                      l.countryCode == 'TW' ||
                      l.countryCode == 'HK' ||
                      l.countryCode == 'MO') {
                    return const Locale('zh', 'TW');
                  }
                }
              }
              // 交回 Flutter 預設處理
              return null;
            },
            onGenerateTitle: (ctx) => AppLocalizations.of(ctx).amitabha,
            theme: Brand.light(),
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