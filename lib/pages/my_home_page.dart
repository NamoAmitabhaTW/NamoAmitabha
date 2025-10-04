import 'package:flutter/material.dart';
import 'package:amitabha/flavors.dart';
import 'package:amitabha/streaming_asr.dart';
import 'package:amitabha/streaming_kws.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget screen =
        (F.appFlavor == Flavor.dev)
            ? const StreamingKwsScreen()
            : const StreamingAsrScreen();

    return Scaffold(body: screen);
  }
}
