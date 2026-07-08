// features/asr/widgets/chanting_background.dart
import 'package:amitabha/features/background/background_item.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 念佛頁背景。來源由 BackgroundController.currentSource 提供,
/// 可能是內建 asset 或下載到本地的 File,影片/圖片皆支援。
class ChantingBackground extends StatefulWidget {
  const ChantingBackground({
    super.key,
    required this.source,
    this.active = true, // 是否在前景;切到別的分頁時設 false 可暫停影片
    this.scrimOpacity = 0, // 暗色遮罩,幫前景文字維持可讀;0 = 不要
  });

  /// 目前背景來源;null 代表載入中或無來源(顯示墊底色)。
  final BackgroundSource? source;
  final bool active;
  final double scrimOpacity;

  @override
  State<ChantingBackground> createState() => _ChantingBackgroundState();
}

class _ChantingBackgroundState extends State<ChantingBackground> {
  VideoPlayerController? _controller;
  bool _ready = false;

  // 來源識別碼:只有它變了才重建影片,避免單純 rebuild 誤觸發。
  String? _currentKey;

  String? _keyOf(BackgroundSource? s) {
    if (s == null) return null;
    return '${s.type}:${s.file?.path ?? s.assetPath ?? ''}:${s.revision}';
  }

  @override
  void initState() {
    super.initState();
    _currentKey = _keyOf(widget.source);
    if (widget.source?.type == BackgroundType.video) {
      _initVideo(widget.source!);
    }
  }

  Future<void> _initVideo(BackgroundSource s) async {
    // 內建走 asset,已下載走 file
    final c = s.file != null
        ? VideoPlayerController.file(
            s.file!,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
        : VideoPlayerController.asset(
            s.assetPath!,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
    _controller = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0); // 靜音
      if (widget.active) await c.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // 初始化失敗(檔案壞/不存在)→ 維持墊底色,不讓畫面崩
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void didUpdateWidget(covariant ChantingBackground old) {
    super.didUpdateWidget(old);

    final newKey = _keyOf(widget.source);
    if (newKey != _currentKey) {
      // 來源真的換了(換影片、影片↔圖片、套用新下載的背景)→ 重建
      _currentKey = newKey;
      _controller?.dispose();
      _controller = null;
      setState(() => _ready = false);
      if (widget.source?.type == BackgroundType.video) {
        _initVideo(widget.source!);
      }
      return;
    }

    // 來源沒變,只是前景/背景切換 → 播放或暫停
    if (widget.active != old.active && _controller != null && _ready) {
      widget.active ? _controller!.play() : _controller!.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildMedia(),
        if (widget.scrimOpacity > 0)
          ColoredBox(
            color: Colors.black.withValues(alpha: widget.scrimOpacity),
          ),
      ],
    );
  }

  Widget _buildMedia() {
    final s = widget.source;

    // 無來源(載入中/被刪且無 fallback)→ 墊底色,避免黑屏
    if (s == null) {
      return const ColoredBox(color: Color(0xFFFFF8E7));
    }

    // 圖片背景:內建 asset 或已下載 file
    if (s.type == BackgroundType.image) {
      final img = s.file != null
          ? Image.file(s.file!, fit: BoxFit.cover)
          : Image.asset(s.assetPath!, fit: BoxFit.cover);
      return SizedBox.expand(child: img);
    }

    // 影片未就緒 → 先墊底色,避免黑屏閃一下
    final c = _controller;
    if (c == null || !_ready) {
      return const ColoredBox(color: Color(0xFFFFF8E7));
    }

    // 影片就緒 → 滿版裁切(FittedBox + cover 維持比例不變形)
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}
