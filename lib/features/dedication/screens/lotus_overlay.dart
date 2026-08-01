// amitabha/lib/features/dedication/screens/lotus_overlay.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const String _kFlowerAsset = 'assets/gifs/lotus_flower.webp';

/// 光環半徑相對於畫面短邊的比例（想更貼近/更外圈就調這個）。
const double _kHaloFraction = 0.5;

/// 一個「蓮花高度」約為畫面短邊的多少（河流的縱向範圍以此為基準）。
const double _kLotusHeightFraction = 0.34;

/// 迴向完成後，於念佛頁上疊放蓮花動畫：
/// 下層光暈 PNG、中層旋轉光環、上層蓮花 GIF；三者置中對齊。
/// 淡入 → 停留 → 淡出，約 [hold] 後自動關閉，亦可點畫面提早跳過。
Future<void> showLotusCelebration(
  BuildContext context, {
  Duration hold = const Duration(seconds: 3),
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => _LotusOverlay(hold: hold),
    ),
  );
}

class _LotusOverlay extends StatefulWidget {
  const _LotusOverlay({required this.hold});

  final Duration hold;

  @override
  State<_LotusOverlay> createState() => _LotusOverlayState();
}

class _LotusOverlayState extends State<_LotusOverlay>
    with TickerProviderStateMixin {
  static const _fadeIn = Duration(milliseconds: 500);
  static const _fadeOut = Duration(milliseconds: 600);

  late final AnimationController _fade =
      AnimationController(vsync: this, duration: _fadeIn);
  // 光芒沿光環繞行一圈又一圈。
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();
  // 河流的細砂流動（無縫循環）。
  late final AnimationController _river = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  )..repeat();
  Timer? _holdTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _fade.forward(); // 淡入
    _holdTimer = Timer(_fadeIn + widget.hold, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    _holdTimer?.cancel();
    // 淡出後關閉。
    _fade.duration = _fadeOut;
    try {
      await _fade.reverse();
    } catch (_) {}
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _fade.dispose();
    _sweep.dispose();
    _river.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeInOut),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 下層：淺金細砂河流（蜿蜒由中左往右上、緩緩流動）
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _river,
                  builder: (_, __) => CustomPaint(
                    painter: _SandRiverPainter(flow: _river.value),
                  ),
                ),
              ),
            ),
            // 中層：旋轉光環（環繞蓮花的一道光芒）
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _sweep,
                  builder: (_, __) => CustomPaint(
                    painter: _LotusHaloPainter(progress: _sweep.value),
                  ),
                ),
              ),
            ),
            // 上層：蓮花（會動，透明 WebP）
            const _CenteredMedia(
              child: Image(image: AssetImage(_kFlowerAsset)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 以整張畫布滿版、置中對齊呈現媒體；兩層同尺寸 → 位置與 Canva 一致。
class _CenteredMedia extends StatelessWidget {
  const _CenteredMedia({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FittedBox(
        // 依素材比例完整顯示、置中（不裁切）。若要放大填滿改 BoxFit.cover。
        fit: BoxFit.contain,
        child: child,
      ),
    );
  }
}

/// 環繞蓮花中心、旋轉的一道光芒（旋轉的 SweepGradient 亮弧描邊圓）。
class _LotusHaloPainter extends CustomPainter {
  _LotusHaloPainter({required this.progress});

  final double progress; // 0..1，光芒繞行一圈的進度

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * _kHaloFraction / 2;
    final shader = SweepGradient(
      transform: GradientRotation(progress * 2 * math.pi),
      colors: const [
        Color(0x00FFEEC0),
        Color(0x00FFEEC0),
        Color(0xFFFFF3D2), // 亮弧
        Color(0x00FFEEC0),
      ],
      stops: const [0.0, 0.60, 0.75, 0.92],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    // 柔光 + 銳線兩道。
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_LotusHaloPainter old) => old.progress != progress;
}

/// 一顆細砂顆粒（沿河流路徑流動）。
class _Grain {
  const _Grain({
    required this.t0,
    required this.perp,
    required this.size,
    required this.speed,
    required this.phase,
  });
  final double t0; // 起始位置（沿路徑 0..1）
  final double perp; // 橫向偏移比例（-1..1）
  final double size; // 半徑
  final int speed; // 每循環繞行圈數（整數 → 無縫循環）
  final double phase; // 閃爍相位
}

/// 淺金細砂質地的蜿蜒河流：一條由中左往右上的柔和砂帶 + 流動的金色細砂顆粒。
/// 縱向範圍約以蓮花為中心、上下各一個蓮花高度。無縫循環流動。
class _SandRiverPainter extends CustomPainter {
  _SandRiverPainter({required this.flow});

  final double flow; // 0..1 循環

  static final List<_Grain> _grains = _makeGrains(150);

  static List<_Grain> _makeGrains(int n) {
    final r = math.Random(7);
    return List.generate(
      n,
      (_) => _Grain(
        t0: r.nextDouble(),
        perp: r.nextDouble() * 2 - 1,
        size: 0.8 + r.nextDouble() * 1.7,
        speed: 1 + r.nextInt(2), // 1 或 2，整數確保循環無縫
        phase: r.nextDouble() * math.pi * 2,
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// 河流中心線：由中左（略低）→ 右上（略高），帶蜿蜒；相位隨 flow 緩緩漂移。
  Offset _pointAt(double t, Size size, double lotusH) {
    final x = _lerp(size.width * 0.02, size.width * 0.98, t);
    final cy = size.height * 0.5;
    final baseY = _lerp(cy + lotusH * 0.35, cy - lotusH * 0.8, t);
    final meander = math.sin(t * 2 * math.pi * 1.3 + flow * 2 * math.pi) *
        lotusH *
        0.15;
    return Offset(x, baseY + meander);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lotusH = size.shortestSide * _kLotusHeightFraction;
    final half = lotusH * 0.26; // 河流半寬

    // 1) 柔和砂帶（兩道模糊描邊營造朦朧質感）。
    final path = Path();
    const n = 48;
    for (var i = 0; i <= n; i++) {
      final p = _pointAt(i / n, size, lotusH);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = half * 2
        ..color = const Color(0x1FC9A75E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = half
        ..color = const Color(0x22DCC085)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2) 流動的金色細砂顆粒。
    for (final g in _grains) {
      final t = (g.t0 + flow * g.speed) % 1.0;
      final p = _pointAt(t, size, lotusH);
      // 沿切線的垂直方向做橫向散佈。
      final p2 = _pointAt((t + 0.01).clamp(0.0, 1.0), size, lotusH);
      final d = p2 - p;
      final len = d.distance == 0 ? 1.0 : d.distance;
      final perp = Offset(-d.dy / len, d.dx / len);
      final pos = p + perp * (g.perp * half);
      // 兩端淡出 + 微微閃爍。
      final edge = 1 - (2 * t - 1).abs();
      final twinkle = 0.5 + 0.5 * math.sin(flow * 2 * math.pi * 2 + g.phase);
      final a = (0.55 * edge * twinkle).clamp(0.0, 1.0);
      if (a <= 0.02) continue;
      canvas.drawCircle(
        pos,
        g.size,
        Paint()..color = Color.fromRGBO(230, 200, 130, a),
      );
    }
  }

  @override
  bool shouldRepaint(_SandRiverPainter old) => old.flow != flow;
}
