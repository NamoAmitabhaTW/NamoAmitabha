// lib/features/dedication/presentation/screens/dedication_screen.dart
import 'dart:math' as math;
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:amitabha/core/layout/layout_scale.dart';
import 'package:amitabha/core/widgets/content_width.dart';
import 'package:amitabha/features/dedication/application/dedication_controller.dart';
import 'package:amitabha/features/dedication/presentation/dedication_style.dart';
import 'package:amitabha/features/dedication/presentation/widgets/dedication_karaoke.dart';
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

    final scale = layoutScale(context);

    final fade = _enterFade;
    final slide = _enterSlide;

    final verse = TextStyle(
      fontFamily: DedicationStyle.fontFamilyFor(_lang),
      fontFamilyFallback: DedicationStyle.fontFallbackFor(_lang),
      fontSize: 30 * scale,
      height: 1.5,
      letterSpacing: 3 * scale,
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _PaperBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                28 * scale,
                8,
                28 * scale,
                28 * scale,
              ),
              child: Column(
                children: [
                  SizedBox(height: 44 * scale),
                  FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: Column(
                        children: [
                          _DedicationTitle(
                            text: t.dedicationTitle,
                            lang: _lang,
                            scale: scale,

                            maxHeight: MediaQuery.sizeOf(context).height * 0.22,
                          ),
                          SizedBox(height: 16 * scale),
                          _GoldDivider(scale: scale),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Expanded(
                    child: FadeTransition(
                      opacity: fade,

                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          controller: _scroll,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: box.maxHeight,
                            ),
                            child: Center(
                              child: DedicationKaraoke(
                                text: _text,
                                languageCode: _lang,
                                perCharMs: 400,
                                rowSpacing: 12 * scale,
                                scale: scale,
                                onProgress: _followProgress,
                                baseStyle: verse.copyWith(
                                  color: const Color(0x3D3A2E25),
                                ),
                                fillStyle: verse.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: DedicationStyle.gold,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0x66DCB765),
                                      blurRadius: 12 * scale,
                                    ),
                                  ],
                                ),
                                onCompleted: () {
                                  if (mounted) {
                                    setState(() => _completed = true);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),

                  ContentWidth(
                    maxWidth: 340 * scale,
                    child: _DedicationButton(
                      label: t.dedicationButton,
                      lang: _lang,
                      scale: scale,
                      enabled: _completed,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
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
                  iconSize: 26 * scale,

                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xCCB2842E),
                    backgroundColor: const Color(0x12B2842E),
                    shape: const CircleBorder(),
                    padding: EdgeInsets.all(11 * scale),
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

class _DedicationTitle extends StatelessWidget {
  const _DedicationTitle({
    required this.text,
    required this.lang,
    required this.scale,
    required this.maxHeight,
  });

  final String text;
  final String lang;
  final double scale;

  final double maxHeight;

  static const double _baseFontSize = 34;

  static const double _minVisualFontSize = 20;

  static const int _searchSteps = 12;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: DedicationStyle.fontFamilyFor(lang),
      fontFamilyFallback: DedicationStyle.fontFallbackFor(lang),

      height: 1.3,
      fontWeight: FontWeight.w600,
      color: DedicationStyle.ink,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final baseSize = _baseFontSize * scale;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          return Text(text, textAlign: TextAlign.center, style: base);
        }

        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);

        bool fits(double size) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: _sized(base, size)),
            maxLines: 2,
            textScaler: scaler,
            textAlign: TextAlign.center,
            textDirection: direction,
          )..layout(maxWidth: maxWidth);
          return !painter.didExceedMaxLines && painter.height <= maxHeight;
        }

        var fitted = baseSize;
        if (!fits(baseSize)) {
          final factor = scaler.scale(1000) / 1000;
          final lowLimit = factor > 0
              ? _minVisualFontSize / factor
              : _minVisualFontSize;

          var low = lowLimit;
          var high = baseSize;
          for (var i = 0; i < _searchSteps; i++) {
            final mid = (low + high) / 2;
            if (fits(mid)) {
              low = mid;
            } else {
              high = mid;
            }
          }

          fitted = low;
        }

        return Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,

          overflow: TextOverflow.ellipsis,
          style: _sized(base, fitted),
        );
      },
    );
  }

  TextStyle _sized(TextStyle base, double size) => base.copyWith(
    fontSize: size,
    letterSpacing: 8 * scale * (size / (_baseFontSize * scale)),
  );
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
            colors: [Color(0x00000000), Color(0x14000000)],
            stops: [0.65, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    Widget line(List<Color> colors) => Container(
      width: 40 * scale,
      height: 1,
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(const [Color(0x00B2842E), DedicationStyle.gold]),
        SizedBox(width: 6 * scale),

        Image.asset(AppAssets.lotusDivider, height: 68 * scale),
        SizedBox(width: 6 * scale),
        line(const [DedicationStyle.gold, Color(0x00B2842E)]),
      ],
    );
  }
}

class _DedicationButton extends StatefulWidget {
  const _DedicationButton({
    required this.label,
    required this.lang,
    required this.scale,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String lang;
  final double scale;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_DedicationButton> createState() => _DedicationButtonState();
}

class _DedicationButtonState extends State<_DedicationButton>
    with TickerProviderStateMixin {
  double get _radius => 30 * widget.scale;
  double get _height => 58 * widget.scale;

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
      constraints: BoxConstraints(minHeight: _height),
      padding: EdgeInsets.symmetric(vertical: 6 * widget.scale),
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
          fontSize: 30 * widget.scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 6 * widget.scale,
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

  final double progress;
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
