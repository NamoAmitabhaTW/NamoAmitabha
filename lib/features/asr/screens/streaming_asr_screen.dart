// features/asr/screens/streaming_asr_screen.dart
import 'dart:async';

import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/features/asr/widgets/chanting_background.dart';
import 'package:amitabha/features/asr/widgets/liuli_button.dart';
import 'package:amitabha/features/background/background_controller.dart';
import 'package:amitabha/features/dedication/screens/dedication_screen.dart';
import 'package:amitabha/features/dedication/screens/lotus_overlay.dart';
import 'package:amitabha/features/model_install/bundled_model.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class StreamingAsrScreen extends StatelessWidget {
  const StreamingAsrScreen({super.key});

  Future<void> _handleStart(BuildContext context) async {
    final asr = context.read<AsrSessionController>();
    if (!await bundledModelReady(kAsrModelName)) {
      if (!context.mounted) return;
      final ready = await _prepareBundledModel(context);
      if (!ready) return;  
      if (!context.mounted) return;
    }

    final granted = await asr.hasMicPermission();
    if (!granted) {
      if (!context.mounted) return;
      await _showOpenSettingsDialog(context);
      return;
    }

    await asr.start();
  }

  Future<bool> _prepareBundledModel(BuildContext context) async {
    final t = AppLocalizations.of(context);

    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(t.preparingPleaseWait)),
            ],
          ),
        ),
      ),
    ));

    try {
      await materializeBundledModel(kAsrModelName);
    } catch (_) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(t.modelPrepareFailed),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t.ok),
            ),
          ],
        ),
      );
      return false;
    }

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    return true;
  }

  Future<void> _handleSave(BuildContext context) async {
    final asr = context.read<AsrSessionController>();
    await asr.save();
    if (!context.mounted) return;
    final dedicated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const DedicationScreen(),
      ),
    );
    if (dedicated == true && context.mounted) {
      await showLotusCelebration(context);
    }
  }

  Future<void> _showOpenSettingsDialog(BuildContext context) async {
    final t = AppLocalizations.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.micPermissionTitle),
        content: Text(t.micPermissionRationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await openAppSettings(); 
            },
            child: Text(t.openSettings),
          ),
        ],
      ),
    );
  }

  static String _calligraphyAsset(String lang) {
    switch (lang) {
      case 'ja':
        return 'assets/images/amitabha_calligraphy_ja.png';
      case 'ko':
        return 'assets/images/amitabha_calligraphy_ko.png';
      case 'vi':
        return 'assets/images/amitabha_calligraphy_vi.png';
      case 'en':
      case 'de':
      case 'fr':
        return 'assets/images/amitabha_calligraphy_sa.png';
      case 'zh':
      default:
        return 'assets/images/amitabha_calligraphy.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<AsrSessionController>();
    final bg = context.watch<BackgroundController>();
    final lang = Localizations.localeOf(context).languageCode;

    final navLabelBase =
        NavigationBarTheme.of(context).labelTextStyle?.resolve(const {}) ??
        Theme.of(context).textTheme.labelMedium ??
        const TextStyle();

    final countStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontFamily: navLabelBase.fontFamily,
      fontWeight: FontWeight.w600,
      height: 1.05,
      letterSpacing: navLabelBase.letterSpacing,
    );


    final numberColor = Colors.white;
    final unitColor = Colors.white;

   
    final viewPadding = MediaQuery.of(context).viewPadding;
  
    return FocusTraversalGroup(
      child: Stack(
        children: [
         
          Positioned.fill(
            child: ChantingBackground(source: bg.currentSource, active: true),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: viewPadding.bottom + 120),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(flex: 4),
                  Image.asset(
                    _calligraphyAsset(lang),
                    width: MediaQuery.of(context).size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 320),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${s.sessionCount} ',
                            style: countStyle?.copyWith(
                              color: numberColor,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: t.times,
                            style: countStyle?.copyWith(
                              color: unitColor,
                              fontWeight: FontWeight.w400,
                              fontSize: (countStyle.fontSize ?? 57.0) * 0.62,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LiuliButton(
                          onPressed: () {
                            if (s.isRecording) {
                              s.stop();
                            } else {
                              _handleStart(context);
                            }
                          },
                          icon: s.isRecording ? Icons.pause : Icons.play_arrow,
                          label: s.isRecording ? t.pause : t.start,
                          gradientColors: [
                            Colors.white.withValues(
                              alpha: 0.22,
                            ), 
                            Colors.white.withValues(alpha: 0.10), 
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: LiuliButton(
                          onPressed: s.sessionCount > 0
                              ? () => _handleSave(context)
                              : null,
                          icon: Icons.save,
                          label: t.save,
                          gradientColors: [
                            Colors.white.withValues(
                              alpha: 0.22,
                            ), 
                            Colors.white.withValues(alpha: 0.10), 
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
