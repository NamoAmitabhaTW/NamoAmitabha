// features/asr/widgets/liuli_button.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class LiuliButton extends StatelessWidget {
  const LiuliButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.foreground = Colors.white,
    this.blurSigma = 8, 
    this.borderRadius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.gradientColors,
    this.labelFontFamily,
    this.labelFontFamilyFallback,
    this.labelFontSize = 18,
    this.labelImageAsset,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color foreground;
  final double blurSigma;
  final double borderRadius;
  final EdgeInsets padding;
  final List<Color>? gradientColors;
  final String? labelFontFamily;
  final List<String>? labelFontFamilyFallback;
  final double labelFontSize;
  final String? labelImageAsset;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final wood = Theme.of(context).colorScheme.primary;
    final colors =
        gradientColors ??
        [
          wood.withValues(alpha: enabled ? 0.42 : 0.18),
          wood.withValues(alpha: enabled ? 0.22 : 0.10),
        ];

    final effForeground = enabled
        ? foreground
        : foreground.withValues(alpha: 0.5);
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.5 : 0.2),
              width: 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, -1),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              splashColor: Colors.white.withValues(alpha: 0.2),
              child: Container(
                constraints: const BoxConstraints(minHeight: 60),
                alignment: Alignment.center,
                padding: labelImageAsset != null
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                    : padding,
                child: labelImageAsset != null
                    ? Image.asset(
                        labelImageAsset!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        color: effForeground,
                        colorBlendMode: BlendMode.srcIn,
                        semanticLabel: label,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 20, color: effForeground),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontFamily: labelFontFamily,
                                  fontFamilyFallback: labelFontFamilyFallback,
                                  fontSize: labelFontSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  color: effForeground,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
