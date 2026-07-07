// lib/home/presentation/home_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:amitabha/app/app_state.dart';
import 'package:amitabha/features/asr/screens/streaming_asr_screen.dart';
import 'package:amitabha/features/records/screens/records_screen.dart';
import 'package:amitabha/features/settings/screens/settings_screen.dart';
import 'package:amitabha/features/asr/streaming_asr.dart';
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/core/theme/theme_controller.dart';
import 'package:amitabha/features/home/widgets/glass_nav_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// 快取已建立過的頁面（避免重建成本）
  final Map<int, Widget> _cache = {};

  @override
  void initState() {
    super.initState();
  }

  Widget _buildStaticPage(int i) {
    switch (i) {
      case 0:
        return const StreamingAsrScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 只在被選到時才建立頁面
  Widget _pageFor(int i) {
    if (i == 1) {
      // 紀錄頁：依 dataVersion 強制重建以拿到最新 daily JSON
      final ver = context.select<AppState, int>((s) => s.dataVersion);
      return KeyedSubtree(key: ValueKey(ver), child: const RecordsScreen());
    }
    // 其他頁面快取起來（避免每次切頁重建）
    return _cache[i] ??= _buildStaticPage(i);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currentStyle = context.watch<ThemeController>().style;
    // 念佛頁(深影片背景)→ 白；其他頁(淺 cream)→ 深木色
    final navFg = _index == 0
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
        
    return Container(
      decoration: Brand.getBackgroundDecoration(currentStyle),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true, // ← 新增：讓 body（含背景影片）延伸到 tabbar 後面
        body: Stack(children: [_pageFor(_index), const StreamingAsrRunner()]),
        bottomNavigationBar: GlassNavBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          foreground: navFg,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.mic), label: t.chant),
            NavigationDestination(
              icon: const Icon(Icons.list_alt),
              label: t.records,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings),
              label: t.settings,
            ),
          ],
        ),
      ),
    );
  }
}
