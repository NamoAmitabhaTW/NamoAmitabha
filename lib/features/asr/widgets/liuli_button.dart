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
    this.blurSigma = 8, // 比毛玻璃低 → 更通透
    this.borderRadius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    // 琉璃漸層色：預設用木色系，想要七寶池感可換成青綠→琉璃藍
    this.gradientColors,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color foreground;
  final double blurSigma;
  final double borderRadius;
  final EdgeInsets padding;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final wood = Theme.of(context).colorScheme.primary;

    // 預設木色琉璃：深木→淺木的半透明漸層
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
            // ① 漸層染色 → 琉璃的色彩穿透感
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            // ② 高光邊：上緣偏亮、下緣偏暗，做出玻璃反光
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.5 : 0.2),
              width: 1,
            ),
            boxShadow: enabled
                ? [
                    // ③ 內側高光感（用淡白外陰影模擬潤澤光暈）
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
                padding: padding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: effForeground),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: effForeground,
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
