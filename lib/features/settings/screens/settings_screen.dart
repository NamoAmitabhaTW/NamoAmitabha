//amitabha/lib/features/settings/screens/settings_screen.dart
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/features/announcements/announcement_controller.dart';
import 'package:amitabha/features/announcements/screens/announcements_screen.dart';
import 'package:amitabha/features/background/background_picker_screen.dart';
import 'package:amitabha/features/dedication/screens/dedication_editor_screen.dart';
import 'package:amitabha/features/settings/store_actions.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vp = MediaQuery.of(context).viewPadding;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, vp.top + 16, 16, vp.bottom + 16),
      children: [
        _SettingsGroup(
          children: [
            _SettingTile(
              icon: Icons.language,
              title: t.language,
              value: _languageLabel(context),
              onTap: () => _chooseLanguage(context),
            ),
            _SettingTile(
              icon: Icons.image_outlined,
              title: t.bgScreenTitle,
              value: t.bgSettingSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BackgroundPickerScreen(),
                ),
              ),
            ),
            _SettingTile(
              icon: Icons.menu_book_outlined,
              title: t.dedicationTitle,
              value: t.dedicationEdit,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DedicationEditorScreen(),
                ),
              ),
            ),
            _SettingTile(
              icon: Icons.campaign_outlined,
              title: t.announcementsTitle,
              value: t.announcementsSubtitle,
              showBadge: context.select<AnnouncementController, bool>(
                (c) => c.hasUnread,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnnouncementsScreen(),
                ),
              ),
            ),
            if (isRateSupported)
              _SettingTile(
                icon: Icons.rate_review_outlined,
                title: t.rateTitle,
                value: t.rateSubtitle,
                onTap: () => StoreActions.rate(context),
              ),
            Builder(
              builder: (tileContext) => _SettingTile(
                icon: Icons.ios_share,
                title: t.shareTitle,
                value: t.shareSubtitle,
                onTap: () => StoreActions.share(tileContext),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _languageLabel(BuildContext context) {
    final t = AppLocalizations.of(context);
    final eff = context.watch<LocaleController>().locale;  

    if (eff == null) {
      final sys = Localizations.maybeLocaleOf(context);
      return t.langFollowSystemWith(_endonymForLocale(sys));
    }
    return _endonymForLocale(eff);
  }

  String _endonymForLocale(Locale? locale) {
    if (locale == null) return 'English';
    for (final lang in LocaleController.supportedLanguages) {
      if (lang.locale.languageCode == locale.languageCode &&
          lang.locale.countryCode == locale.countryCode) {
        return lang.endonym;
      }
    }
    for (final lang in LocaleController.supportedLanguages) {
      if (lang.locale.languageCode == locale.languageCode) {
        return lang.endonym;
      }
    }
    return locale.languageCode; 
  }

  void _chooseLanguage(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ctrl = context.read<LocaleController>();
    final current = ctrl.locale; 

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [

            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: Text(t.langFollowSystem),
              trailing: current == null
                  ? const Icon(Icons.check, color: Brand.settingsBrown)
                  : null,
              onTap: () {
                ctrl.useSystem();
                Navigator.pop(sheetContext);
              },
            ),
            const Divider(height: 1),
      
            for (final lang in LocaleController.supportedLanguages)
              ListTile(
                leading: const Icon(Icons.translate),
                title: Text(lang.endonym),
                trailing: _isCurrent(current, lang)
                    ? const Icon(Icons.check, color: Brand.settingsBrown)
                    : null,
                onTap: () {
                  ctrl.setLanguage(lang.code);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _isCurrent(Locale? current, AppLanguage lang) {
    if (current == null) return false;
    return current.languageCode == lang.locale.languageCode &&
        current.countryCode == lang.locale.countryCode;
  }
}


class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      tiles.add(children[i]);
      if (i != children.length - 1) {
        tiles.add(
          const Divider(
            height: 1,
            thickness: 1,
            indent: 72, 
            color: Brand.settingsDivider,
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Brand.settingsCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Brand.settingsShadow, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: tiles),
      ),
    );
  }
}


class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.showBadge = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Brand.settingsIconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Brand.settingsBrown, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Brand.settingsTitle,
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        value!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Brand.settingsBrownSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showBadge) ...[
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right, color: Brand.settingsBrownSoft, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}