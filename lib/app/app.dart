// lib/app/app.dart
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/features/asr/application/sherpa_mic_source.dart';
import 'package:amitabha/features/background/background_controller.dart';
import 'package:amitabha/features/home/home_shell.dart';
import 'package:amitabha/features/model_install/install_progress_model.dart';
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
          create: (_) =>
              AsrSessionController(sourceFactory: () => SherpaMicSource()),
        ),
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(
          create: (_) => BackgroundController()..load(),
          lazy: false,
        ),
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
            home: const HomeShell(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

}
