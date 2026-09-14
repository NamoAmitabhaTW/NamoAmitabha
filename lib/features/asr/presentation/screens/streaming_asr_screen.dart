// lib/features/asr/presentation/screens/streaming_asr_screen.dart
import 'dart:async';
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/features/asr/presentation/widgets/chanting_background.dart';
import 'package:amitabha/features/asr/presentation/widgets/liuli_button.dart';
import 'package:amitabha/features/background/background.dart';
import 'package:amitabha/features/dedication/dedication.dart';
import 'package:amitabha/features/model_install/model_install.dart';
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

    // Decode the pause art before start() swaps the label, so the button never
    // waits on a decode the model load is about to block.
    if (!context.mounted) return;
    final pauseArt = AppAssets.chantButton(
      Localizations.localeOf(context).languageCode,
      ChantButtonArt.pause,
    );
    if (pauseArt != null) {
      await precacheImage(AssetImage(pauseArt), context);
    }

    await asr.start();
  }

  Future<bool> _prepareBundledModel(BuildContext context) async {
    final t = AppLocalizations.of(context);

    unawaited(
      showDialog(
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
      ),
    );

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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<AsrSessionController>();
    final bg = context.watch<BackgroundController>();
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;

    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    final baseCount = Theme.of(context).textTheme.displayLarge;
    final countStyle = baseCount?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.05,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: (baseCount.fontSize ?? 57.0) * (isTablet ? 2.0 : 1.0),
    );

    final kleeFamily = Brand.primaryFontFor(locale);

    final labelFallbackFamily = Brand.settingsFontFor(locale);

    final numberColor = Colors.white;
    final unitColor = Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;

    final titleToCountGap = (MediaQuery.sizeOf(context).height * 0.375).clamp(
      160.0,
      320.0,
    );

    final titleImage = Image.asset(
      AppAssets.calligraphy(lang),
      width: isTablet
          ? MediaQuery.of(context).size.width.clamp(0.0, 640.0) * 0.88
          : MediaQuery.of(context).size.width.clamp(0.0, 520.0) * 0.8,
      fit: BoxFit.contain,
    );

    Shadow numShadow() => Shadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 6,
      offset: const Offset(0, 1),
    );

    final countWidget = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${s.sessionCount} ',
                style: countStyle?.copyWith(
                  color: numberColor,
                  shadows: [numShadow()],
                ),
              ),
              TextSpan(
                text: t.times,
                style: countStyle?.copyWith(
                  fontFamily: kleeFamily,
                  fontFamilyFallback: Brand.cjkFallback,
                  color: unitColor,
                  fontWeight: FontWeight.w700,
                  fontSize: (countStyle.fontSize ?? 57.0) * 0.62,
                  shadows: [numShadow()],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final startButton = LiuliButton(
      onPressed: () {
        if (s.isRecording) {
          s.stop();
        } else {
          _handleStart(context);
        }
      },
      icon: s.isRecording ? Icons.pause : Icons.play_arrow,
      label: s.isRecording ? t.pause : t.start,

      labelImageAsset: AppAssets.chantButton(
        lang,
        s.isRecording ? ChantButtonArt.pause : ChantButtonArt.start,
      ),
      labelFontFamily: labelFallbackFamily,
      labelFontFamilyFallback: Brand.cjkFallback,
      labelFontSize: 26,
      gradientColors: [
        Colors.white.withValues(alpha: 0.22),
        Colors.white.withValues(alpha: 0.10),
      ],
    );

    final saveButton = LiuliButton(
      onPressed: s.sessionCount > 0 ? () => _handleSave(context) : null,
      icon: Icons.save,
      label: t.save,

      labelImageAsset: AppAssets.chantButton(lang, ChantButtonArt.save),
      labelFontFamily: labelFallbackFamily,
      labelFontFamilyFallback: Brand.cjkFallback,
      labelFontSize: 26,
      gradientColors: [
        Colors.white.withValues(alpha: 0.22),
        Colors.white.withValues(alpha: 0.10),
      ],
    );

    final buttonsRow = Row(
      children: isTablet
          ? [
              Expanded(flex: 2, child: startButton),
              const Spacer(flex: 1),
              Expanded(flex: 2, child: saveButton),
            ]
          : [
              Expanded(child: startButton),
              const SizedBox(width: 16),
              Expanded(child: saveButton),
            ],
    );

    final contentColumn = Column(
      children: isTablet
          ? [
              SizedBox(height: viewPadding.top + 16),
              titleImage,
              const Spacer(),

              Flexible(child: countWidget),
              const Spacer(),
              buttonsRow,
            ]
          : [
              const Spacer(flex: 4),
              titleImage,
              SizedBox(height: titleToCountGap),

              countWidget,
              const Spacer(flex: 10),
              buttonsRow,
            ],
    );

    final content = Padding(
      padding: EdgeInsets.only(bottom: viewPadding.bottom + 120),
      child: Padding(padding: const EdgeInsets.all(20), child: contentColumn),
    );

    final body = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 640 : 520),
        child: content,
      ),
    );

    return FocusTraversalGroup(
      child: Stack(
        children: [
          Positioned.fill(
            child: ChantingBackground(source: bg.currentSource, active: true),
          ),

          body,
        ],
      ),
    );
  }
}
