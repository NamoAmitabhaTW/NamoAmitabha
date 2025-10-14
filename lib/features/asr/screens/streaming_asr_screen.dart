// features/asr/screens/streaming_asr_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amitabha/app/application/app_state.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:amitabha/streaming_asr.dart' show StreamingAsrRunner;
import 'dart:ui' show lerpDouble;
import 'dart:math' as math;

class StreamingAsrScreen extends StatelessWidget {
  const StreamingAsrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<AppState>();

    // 拿底部導航的字型做為基礎
    final navLabelBase =
        NavigationBarTheme.of(context).labelTextStyle?.resolve(const {}) ??
        Theme.of(context).textTheme.labelMedium ??
        const TextStyle();

    // 計數字樣式：放大、粗一點、沿用底部導航字型
    final countStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontFamily: navLabelBase.fontFamily,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: navLabelBase.letterSpacing,
    );

    // 水印字樣式：很淡、加字距
    final watermarkBaseStyle =
        (Theme.of(context).textTheme.displayLarge ??
                const TextStyle(fontSize: 48))
            .copyWith(
              fontFamily: navLabelBase.fontFamily,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
            );

    // 顏色：數字用主色，單位用 onSurface 降不透明
    final theme = Theme.of(context);
    final numberColor = theme.colorScheme.primary;
    final unitColor = theme.colorScheme.primary;

    return Stack(
      children: [

        const StreamingAsrRunner(),

        // 聖號水印（可見且偏上）
        PositionedFillWatermark(
          t: t,
          verticalBias: -0.6,
          opacity: 0.12,
          textStyle: watermarkBaseStyle,
        ),

        // 前景內容
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),

              // 「0 次」分色排版
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${s.sessionCount} ',
                        style: countStyle?.copyWith(color: numberColor),
                      ),
                      TextSpan(
                        text: t.times,
                        style: countStyle?.copyWith(
                          color: unitColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (s.isRecording) {
                          s.stopAsr?.call();
                        } else {
                          s.startAsr?.call();
                        }
                      },
                      icon: Icon(
                        s.isRecording ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(s.isRecording ? t.pause : t.start),
                    ),
                  ),

                  // 儲存（實際會呼叫 _onSavePressed -> _commitSession -> 寫入 repo）
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: s.sessionCount > 0 ? s.saveAsr : null,
                      icon: const Icon(Icons.save),
                      label: Text(t.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 其餘類別維持，僅調整 GradientWatermark 支援外部樣式覆寫
class PositionedFillWatermark extends StatelessWidget {
  const PositionedFillWatermark({
    super.key,
    required this.t,
    this.verticalBias = -0.5,
    this.opacity = 0.06,
    this.color,
    this.textStyle,
  });

  final AppLocalizations t;
  final double verticalBias;
  final double opacity;
  final Color? color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        color ?? Theme.of(context).colorScheme.onSurface.withOpacity(opacity);

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment(0, verticalBias),
          child: LayoutBuilder(
            builder: (ctx, c) {
              final fontSize = (c.biggest.shortestSide) * 0.22;
              final style =
                  (textStyle ??
                          Theme.of(context).textTheme.displayLarge ??
                          const TextStyle())
                      .copyWith(
                        fontSize: fontSize,
                        color: (textStyle?.color ?? baseColor),
                      );
              return FittedBox(
                child: Text(
                  t.amitabha,
                  textAlign: TextAlign.center,
                  style: style,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class BreathingWatermark extends StatelessWidget {
  const BreathingWatermark({
    super.key,
    required this.t,
    this.verticalBias = -0.25,
    this.minOpacity = 0.04,
    this.maxOpacity = 0.09,
    this.period = const Duration(seconds: 4),
    this.textStyle,
  });

  final AppLocalizations t;
  final double verticalBias;
  final double minOpacity;
  final double maxOpacity;
  final Duration period;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: period,
      curve: Curves.easeInOut,
      builder: (ctx, v, _) {
        final op = lerpDouble(
          minOpacity,
          maxOpacity,
          (math.sin(v * math.pi * 2) + 1) / 2,
        )!;
        return PositionedFillWatermark(
          t: t,
          verticalBias: verticalBias,
          opacity: op,
          textStyle: textStyle,
        );
      },
      onEnd: () {},
    );
  }
}

class GradientWatermark extends StatelessWidget {
  const GradientWatermark({
    super.key,
    required this.t,
    this.verticalBias = -0.25,
    this.textStyle,
  });

  final AppLocalizations t;
  final double verticalBias;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment(0, verticalBias),
          child: LayoutBuilder(
            builder: (ctx, c) {
              final size = (c.biggest.shortestSide) * 0.22;
              final base =
                  (textStyle ??
                          Theme.of(context).textTheme.displayLarge ??
                          const TextStyle())
                      .copyWith(fontSize: size);

              final gradient = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (base.color ??
                          Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.06))
                      .withOpacity(0.06),
                  Theme.of(context).colorScheme.primary.withOpacity(0.06),
                ],
              );

              return ShaderMask(
                shaderCallback: (rect) => gradient.createShader(rect),
                blendMode: BlendMode.srcIn,
                child: FittedBox(child: Text(t.amitabha, style: base)),
              );
            },
          ),
        ),
      ),
    );
  }
}