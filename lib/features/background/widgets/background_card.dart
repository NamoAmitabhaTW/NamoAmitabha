// amitabha/lib/features/background/widgets/background_card.dart
import 'package:flutter/material.dart';
import 'package:amitabha/features/background/background_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';

// ── 色彩 tokens ──(略,維持原樣)
const _kBrown = Color(0xFF6F4E37);
const _kDangerColor = Color(0xFFA8623F);
const _kCream = Color(0xFFFFF8EC);
const _kBrownBorder = Color(0x806F4E37);
const _kBrownTrack = Color(0x266F4E37);
const _kDangerBorder = Color(0x80A8623F);
const _kActiveBorder = Color(0x736F4E37);
const _kCardBorder = Color(0x0F000000);
const _kCardShadow = Color(0x0F000000);
const _kChipBg = Color(0x993A2E25);
const _kPreviewBg = Color(0x1F000000);
const _kPreviewIcon = Color(0x61000000);
const _kSubtleText = Color(0x8A000000);

/// 可縮放的按鈕文字：長語系(Verwenden/Löschen)不折行，改為等比縮小。
Widget _btnLabel(String text) => FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(text, maxLines: 1, softWrap: false),
);

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
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
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
          Stack(
            children: [
              SizedBox(height: 180, width: double.infinity, child: _preview()),
              Positioned(top: 12, right: 12, child: _metaChip(t)), // ← 傳 t
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName(lang),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _actions(state, t), // ← 傳 t
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
    if (item.isBuiltin) {
      return Image.asset(
        item.thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
    return CachedNetworkImage(
      imageUrl: item.thumbnail,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }

  // 內建顯示「預設背景」,其餘顯示「類型 · 大小」。
  Widget _metaChip(AppLocalizations t) {
    final String text;
    if (item.isBuiltin) {
      text = t.bgDefault;
    } else {
      final typeLabel =
          item.type == BackgroundType.video ? t.bgTypeVideo : t.bgTypeImage;
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

  Widget _actions(BackgroundUiState state, AppLocalizations t) {
    switch (state) {
      case BackgroundUiState.activeBuiltin:
      case BackgroundUiState.activeDownloaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.needsUpdate) ...[
              _updateBtn(t),
              const SizedBox(height: 12),
            ],
            _activeBanner(t),
          ],
        );

      case BackgroundUiState.idleBuiltin:
        return SizedBox(width: double.infinity, child: _useBtn(t));

      case BackgroundUiState.idleDownloaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.needsUpdate) ...[
              _updateBtn(t),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(child: _useBtn(t)),
                const SizedBox(width: 12),
                Expanded(child: _deleteBtn(t)),
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
                  backgroundColor: _kBrownTrack,
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
        return SizedBox(width: double.infinity, child: _downloadBtn(t));
    }
  }

  Widget _useBtn(AppLocalizations t) => OutlinedButton.icon(
    onPressed: onUse,
    icon: const Icon(Icons.touch_app_outlined, size: 20),
    label: _btnLabel(t.bgUse),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kBrown,
      minimumSize: const Size(0, 50),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kBrownBorder),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  Widget _deleteBtn(AppLocalizations t) => OutlinedButton.icon(
    onPressed: onDelete,
    icon: const Icon(Icons.delete_outline, size: 20),
    label: _btnLabel(t.bgDelete),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kDangerColor,
      minimumSize: const Size(0, 50),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kDangerBorder),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  Widget _downloadBtn(AppLocalizations t) => OutlinedButton.icon(
    onPressed: onDownload,
    icon: const Icon(Icons.download, size: 20),
    label: _btnLabel(t.download),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kBrown,
      minimumSize: const Size(0, 50),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kBrownBorder),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  Widget _updateBtn(AppLocalizations t) => OutlinedButton.icon(
    onPressed: onDownload,
    icon: const Icon(Icons.refresh, size: 20),
    label: _btnLabel(t.bgUpdate),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kBrown,
      minimumSize: const Size(0, 50),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kBrownBorder),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  Widget _activeBanner(AppLocalizations t) => Container(
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _kBrown,
      borderRadius: BorderRadius.circular(25),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row( // ← 拿掉 const(因為內含 t.bgInUse)
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: _kCream, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              t.bgInUse,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                color: _kCream,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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
