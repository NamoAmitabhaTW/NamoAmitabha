import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/features/announcements/announcement_controller.dart';
import 'package:amitabha/features/announcements/announcement_item.dart';
import 'package:amitabha/features/announcements/screens/announcement_detail_screen.dart';
import 'package:amitabha/features/announcements/widgets/simple_markdown.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = context.read<AnnouncementController>();
      if (c.manifestLoadFailed) c.load();
      c.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t.announcementsTitle)),
      body: Consumer<AnnouncementController>(
        builder: (context, c, _) {
          if (c.isLoading && c.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  t.announcementsEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Brand.settingsBrownSoft),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: c.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              itemCount: c.items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 32,
                thickness: 1,
                color: Brand.settingsDivider,
              ),
              itemBuilder: (context, i) {
                final item = c.items[i];
                return item.pinned
                    ? _PinnedCard(item: item, lang: lang)
                    : _AnnouncementRow(item: item, lang: lang);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.item, required this.lang});

  final AnnouncementItem item;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final c = context.read<AnnouncementController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Text(
          item.displayTitle(lang),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            color: Brand.settingsGold,
            fontFamilyFallback: SimpleMarkdown.cjkFallback,
          ),
        ),
        if (item.date.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.date,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              letterSpacing: 3,
              color: Brand.settingsBrownSoft,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 28,
            height: 1,
            color: const Color(0x598A6320),
          ),
        ),
        const SizedBox(height: 22),
        FutureBuilder<String?>(
          future: c.ensureBody(item, lang),
          builder: (context, snap) {
            final bodyLang = item.resolveBodyLang(lang) ?? 'zh';
            final body = snap.data ?? c.cachedBody(item.id, bodyLang);
            if (body == null) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Text(
                AppLocalizations.of(context).announcementsEmpty,
                style: const TextStyle(color: Brand.settingsBrownSoft),
              );
            }
            return SimpleMarkdown(
              data: body,
              accentColor: Brand.settingsGold,
              justify: bodyLang == 'zh' || bodyLang == 'ja',
              onLinkTap: (url) => _copyLink(context, url),
            );
          },
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({required this.item, required this.lang});

  final AnnouncementItem item;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(item: item),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayTitle(lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Brand.settingsTitle,
                      fontFamilyFallback: SimpleMarkdown.cjkFallback,
                    ),
                  ),
                  if (item.date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 12.5,
                        letterSpacing: 1,
                        color: Brand.settingsBrownSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Brand.settingsBrownSoft,
              size: 22,
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
