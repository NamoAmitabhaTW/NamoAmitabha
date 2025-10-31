// widgets/floating_lotus_field.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloatingLotusField extends StatefulWidget {
  const FloatingLotusField({
    super.key,
    required this.isActive,
    this.imageAssets = const ['assets/images/lotus.png'],

    // 節奏與數量
    this.maxParticles = 3,             // 同時最多 3 朵
    this.spawnPerSecond = 1.0 / 5.0,   // 每 3 秒 1 朵

    // 大小
    this.minSize = 28,
    this.maxSize = 45,

    // 速度（相對單位 0~1/秒）— 已調慢
    this.minSpeed = 0.05,              // 每秒上升 5% 螢幕高度
    this.maxSpeed = 0.07,              // 每秒上升 9%  螢幕高度

    // 漂移（相對單位 -1~1/秒）— 已調小
    this.minDrift = -0.015,
    this.maxDrift =  0.015,

    // 生成位置（相對 0 底 1? → 我們用 0=頂端, 1=底端）
    this.spawnY = 0.82,                // 起點在底部偏上（約在「儲存」按鈕上方）
    this.spawnXMin = 0.60,             // 右半邊（靠近儲存鍵）
    this.spawnXMax = 0.95,

    // 消失門檻（到這高度開始淡出並回收）
    this.topExitY = 0.22,              // 接近聖號水印（約畫面上 22%）
    this.minOpacity = 0.45,
    this.maxOpacity = 0.85,

    // 視覺擺動
    this.wobbleAmp = 0.12,             // 擺動幅度 (弧度)
    this.wobbleFreq = 1.0,             // 擺動頻率（越大越快）
  });

  final bool isActive;

  final List<String> imageAssets;

  final int maxParticles;
  final double spawnPerSecond;

  final double minSize;
  final double maxSize;

  final double minSpeed;
  final double maxSpeed;

  final double minDrift;
  final double maxDrift;

  // 生成/終點參數
  final double spawnY;
  final double spawnXMin;
  final double spawnXMax;
  final double topExitY;

  final double minOpacity;
  final double maxOpacity;

  final double wobbleAmp;
  final double wobbleFreq;

  @override
  State<FloatingLotusField> createState() => _FloatingLotusFieldState();
}

class _FloatingLotusFieldState extends State<FloatingLotusField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = math.Random();

  final List<_Lotus> _items = [];
  double _spawnAcc = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this)
      ..addListener(_tick)
      ..repeat(min: 0, max: 1, period: const Duration(milliseconds: 16));
  }

  @override
  void didUpdateWidget(covariant FloatingLotusField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // isActive=false 時不再生新粒子，舊粒子自然結束
  }

  void _tick() {
    const dt = 1 / 60.0;

    // 生成：一次最多只生一朵，避免掉幀暴衝
    if (widget.isActive) {
      _spawnAcc += widget.spawnPerSecond * dt;
      if (_spawnAcc >= 1 && _items.length < widget.maxParticles) {
        _spawnOne();
        _spawnAcc -= 1;
      }
    }

    // 更新
    for (final p in _items) {
      p.age += dt;

      // 相對位移
      p.y -= p.speed * dt;   // 往上（y 變小；0=頂, 1=底）
      p.x += p.drift * dt;   // 左右飄

      // 漸顯/漸隱（接近 topExitY 開始淡出）
      final lifeRatio = (p.age / p.life).clamp(0.0, 1.0);
      if (lifeRatio < 0.15) {
        p.opacity = p.baseOpacity * (lifeRatio / 0.15);
      } else if (p.y <= widget.topExitY) {
        // 進入頂端區域，按比例淡出
        final t = ((widget.topExitY - p.y) / 0.12).clamp(0.0, 1.0);
        p.opacity = p.baseOpacity * (1 - t).clamp(0.4, 0.8);
      } else {
        p.opacity = p.baseOpacity.clamp(0.4, 0.8);
      }
    }

    // 回收：到頂端上方一點、或壽終、或透明
    _items.removeWhere((p) => p.y < widget.topExitY - 0.08 || p.age >= p.life || p.opacity <= 0);

    if (mounted) setState(() {});
  }

  void _spawnOne() {
    final size  = _rng.nextDouble() * (widget.maxSize - widget.minSize) + widget.minSize;
    final speed = _rng.nextDouble() * (widget.maxSpeed - widget.minSpeed) + widget.minSpeed;
    final drift = _rng.nextDouble() * (widget.maxDrift - widget.minDrift) + widget.minDrift;
    final baseOpacity =
        _rng.nextDouble() * (widget.maxOpacity - widget.minOpacity) + widget.minOpacity;

    // 生成在右半邊、儲存鍵上方附近
    final x = widget.spawnXMin + _rng.nextDouble() * (widget.spawnXMax - widget.spawnXMin);
    final y = widget.spawnY;
    
    final asset = widget.imageAssets[_rng.nextInt(widget.imageAssets.length)];

    // 壽命：從 spawnY 飄到 topExitY 再預留 0.1 高度時間緩衝
    final distance = (y - widget.topExitY) + 0.10;
    final life = (distance / speed).clamp(0.5, 20.0); // 安全夾範圍

    _items.add(_Lotus(
      x: x,
      y: y,
      size: size,
      speed: speed,
      drift: drift,
      life: life,
      baseOpacity: baseOpacity,
      asset: asset,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (ctx, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;

          return Stack(
            children: [
              for (final p in _items)
                Positioned(
                  left: p.x * w - p.size / 2,
                  top:  p.y * h - p.size / 2,
                  width: p.size,
                  height: p.size,
                  child: Opacity(
                    opacity: p.opacity,
                    child: Transform.rotate(
                      angle: math.sin((p.age + p.x) * widget.wobbleFreq) * widget.wobbleAmp,
                      child: Image.asset(
                        p.asset,
                        filterQuality: FilterQuality.medium,
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
}

class _Lotus {
  _Lotus({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.life,
    required this.baseOpacity,
    required this.asset,
  });

  double x;            // 0~1（0=左,1=右）
  double y;            // 0~1（0=頂,1=底）
  double size;         // px
  double speed;        // 相對垂直速度（每秒上升多少螢幕高度）
  double drift;        // 相對水平速度（每秒橫移多少螢幕寬度）
  double life;         // 秒
  double age = 0;      // 秒
  double baseOpacity;  // 目標不透明度
  double opacity = 0;  // 目前不透明度
  final String asset;
}