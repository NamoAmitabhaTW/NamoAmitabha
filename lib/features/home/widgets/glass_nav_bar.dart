// features/home/widgets/glass_nav_bar.dart
import 'package:flutter/material.dart';

/// 毛玻璃底的底部導覽列。
/// 模糊背後內容 + 半透明底色，讓文字在任何背景（深影片/淺米白）上都可讀。
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.foreground,
    this.blurSigma = 18, // tabbar 模糊重一點，文字更穩
    this.tintOpacity = 0.18, // 玻璃底色濃度
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final double blurSigma;
  final double tintOpacity;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    // 依文字色決定陰影色：淺文字配深陰影、深文字配淺陰影，對比最大化
    final isLightFg = foreground.computeLuminance() > 0.5;
    final shadowColor = isLightFg
        ? Colors.black.withValues(alpha: 0.5) // 白字 → 黑陰影
        : Colors.white.withValues(alpha: 0.6); // 深字 → 白陰影

    final shadows = [
      Shadow(color: shadowColor, blurRadius: 4, offset: const Offset(0, 1)),
    ];

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.transparent, // 透明，露出背景影片/底色
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: foreground,
            shadows: shadows, // ← 文字陰影
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(
            color: foreground,
            shadows: shadows, // ← 圖示陰影（IconThemeData 也支援 shadows）
          ),
        ),
        indicatorColor: foreground.withValues(alpha: 0.18),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}
