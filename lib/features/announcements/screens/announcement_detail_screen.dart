// amitabha/lib/features/announcements/screens/announcement_detail_screen.dart
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/core/widgets/content_width.dart';
import 'package:amitabha/core/widgets/fitted_title.dart';
import 'package:amitabha/features/announcements/announcement_controller.dart';
import 'package:amitabha/features/announcements/announcement_item.dart';
import 'package:amitabha/features/announcements/widgets/simple_markdown.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  const AnnouncementDetailScreen({super.key, required this.item});

  final AnnouncementItem item;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final c = context.read<AnnouncementController>();

    return Scaffold(
      appBar: AppBar(
        title: FittedTitle(
          item.displayTitle(lang),
          style: const TextStyle(
            fontFamilyFallback: SimpleMarkdown.cjkFallback,
          ),
        ),
      ),
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            32 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            if (item.date.isNotEmpty) ...[
              Text(
                item.date,
                style: const TextStyle(
                  fontSize: 13,
                  color: Brand.settingsBrownSoft,
                ),
              ),
              const SizedBox(height: 16),
            ],
            FutureBuilder<String?>(
              future: c.ensureBody(item, lang),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    c.cachedBody(item.id, item.resolveBodyLang(lang) ?? 'zh') ==
                        null) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final body =
                    snap.data ??
                    c.cachedBody(item.id, item.resolveBodyLang(lang) ?? 'zh');
                if (body == null || body.trim().isEmpty) {
                  return Text(
                    AppLocalizations.of(context).announcementsEmpty,
                    style: const TextStyle(color: Brand.settingsBrownSoft),
                  );
                }
                final bodyLang = item.resolveBodyLang(lang) ?? 'zh';
                return SimpleMarkdown(
                  data: body,
                  accentColor: Brand.settingsGold,
                  justify: bodyLang == 'zh' || bodyLang == 'ja',
                  baseFontSize: item.id == 'licenses' ? 14 : 18,
                  onLinkTap: (url) => _copyLink(context, url),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _copyLink(BuildContext context, String url) {
  Clipboard.setData(ClipboardData(text: url));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context).announcementsLinkCopied),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
