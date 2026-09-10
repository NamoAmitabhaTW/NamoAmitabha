// lib/app/orientation_lock.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrientationLock extends StatefulWidget {
  const OrientationLock({super.key, required this.child});

  final Widget child;

  @override
  State<OrientationLock> createState() => _OrientationLockState();
}

class _OrientationLockState extends State<OrientationLock>
    with WidgetsBindingObserver {
  bool? _lockedToPortrait;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _apply();

  void _apply() {
    if (!mounted) return;

    final display = View.of(context).display;

    final screenShortestSide =
        display.size.shortestSide / display.devicePixelRatio;
    final shouldLock = screenShortestSide < 600;

    if (_lockedToPortrait == shouldLock) return;
    _lockedToPortrait = shouldLock;

    SystemChrome.setPreferredOrientations(
      shouldLock
          ? const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
          : const [],
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
