// lib/home/presentation/home_shell.dart
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/features/asr/screens/streaming_asr_screen.dart';
import 'package:amitabha/features/home/widgets/glass_nav_bar.dart';
import 'package:amitabha/features/records/screens/records_screen.dart';
import 'package:amitabha/features/settings/screens/settings_screen.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

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

  Widget _pageFor(int i) {
    if (i == 1) {
      final ver = context.select<AsrSessionController, int>((s) => s.dataVersion);
      return KeyedSubtree(key: ValueKey(ver), child: const RecordsScreen());
    }
    return _cache[i] ??= _buildStaticPage(i);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final navFg = _index == 0 ? Colors.white : Brand.amitabhaInk;
        
    return Container(
      decoration: Brand.getBackgroundDecoration(AppThemeStyle.zenWood),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: _index != 2,
        body: _pageFor(_index),
        bottomNavigationBar: GlassNavBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          foreground: navFg,
          glass: _index == 1,
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
