// amitabha/lib/features/background/screens/background_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amitabha/features/background/background_controller.dart';
import 'package:amitabha/features/background/background_item.dart';
import 'package:amitabha/features/background/widgets/background_card.dart';

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
      // 只在「上次沒載到遠端清單」時自動重抓;成功過就不重複打網路。
      // 手動重試 / 下拉刷新仍可隨時觸發 c.load()。
      if (c.manifestLoadFailed) {
        c.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('念佛背景')),
      body: Consumer<BackgroundController>(
        builder: (context, c, _) {
          if (c.isLoading && c.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              if (c.clearedNoticeName != null)
                _ClearedNoticeBanner(
                  name: c.clearedNoticeName!,
                  onDismiss: c.consumeClearedNotice,
                ),
              if (c.manifestLoadFailed) _OfflineNoticeBanner(onRetry: c.load),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除背景'),
        content: Text('確定要刪除「${item.name}」嗎? \n刪除後，仍可重新下載。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(c.lastDownloadError!),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '重試',
            onPressed: () => _handleDownload(context, c, item),
          ),
        ),
      );
    }
  }
}

/// 偵測到使用中背景被系統清掉時,在選擇頁頂端顯示的說明橫幅。
class _ClearedNoticeBanner extends StatelessWidget {
  const _ClearedNoticeBanner({required this.name, required this.onDismiss});

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
                  '背景「$name」已被系統清除',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '當手機儲存空間不足,或你清除了 App 暫存,系統可能會清掉先前下載的背景以釋放空間。已暫時切回預設背景,需要時可重新下載。',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
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
/// 不蓋掉列表——內建背景仍可正常使用。
class _OfflineNoticeBanner extends StatelessWidget {
  const _OfflineNoticeBanner({required this.onRetry});

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '目前處於離線狀態',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  '連接網路，即可下載背景素材。',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('重試'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6F5C44), // 暖褐,與卡片按鈕一致
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
