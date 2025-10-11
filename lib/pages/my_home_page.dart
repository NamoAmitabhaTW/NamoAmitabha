import 'package:flutter/material.dart';
import 'package:amitabha/flavors.dart';
import 'package:amitabha/streaming_asr.dart';
import 'package:amitabha/streaming_kws.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // 取得翻譯器
    final screen = (F.appFlavor == Flavor.dev)
        ? const StreamingAsrScreen()
        : const StreamingKwsScreen();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.amitabha),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              PopupMenuItem(value: 'start', child: Text(t.start)),
              PopupMenuItem(value: 'pause', child: Text(t.pause)),
              PopupMenuItem(value: 'save', child: Text(t.save)),
              PopupMenuItem(value: 'logIn', child: Text(t.logIn)),
              PopupMenuItem(value: 'logOut', child: Text(t.logOut)),
            ],
          ),
        ],
      ),
      body: screen,
    );
  }
}
