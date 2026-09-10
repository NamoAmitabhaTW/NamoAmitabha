// lib/app/app.dart
import 'package:amitabha/app/di/app_dependencies.dart';
import 'package:amitabha/app/orientation_lock.dart';
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/features/app_update/app_update.dart';
import 'package:amitabha/features/home/home.dart';
import 'package:amitabha/features/model_install/model_install.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InstallProgressModel()),
        ChangeNotifierProvider(
          create: (_) => AppDependencies.createAsrSessionController(),
        ),
        ChangeNotifierProvider(create: (_) => LocaleController()),

        Provider(create: (_) => AppDependencies.createRecordsController()),
        ChangeNotifierProvider(
          create: (_) => AppDependencies.createBackgroundController()..load(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => AppDependencies.createDedicationController()..load(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => AppDependencies.createAnnouncementController()..load(),
          lazy: false,
        ),

        Provider(create: (_) => AppDependencies.createAppUpdateController()),
      ],
      child: Builder(
        builder: (context) {
          final locale = context.watch<LocaleController>().locale;
          final themeData = Brand.getTheme(AppThemeStyle.zenWood);
          return MaterialApp(
            locale: locale,
            localeListResolutionCallback: (locales, supported) {
              final prefs = locales ?? const <Locale>[];

              for (final l in prefs) {
                if (l.languageCode == 'zh') {
                  if (l.scriptCode == 'Hant' ||
                      l.countryCode == 'TW' ||
                      l.countryCode == 'HK' ||
                      l.countryCode == 'MO') {
                    return const Locale('zh', 'TW');
                  }
                  return const Locale('zh', 'TW');
                }

                for (final s in supported) {
                  if (s.languageCode == l.languageCode) {
                    return s;
                  }
                }
              }

              return const Locale('zh', 'TW');
            },
            onGenerateTitle: (ctx) => AppLocalizations.of(ctx).amitabha,
            theme: themeData,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const OrientationLock(
              child: AppUpdateGate(child: HomeShell()),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
