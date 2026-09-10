// lib/features/home/presentation/widgets/glass_nav_bar.dart
import 'dart:ui' show ImageFilter;
import 'package:amitabha/core/theme/brand.dart';
import 'package:flutter/material.dart';

class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.foreground,
    this.glass = false,
    this.blurSigma = 18,
    this.tintOpacity = 0.18,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  final bool glass;
  final double blurSigma;
  final double tintOpacity;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final isLightFg = foreground.computeLuminance() > 0.5;
    final shadows = isLightFg
        ? [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ]
        : const <Shadow>[];

    final locale = Localizations.localeOf(context);

    final Widget bar = NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: Brand.primaryFontFor(locale),
            fontFamilyFallback: Brand.cjkFallback,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: foreground,
            shadows: shadows,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: foreground, shadows: shadows),
        ),
        indicatorColor: foreground.withValues(alpha: 0.18),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );

    if (!glass) return bar;

    final tint = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: tintOpacity);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(color: tint),
          child: bar,
        ),
      ),
    );
  }
}
