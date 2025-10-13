//amitabha/lib/home/presentation/home_shell.dart
import 'package:flutter/material.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:amitabha/features/asr/screens/streaming_asr_screen.dart';
import 'package:amitabha/features/records/screens/records_screen.dart';
import 'package:amitabha/features/settings/screens/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pages = <Widget>[
      const StreamingAsrScreen(), 
      const RecordsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
    );
  }
}
