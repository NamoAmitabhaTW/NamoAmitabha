// features/asr/widgets/chanting_background.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 背景類型。未來由設定頁 / AppState 提供。
/// 若你專案別處已定義 BackgroundType，請改 import 那個，別重複宣告。
enum BackgroundType { video, image }

class ChantingBackground extends StatefulWidget {
  const ChantingBackground({
    super.key,
    required this.type,
    this.videoAsset = 'assets/videos/stream.mp4',
    this.imageAsset = 'assets/images/sun.png',
    this.active = true, // 是否在前景；切到別的分頁時設 false 可暫停影片
    this.scrimOpacity = 0.25, // 蓋在背景上的暗色遮罩，幫前景文字維持可讀；0 = 不要
  });

  final BackgroundType type;
  final String videoAsset;
  final String imageAsset;
  final bool active;
  final double scrimOpacity;

  @override
  State<ChantingBackground> createState() => _ChantingBackgroundState();
}

class _ChantingBackgroundState extends State<ChantingBackground> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == BackgroundType.video) _initVideo();
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset(widget.videoAsset);
    _controller = c;
    await c.initialize();
    await c.setLooping(true);
    await c.setVolume(0); // 靜音
    if (widget.active) await c.play();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void didUpdateWidget(covariant ChantingBackground old) {
    super.didUpdateWidget(old);

    // 影片 <-> 圖片 切換（之後設定頁會用到）
    if (widget.type != old.type) {
      if (widget.type == BackgroundType.video) {
        _ready = false;
        _initVideo();
      } else {
        _controller?.dispose();
        _controller = null;
        _ready = false;
      }
    }

    // 前景/背景切換 -> 播放或暫停
    if (widget.active != old.active && _controller != null) {
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
    // 圖片背景
    if (widget.type == BackgroundType.image) {
      return Image.asset(widget.imageAsset, fit: BoxFit.cover);
    }

    // 影片還沒就緒 -> 先用圖片墊著，避免黑屏閃一下
    final c = _controller;
    if (c == null || !_ready) {
      return const ColoredBox(color: Color(0xFFFFF8E7));
    }

    // 影片就緒 -> 滿版裁切（FittedBox + cover 是維持比例不變形的標準寫法）
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
