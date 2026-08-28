import 'dart:async';

import 'package:amitabha/features/announcements/announcement_controller.dart';
import 'package:amitabha/features/app_update/app_update_controller.dart';
import 'package:amitabha/features/app_update/screens/app_update_screen.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/features/background/background_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  static const Duration _minInterval = Duration(hours: 6);

  DateTime? _lastCheckedAt;

  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _lastCheckedAt = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_run(isStartup: true));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_run(isStartup: false));
  }

  Future<void> _run({required bool isStartup}) async {
    final now = DateTime.now();
    if (!isStartup) {
      final last = _lastCheckedAt;
      if (last != null && now.difference(last) < _minInterval) return;
    }
    _lastCheckedAt = now;

    final update = context.read<AppUpdateController>();
    final asr = context.read<AsrSessionController>();

    if (!isStartup) {
      unawaited(context.read<AnnouncementController>().load());
      unawaited(context.read<BackgroundController>().load());
    }

    if (!await update.check()) return;
    if (!mounted || _showing) return;

    if (asr.isRecording) return;

    _showing = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AppUpdateScreen(),
          fullscreenDialog: true,
        ),
      );
    } finally {
      _showing = false;
    }

    await update.dismiss();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
