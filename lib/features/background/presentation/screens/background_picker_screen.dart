// lib/features/background/presentation/screens/background_picker_screen.dart
import 'package:amitabha/core/layout/layout_scale.dart';
import 'package:amitabha/core/widgets/content_width.dart';
import 'package:amitabha/core/widgets/fitted_title.dart';
import 'package:amitabha/features/background/application/background_controller.dart';
import 'package:amitabha/features/background/domain/background_item.dart';
import 'package:amitabha/features/background/presentation/widgets/background_card.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BackgroundPickerScreen extends StatefulWidget {
  const BackgroundPickerScreen({super.key});

  @override
  State<BackgroundPickerScreen> createState() => _BackgroundPickerScreenState();
}

class _BackgroundPickerScreenState extends State<BackgroundPickerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = context.read<BackgroundController>();
      if (c.manifestLoadFailed) {
        c.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: FittedTitle(t.bgScreenTitle)),
      body: Consumer<BackgroundController>(
        builder: (context, c, _) {
          if (c.isLoading && c.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              if (c.clearedNoticeItem != null)
                _ClearedNoticeBanner(
                  t: t,
                  name: c.clearedNoticeItem!.displayName(lang),
                  onDismiss: c.consumeClearedNotice,
                ),
              if (c.manifestLoadFailed)
                _OfflineNoticeBanner(t: t, onRetry: c.load),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: c.load,

                  child: ContentWidth(
                    maxWidth: 600 * layoutScale(context),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16 * layoutScale(context),
                        16 * layoutScale(context),
                        16 * layoutScale(context),
                        16 * layoutScale(context) +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: c.items.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: 12 * layoutScale(context)),
                      itemBuilder: (context, i) {
                        final item = c.items[i];
                        return BackgroundCard(
                          item: item,
                          isActive: item.id == c.activeId,
                          onDownload: () => _handleDownload(context, c, item),
                          onCancel: () => c.cancelDownload(item),
                          onUse: () => c.use(item),
                          onDelete: () => _confirmDelete(context, c, item),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BackgroundController c,
    BackgroundItem item,
  ) async {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.bgDeleteTitle),
        content: Text(t.bgDeleteConfirm(item.displayName(lang))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.bgDelete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await c.delete(item);
  }

  Future<void> _handleDownload(
    BuildContext context,
    BackgroundController c,
    BackgroundItem item,
  ) async {
    final ok = await c.download(item);
    if (!ok && c.lastDownloadError != null && context.mounted) {
      final t = AppLocalizations.of(context);
      final error = c.lastDownloadError!;
      final msg = switch (error) {
        BackgroundDownloadError.network => t.bgDownloadErrorNetwork,
        BackgroundDownloadError.notAvailable => t.bgDownloadErrorNotAvailable,
        BackgroundDownloadError.unknown => t.bgDownloadErrorGeneric,
      };

      final retryable = error != BackgroundDownloadError.notAvailable;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          action: retryable
              ? SnackBarAction(
                  label: t.retry,
                  onPressed: () => _handleDownload(context, c, item),
                )
              : null,
        ),
      );
    }
  }
}

class _ClearedNoticeBanner extends StatelessWidget {
  const _ClearedNoticeBanner({
    required this.t,
    required this.name,
    required this.onDismiss,
  });

  final AppLocalizations t;
  final String name;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final s = layoutScale(context);
    return Container(
      margin: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 0),
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20 * s, color: Colors.amber),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.bgClearedTitle(name),
                  style: TextStyle(
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  t.bgClearedBody,
                  style: TextStyle(fontSize: 12.5 * s, height: 1.4),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18 * s),
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _OfflineNoticeBanner extends StatelessWidget {
  const _OfflineNoticeBanner({required this.t, required this.onRetry});

  final AppLocalizations t;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final s = layoutScale(context);
    return Container(
      margin: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 0),
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, size: 20 * s, color: Colors.amber),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.bgOfflineTitle,
                  style: TextStyle(
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  t.bgOfflineBody,
                  style: TextStyle(fontSize: 12.5 * s, height: 1.4),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, size: 20 * s),
            label: Text(t.retry),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6F5C44),
              textStyle: TextStyle(
                fontSize: 16 * s,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
