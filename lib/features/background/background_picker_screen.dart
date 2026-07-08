// amitabha/lib/features/background/screens/background_picker_screen.dart
import 'package:amitabha/features/background/background_controller.dart';
import 'package:amitabha/features/background/background_item.dart';
import 'package:amitabha/features/background/widgets/background_card.dart';
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
      appBar: AppBar(title: Text(t.bgScreenTitle)),
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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: c.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      // 永久性錯誤(素材下架/連結失效)不給重試鈕,重試無意義
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
} // ← 這個大括號就是原本漏掉的:關閉 _BackgroundPickerScreenState

/// 偵測到使用中背景被系統清掉時,在選擇頁頂端顯示的說明橫幅。
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.bgClearedTitle(name),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text( // ← 拿掉 const(內含 t.bgClearedBody)
                  t.bgClearedBody,
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// 抓不到遠端背景清單(多半是無網路)時,在頂端顯示的提示。
class _OfflineNoticeBanner extends StatelessWidget {
  const _OfflineNoticeBanner({required this.t, required this.onRetry});

  final AppLocalizations t;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 20, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded( // ← 拿掉 const(內含 t.bgOfflineTitle/Body)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.bgOfflineTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.bgOfflineBody,
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,        // ← 原本誤寫成 t.retry
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(t.retry),      // ← 原本誤寫成 const Text('重試')
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6F5C44),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}