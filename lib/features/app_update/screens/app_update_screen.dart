// lib/features/app_update/screens/app_update_screen.dart
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/features/app_update/app_update_controller.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppUpdateScreen extends StatelessWidget {
  const AppUpdateScreen({super.key});

  Future<void> _openStore(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);

    final ok = await context.read<AppUpdateController>().openStore();
    if (ok) {
      await navigator.maybePop();
    } else {
      messenger?.showSnackBar(SnackBar(content: Text(t.storeActionFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final maxWidth = isTablet ? 520.0 : 400.0;
    final titleSize = isTablet ? 30.0 : 24.0;
    final bodySize = isTablet ? 18.0 : 16.0;
    final nameSize = isTablet ? 17.0 : 15.0;
    final buttonSize = isTablet ? 19.0 : 17.0;

    return Scaffold(
      backgroundColor: Brand.cream,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  color: Brand.settingsBrownSoft,
                  tooltip: t.updateLater,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 72, 32, 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AppIconBadge(size: isTablet ? 140 : 104),
                              const SizedBox(height: 12),
                              Text(
                                t.appDisplayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: nameSize,
                                  height: 1.3,
                                  color: Brand.amitabhaInk,
                                ),
                              ),
                              const SizedBox(height: 36),
                              _AutoShrinkText(
                                t.updateTitle,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: Brand.settingsTitle,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t.updateBody,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: bodySize,
                                  height: 1.7,
                                  color: Brand.settingsBrownSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _openStore(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: Brand.settingsBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            t.updateButton,
                            style: TextStyle(
                              fontSize: buttonSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIconBadge extends StatelessWidget {
  const _AppIconBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.224),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.224),
        child: Image.asset(
          AppAssets.appIcon,
          width: size,
          height: size,
          fit: BoxFit.cover,

          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _AutoShrinkText extends StatelessWidget {
  const _AutoShrinkText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  static const double minScale = 0.75;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final base = effective.fontSize ?? 24;
    final minSize = base * minScale;
    final allowedLines = '\n'.allMatches(text).length + 1;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        var size = base;
        var fits = false;
        while (size >= minSize) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: effective.copyWith(fontSize: size),
            ),
            textDirection: direction,
            textAlign: TextAlign.center,
            textScaler: scaler,
            maxLines: allowedLines,
          )..layout(maxWidth: constraints.maxWidth);
          final overflowed = painter.didExceedMaxLines;
          painter.dispose();
          if (!overflowed) {
            fits = true;
            break;
          }
          size -= 1;
        }

        if (!fits) size = base;

        return Text(
          text,
          textAlign: TextAlign.center,

          style: effective.copyWith(fontSize: size),
        );
      },
    );
  }
}
