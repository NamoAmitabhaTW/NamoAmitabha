//amitabha/lib/features/settings/screens/settings_screen.dart
import 'package:amitabha/core/core/theme/brand.dart';
import 'package:amitabha/core/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vp = MediaQuery.of(context).viewPadding;
    return ListView(
      padding: EdgeInsets.only(
        top: vp.top + 8, // 原本的 const SizedBox(height: 8) 也可保留
        bottom: vp.bottom + 12, // 讓最尾列不被手勢列擠住
      ),
      children: [
        const SizedBox(height: 8),

        //_AccountTile(),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(t.language),
          subtitle: Text(_languageLabel(context)),
          onTap: () => _chooseLanguage(context),
        ),
        ListTile(
          leading: const Icon(Icons.feedback_outlined),
          title: Text(t.feedback),
          onTap: () => sendFeedbackEmail(context),
        ),

        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('風格'), // 之後加入 i18n
          subtitle: Text(_themeLabel(context)),
          onTap: () => _chooseTheme(context),
        ),
      ],
    );
  }

  String _languageLabel(BuildContext context) {
    final ctrl = context.watch<LocaleController>();
    final eff = ctrl.locale; // null = 跟隨系統
    if (eff == null) {
      final sys = Localizations.maybeLocaleOf(context);
      final isZh =
          sys?.languageCode == 'zh' &&
          (sys?.countryCode == 'TW' || sys?.scriptCode == 'Hant');
      return isZh ? '跟隨系統（繁體中文）' : '跟隨系統（English）';
    }
    return eff.languageCode == 'zh' ? '繁體中文' : 'English';
  }

  void _chooseLanguage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: const Text('跟隨系統'),
              onTap: () {
                context.read<LocaleController>().useSystem();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('繁體中文'),
              onTap: () {
                context.read<LocaleController>().useTraditionalChinese();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('English'),
              onTap: () {
                context.read<LocaleController>().useEnglish();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(BuildContext context) {
    final style = context.watch<ThemeController>().style;
    return style == AppThemeStyle.zenWood ? '禪堂木紋' : '蓮花七寶池';
  }

  void _chooseTheme(BuildContext context) {
    final controller = context.read<ThemeController>();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.architecture),
              title: const Text('禪堂木紋'),
              onTap: () {
                controller.setStyle(AppThemeStyle.zenWood);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_vintage),
              title: const Text('蓮花七寶池'),
              onTap: () {
                controller.setStyle(AppThemeStyle.lotusPond);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendFeedbackEmail(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final messeger = ScaffoldMessenger.of(context);

    // 多語主旨與內文（以 i18n 字串組合）
    // 這裡把 App 名字當參數帶進去（若有 appName 的 i18n 也可以帶 t.appName）
    final subject = t.feedbackEmailSubject(t.appName);
    final body = t.feedbackEmailBody;

    // 收件者可抽成設定或常數
    const to = 'namoamitabha1995@gmail.com';

    final uri = Uri.parse(
      'mailto:$to'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    // 用 Uri 物件比較不會有編碼問題
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // 無法開啟郵件 App 的 fallback（可改成顯示對話框）
      messeger.showSnackBar(
        SnackBar(content: Text(t.feedbackOpenMailAppFailed)),
      );
    }
  }
}
