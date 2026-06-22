// amitabha/lib/features/background/widgets/background_card.dart
import 'package:flutter/material.dart';
import 'package:amitabha/features/background/background_item.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ── 色彩 tokens(全部集中於此,日後建議抽到 theme / AppColors 統一管理) ──
// 按鈕全為外框、不填色,維持清爽通透,與卡片奶油底協調,讓上方繽紛的預覽圖
// 當主角。主要與次要動作同為暖棕,靠標籤與圖示區分;刪除以赤陶外框做出可
// 辨識差異(點擊後另有確認對話框把關);作用中改以「實心暖棕 pill」標示,
// 不再使用綠色,讓整張卡片維持同一色相,只靠「實心 vs 外框」分出層級。
//
// 命名慣例:k = compile-time constant(源自 Google/Flutter 規範,如 kToolbarHeight)。
// 顏色名(brown / cream)本身自明,不加 Color;語意角色名(danger / active)加
// Color 才看得出是顏色。alpha 已烤進 hex 前兩碼,維持純 const、不需 withValues。

// 基色
const _kBrown = Color(0xFF6F4E37); // 主要動作:使用 / 下載 / 更新 + 作用中
const _kDangerColor = Color(0xFFA8623F); // 赤陶:刪除(破壞性,有確認框)
const _kCream = Color(0xFFFFF8EC); // 作用中 pill 上的文字 / 圖示

// 由基色派生(alpha 烤進 hex)
const _kBrownBorder = Color(0x806F4E37); // 暖棕外框 ~50%
const _kBrownTrack = Color(0x266F4E37); // 下載進度條底 ~15%
const _kDangerBorder = Color(0x80A8623F); // 刪除外框 ~50%
const _kActiveBorder = Color(0x736F4E37); // 作用中卡片外框 ~45%

// 中性
const _kCardBorder = Color(0x0F000000); // 一般卡片外框 ~6%
const _kCardShadow = Color(0x0F000000); // 卡片陰影 ~6%
const _kChipBg = Color(0x993A2E25); // 圖片右上角霧面標籤底 ~50%
const _kPreviewBg = Color(0x1F000000); // 預覽載入失敗佔位底(≈ black12)
const _kPreviewIcon = Color(0x61000000); // 佔位 icon(≈ black38)
const _kSubtleText = Color(0x8A000000); // 次要文字,如百分比(≈ black54)

class BackgroundCard extends StatelessWidget {
  const BackgroundCard({
    super.key,
    required this.item,
    required this.isActive,
    required this.onDownload,
    required this.onCancel,
    required this.onUse,
    required this.onDelete,
  });

  final BackgroundItem item;
  final bool isActive;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final state = item.uiState(isActive);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: isActive
            ? Border.all(color: _kActiveBorder, width: 1.5)
            : Border.all(color: _kCardBorder),
        boxShadow: const [
          BoxShadow(color: _kCardShadow, blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 頂部大預覽圖 + 右上角霧面標籤 ──
          Stack(
            children: [
              SizedBox(height: 180, width: double.infinity, child: _preview()),
              Positioned(top: 12, right: 12, child: _metaChip()),
            ],
          ),
          // ── 下方資訊區 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w200,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _actions(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final placeholder = Container(
      color: _kPreviewBg,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 32, color: _kPreviewIcon),
    );
    // 內建:打包在 App 內的 asset,本來就離線
    if (item.isBuiltin) {
      return Image.asset(
        item.thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
    // 遠端:磁碟快取,離線也能顯示曾載過的縮圖
    return CachedNetworkImage(
      imageUrl: item.thumbnail,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }

  // 疊在圖片右上角的霧面標籤:內建顯示「預設背景」,其餘顯示「類型 · 大小」。
  Widget _metaChip() {
    final String text;
    if (item.isBuiltin) {
      text = '預設背景';
    } else {
      final typeLabel = item.type == BackgroundType.video ? '影片' : '圖片';
      final size = _fmtSize(item.fileSize);
      text = size.isEmpty ? typeLabel : '$typeLabel · $size';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          shadows: [Shadow(color: Color(0xB3000000), blurRadius: 4)],
        ),
      ),
    );
  }

  // ── 動作區 ────────────────────────────────────────────────

  Widget _actions(BackgroundUiState state) {
    switch (state) {
      case BackgroundUiState.activeBuiltin:
      case BackgroundUiState.activeDownloaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.needsUpdate) ...[_updateBtn(), const SizedBox(height: 12)],
            _activeBanner(),
          ],
        );

      case BackgroundUiState.idleBuiltin:
        // 內建不可刪:使用鍵滿版(大小、位置與「使用中」一致)
        return SizedBox(width: double.infinity, child: _useBtn());

      case BackgroundUiState.idleDownloaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.needsUpdate) ...[_updateBtn(), const SizedBox(height: 12)],
            // 使用(主要,暖棕)| 刪除(次要,赤陶),等分滿版
            Row(
              children: [
                Expanded(child: _useBtn()),
                const SizedBox(width: 12),
                Expanded(child: _deleteBtn()),
              ],
            ),
          ],
        );

      case BackgroundUiState.downloading:
        return Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.downloadProgress,
                  minHeight: 8,
                  color: _kBrown,
                  backgroundColor: _kBrownTrack, // 原 _kBrown.withOpacity(0.15)
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(item.downloadProgress * 100).round()}%',
              style: const TextStyle(fontSize: 13, color: _kSubtleText),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 22),
              onPressed: onCancel,
            ),
          ],
        );

      case BackgroundUiState.notDownloaded:
        // 下載鍵滿版(大小、位置與「使用中」一致)
        return SizedBox(width: double.infinity, child: _downloadBtn());
    }
  }

  // 使用(主要動作:暖棕外框藥丸)
  Widget _useBtn() => OutlinedButton.icon(
    onPressed: onUse,
    icon: const Icon(Icons.touch_app_outlined, size: 20),
    label: const Text('使用'),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kBrown,
      minimumSize: const Size(0, 50),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kBrownBorder),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  // 刪除(次要、破壞性:赤陶外框藥丸。點擊後另有確認對話框把關)
  Widget _deleteBtn() => OutlinedButton.icon(
    onPressed: onDelete,
    icon: const Icon(Icons.delete_outline, size: 20),
    label: const Text('刪除'),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kDangerColor,
      minimumSize: const Size(0, 50),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kDangerBorder),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  // 下載(主要動作:暖棕外框藥丸,滿版)
  Widget _downloadBtn() => OutlinedButton.icon(
    onPressed: onDownload,
    icon: const Icon(Icons.download, size: 20),
    label: const Text('下載'),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kBrown,
      minimumSize: const Size(0, 50),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kBrownBorder),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  // 更新(有新版時出現:暖棕外框藥丸,滿版。次要操作)
  Widget _updateBtn() => OutlinedButton.icon(
    onPressed: onDownload,
    icon: const Icon(Icons.refresh, size: 20),
    label: const Text('更新'),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kBrown,
      minimumSize: const Size(0, 50),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kBrownBorder),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  // 使用中(滿版實心暖棕 pill,與外框按鈕同色相、靠「實心」拉出層級)
  Widget _activeBanner() => Container(
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _kBrown,
      borderRadius: BorderRadius.circular(25),
    ),
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: _kCream, size: 20),
        SizedBox(width: 8),
        Text(
          '使用中',
          style: TextStyle(
            color: _kCream,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  String _fmtSize(int bytes) {
    if (bytes <= 0) return '';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
