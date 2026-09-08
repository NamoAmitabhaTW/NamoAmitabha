// amitabha/lib/features/background/widgets/background_card.dart
import 'package:amitabha/features/background/background_item.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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

Widget _btnLabel(String text) => Text(
  text,
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
);

const _kBtnGap = 12.0;

const _kBtnChrome = 20.0 + 8.0 + 16.0 * 2 + 12.0;

const _kBtnTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

bool _labelsFitSideBySide(
  BuildContext context,
  double maxWidth,
  List<String> labels,
) {
  final scaler = MediaQuery.textScalerOf(context);
  final perLabel = (maxWidth - _kBtnGap) / 2 - _kBtnChrome;
  if (perLabel <= 0) return false;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _kBtnTextStyle),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    if (painter.width > perLabel) return false;
  }
  return true;
}

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
              AspectRatio(aspectRatio: 16 / 9, child: _preview()),
              Positioned(top: 12, right: 12, child: _metaChip(t)),
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
                _actions(context, state, t),
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

  Widget _metaChip(AppLocalizations t) {
    final String text;
    if (item.isBuiltin) {
      text = t.bgDefault;
    } else {
      final typeLabel = item.type == BackgroundType.video
          ? t.bgTypeVideo
          : t.bgTypeImage;
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

  Widget _actions(
    BuildContext context,
    BackgroundUiState state,
    AppLocalizations t,
  ) {
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
            _useDeleteActions(context, t),
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

  Widget _useDeleteActions(BuildContext context, AppLocalizations t) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = _labelsFitSideBySide(
            context,
            constraints.maxWidth,
            [t.bgUse, t.bgDelete],
          );
          if (sideBySide) {
            return Row(
              children: [
                Expanded(child: _useBtn(t)),
                const SizedBox(width: _kBtnGap),
                Expanded(child: _deleteBtn(t)),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _useBtn(t),
              const SizedBox(height: _kBtnGap),
              _deleteBtn(t),
            ],
          );
        },
      );

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
    constraints: const BoxConstraints(minHeight: 50),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _kBrown,
      borderRadius: BorderRadius.circular(25),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: _kCream, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            t.bgInUse,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kCream,
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
