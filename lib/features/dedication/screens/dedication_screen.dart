// amitabha/lib/features/dedication/screens/dedication_screen.dart
import 'dart:math' as math;

import 'package:amitabha/features/dedication/dedication_controller.dart';
import 'package:amitabha/features/dedication/dedication_style.dart';
import 'package:amitabha/features/dedication/widgets/dedication_karaoke.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DedicationScreen extends StatefulWidget {
  const DedicationScreen({super.key});

  @override
  State<DedicationScreen> createState() => _DedicationScreenState();
}

class _DedicationScreenState extends State<DedicationScreen>
    with SingleTickerProviderStateMixin {
  late final String _lang = Localizations.localeOf(context).languageCode;
  late final String _text = context.read<DedicationController>().textFor(_lang);
  bool _completed = false;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final CurvedAnimation _enterFade = CurvedAnimation(
    parent: _enter,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _enterSlide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(_enterFade);

  final ScrollController _scroll = ScrollController();

  static const double _activeAnchor = 0.66;

  void _followProgress(double t) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final max = pos.maxScrollExtent;
    if (max <= 0) return;
    final vh = pos.viewportDimension;
    final contentH = max + vh;
    final target = (t * contentH - _activeAnchor * vh).clamp(0.0, max);
    _scroll.jumpTo(target);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _enterFade.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final fade = _enterFade;
    final slide = _enterSlide;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _PaperBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                children: [
                  const SizedBox(height: 44),
                  FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: Column(
                        children: [
                          Text(
                            t.dedicationTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: DedicationStyle.fontFamilyFor(_lang),
                              fontFamilyFallback:
                                  DedicationStyle.fontFallbackFor(_lang),
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              color: DedicationStyle.ink,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _GoldDivider(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: FadeTransition(
                      opacity: fade,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        child: DedicationKaraoke(
                          text: _text,
                          languageCode: _lang,
                          perCharMs: 400,
                          rowSpacing: 12,
                          onProgress: _followProgress,
                          baseStyle: TextStyle(
                            fontFamily: DedicationStyle.fontFamilyFor(_lang),
                            fontFamilyFallback: DedicationStyle.fontFallbackFor(
                              _lang,
                            ),
                            fontSize: 30,
                            height: 1.5,
                            letterSpacing: 3,
                            color: const Color(0x3D3A2E25), // ink 24%
                          ),
                          fillStyle: TextStyle(
                            fontFamily: DedicationStyle.fontFamilyFor(_lang),
                            fontFamilyFallback: DedicationStyle.fontFallbackFor(
                              _lang,
                            ),
                            fontSize: 30,
                            height: 1.5,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                            color: DedicationStyle.gold,
                            shadows: const [
                              Shadow(color: Color(0x66DCB765), blurRadius: 12),
                            ],
                          ),
                          onCompleted: () {
                            if (mounted) setState(() => _completed = true);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DedicationButton(
                    label: t.dedicationButton,
                    lang: _lang,
                    enabled: _completed,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 26,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xCCB2842E),
                    backgroundColor: const Color(0x12B2842E),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(11),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  tooltip: t.close,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperBackground extends StatelessWidget {
  const _PaperBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.25),
          radius: 1.15,
          colors: [DedicationStyle.paperCenter, DedicationStyle.paperEdge],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.2,
            colors: [Color(0x00000000), Color(0x14000000)], // 暈影
            stops: [0.65, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    Widget line(List<Color> colors) => Container(
      width: 40,
      height: 1,
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(const [Color(0x00B2842E), DedicationStyle.gold]),
        const SizedBox(width: 6),
        Image.asset('assets/images/lotus_divider.png', height: 68),
        const SizedBox(width: 6),
        line(const [DedicationStyle.gold, Color(0x00B2842E)]),
      ],
    );
  }
}

class _DedicationButton extends StatefulWidget {
  const _DedicationButton({
    required this.label,
    required this.lang,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String lang;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_DedicationButton> createState() => _DedicationButtonState();
}

class _DedicationButtonState extends State<_DedicationButton>
    with TickerProviderStateMixin {
  static const double _radius = 30;
  static const double _height = 58;

  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _startFx();
  }

  @override
  void didUpdateWidget(covariant _DedicationButton old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !old.enabled) {
      _startFx();
    } else if (!widget.enabled && old.enabled) {
      _stopFx();
    }
  }

  void _startFx() {
    _breathe.repeat(reverse: true);
    _sweep.repeat();
  }

  void _stopFx() {
    _breathe.stop();
    _sweep.stop();
  }

  @override
  void dispose() {
    _breathe.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      width: double.infinity,
      height: _height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAD9A6), Color(0xFFE0CB90)],
              )
            : null,
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 450),
        style: TextStyle(
          fontFamily: DedicationStyle.fontFamilyFor(widget.lang),
          fontFamilyFallback: DedicationStyle.fontFallbackFor(widget.lang),
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
          color: enabled ? DedicationStyle.gold : const Color(0x59B2842E),
        ),
        child: Text(widget.label),
      ),
    );

    return GestureDetector(
      onTap: enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (_, child) {
          final scale = enabled
              ? 1 + 0.035 * Curves.easeInOut.transform(_breathe.value)
              : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: Stack(
            children: [
              pill,
              if (enabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _sweep,
                      builder: (_, __) => CustomPaint(
                        painter: _SweepBorderPainter(
                          progress: _sweep.value,
                          radius: _radius,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SweepBorderPainter extends CustomPainter {
  _SweepBorderPainter({required this.progress, required this.radius});

  final double progress; // 0..1，光芒繞行一圈的進度
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - 2 * inset,
        size.height - 2 * inset,
      ),
      Radius.circular(radius),
    );
    final shader = SweepGradient(
      transform: GradientRotation(progress * 2 * math.pi),
      colors: const [
        Color(0x00FFF0C4),
        Color(0x00FFF0C4),
        Color(0xFFFFF3D2),
        Color(0x00FFF0C4),
      ],
      stops: const [0.0, 0.58, 0.74, 0.9],
    ).createShader(Offset.zero & size);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_SweepBorderPainter old) => old.progress != progress;
}
