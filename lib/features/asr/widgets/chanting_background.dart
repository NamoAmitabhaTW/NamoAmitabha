// features/asr/widgets/chanting_background.dart
import 'package:amitabha/features/background/background_item.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ChantingBackground extends StatefulWidget {
  const ChantingBackground({
    super.key,
    required this.source,
    this.active = true, 
    this.scrimOpacity = 0, 
  });

  final BackgroundSource? source;
  final bool active;
  final double scrimOpacity;

  @override
  State<ChantingBackground> createState() => _ChantingBackgroundState();
}

class _ChantingBackgroundState extends State<ChantingBackground> {
  VideoPlayerController? _controller;
  bool _ready = false;

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
      await c.setVolume(0); 
      if (widget.active) await c.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void didUpdateWidget(covariant ChantingBackground old) {
    super.didUpdateWidget(old);

    final newKey = _keyOf(widget.source);
    if (newKey != _currentKey) {
      _currentKey = newKey;
      _controller?.dispose();
      _controller = null;
      setState(() => _ready = false);
      if (widget.source?.type == BackgroundType.video) {
        _initVideo(widget.source!);
      }
      return;
    }

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

    if (s == null) {
      return const ColoredBox(color: Color(0xFFFFF8E7));
    }

    if (s.type == BackgroundType.image) {
      final img = s.file != null
          ? Image.file(s.file!, fit: BoxFit.cover)
          : Image.asset(s.assetPath!, fit: BoxFit.cover);
      return SizedBox.expand(child: img);
    }

    final c = _controller;
    if (c == null || !_ready) {
      return const ColoredBox(color: Color(0xFFFFF8E7));
    }

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
