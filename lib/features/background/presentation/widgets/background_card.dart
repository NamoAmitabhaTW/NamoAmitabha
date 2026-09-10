// lib/features/background/presentation/widgets/background_card.dart
import 'package:amitabha/core/layout/layout_scale.dart';
import 'package:amitabha/features/background/domain/background_item.dart';
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

double _btnChrome(double scale) => (20.0 + 8.0 + 16.0 * 2 + 12.0) * scale;

TextStyle _btnTextStyle(double scale) =>
    TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w600);

bool _labelsFitSideBySide(
  BuildContext context,
  double maxWidth,
  List<String> labels,
  double scale,
) {
  final scaler = MediaQuery.textScalerOf(context);
  final perLabel = (maxWidth - _kBtnGap * scale) / 2 - _btnChrome(scale);
  if (perLabel <= 0) return false;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _btnTextStyle(scale)),
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
    final s = layoutScale(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18 * s),
        border: isActive
            ? Border.all(color: _kActiveBorder, width: 1.5)
            : Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 14 * s,
            offset: Offset(0, 5 * s),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: _preview(s)),
              Positioned(top: 12 * s, right: 12 * s, child: _metaChip(t, s)),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18 * s, 16 * s, 18 * s, 18 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName(lang),
                  style: TextStyle(
                    fontSize: 20 * s,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16 * s),
                _actions(context, state, t, s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(double s) {
    final placeholder = Container(
      color: _kPreviewBg,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 32 * s, color: _kPreviewIcon),
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

  Widget _metaChip(AppLocalizations t, double s) {
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
      padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(20 * s),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5 * s,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          shadows: [Shadow(color: const Color(0xB3000000), blurRadius: 4 * s)],
        ),
      ),
    );
  }

  Widget _actions(
    BuildContext context,
    BackgroundUiState state,
    AppLocalizations t,
    double s,
  ) {
    switch (state) {
      case BackgroundUiState.activeBuiltin:
      case BackgroundUiState.activeDownloaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.needsUpdate) ...[
              _updateBtn(t, s),
              SizedBox(height: 12 * s),
            ],
            _activeBanner(t, s),
          ],
        );

      case BackgroundUiState.idleBuiltin:
        return SizedBox(width: double.infinity, child: _useBtn(t, s));

      case BackgroundUiState.idleDownloaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.needsUpdate) ...[
              _updateBtn(t, s),
              SizedBox(height: 12 * s),
            ],
            _useDeleteActions(context, t, s),
          ],
        );

      case BackgroundUiState.downloading:
        return Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4 * s),
                child: LinearProgressIndicator(
                  value: item.downloadProgress,
                  minHeight: 8 * s,
                  color: _kBrown,
                  backgroundColor: _kBrownTrack,
                ),
              ),
            ),
            SizedBox(width: 12 * s),
            Text(
              '${(item.downloadProgress * 100).round()}%',
              style: TextStyle(fontSize: 13 * s, color: _kSubtleText),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 22 * s),
              onPressed: onCancel,
            ),
          ],
        );

      case BackgroundUiState.notDownloaded:
        return SizedBox(width: double.infinity, child: _downloadBtn(t, s));
    }
  }

  Widget _useDeleteActions(
    BuildContext context,
    AppLocalizations t,
    double s,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final sideBySide = _labelsFitSideBySide(context, constraints.maxWidth, [
        t.bgUse,
        t.bgDelete,
      ], s);
      if (sideBySide) {
        return Row(
          children: [
            Expanded(child: _useBtn(t, s)),
            SizedBox(width: _kBtnGap * s),
            Expanded(child: _deleteBtn(t, s)),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _useBtn(t, s),
          SizedBox(height: _kBtnGap * s),
          _deleteBtn(t, s),
        ],
      );
    },
  );

  Widget _useBtn(AppLocalizations t, double s) => OutlinedButton.icon(
    onPressed: onUse,
    icon: Icon(Icons.touch_app_outlined, size: 20 * s),
    label: _btnLabel(t.bgUse),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kBrown,
      minimumSize: Size(0, 50 * s),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kBrownBorder),
      textStyle: _btnTextStyle(s),
    ),
  );

  Widget _deleteBtn(AppLocalizations t, double s) => OutlinedButton.icon(
    onPressed: onDelete,
    icon: Icon(Icons.delete_outline, size: 20 * s),
    label: _btnLabel(t.bgDelete),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kDangerColor,
      minimumSize: Size(0, 50 * s),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kDangerBorder),
      textStyle: _btnTextStyle(s),
    ),
  );

  Widget _downloadBtn(AppLocalizations t, double s) => OutlinedButton.icon(
    onPressed: onDownload,
    icon: Icon(Icons.download, size: 20 * s),
    label: _btnLabel(t.download),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kBrown,
      minimumSize: Size(0, 50 * s),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kBrownBorder),
      textStyle: _btnTextStyle(s),
    ),
  );

  Widget _updateBtn(AppLocalizations t, double s) => OutlinedButton.icon(
    onPressed: onDownload,
    icon: Icon(Icons.refresh, size: 20 * s),
    label: _btnLabel(t.bgUpdate),
    style: OutlinedButton.styleFrom(
      foregroundColor: _kBrown,
      minimumSize: Size(0, 50 * s),
      shape: const StadiumBorder(),
      side: const BorderSide(color: _kBrownBorder),
      textStyle: _btnTextStyle(s),
    ),
  );

  Widget _activeBanner(AppLocalizations t, double s) => Container(
    constraints: BoxConstraints(minHeight: 50 * s),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _kBrown,
      borderRadius: BorderRadius.circular(25 * s),
    ),
    padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: _kCream, size: 20 * s),
        SizedBox(width: 8 * s),
        Flexible(
          child: Text(
            t.bgInUse,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _kCream,
              fontSize: 16 * s,
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
