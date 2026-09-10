//amitabha/lib/features/settings/screens/settings_screen.dart
import 'dart:math' as math;

import 'package:amitabha/core/layout/layout_scale.dart';
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/core/widgets/app_bottom_sheet.dart';
import 'package:amitabha/features/announcements/screens/announcements_screen.dart';
import 'package:amitabha/features/background/background_picker_screen.dart';
import 'package:amitabha/features/dedication/screens/dedication_editor_screen.dart';
import 'package:amitabha/features/settings/leaf_layout.dart';
import 'package:amitabha/features/settings/store_actions.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _titleImageLocales = {'zh', 'en', 'ja', 'ko', 'vi', 'de', 'fr'};

String? _titleImage(BuildContext context, String feature) {
  final lang = Localizations.localeOf(context).languageCode;
  if (!_titleImageLocales.contains(lang)) return null;
  return 'assets/images/settings_titles/$lang/title_${feature}_$lang.png';
}

const _breathFloat = 6.0;
const _breathScale = 0.018;
const _breathHold = Duration(milliseconds: 500);

const _titleInkColor = Brand.amitabhaInk;
const _titleGoldColor = Color(0xFFC69E4A);
const _titleGoldSwing = 1.0;

Color _titleColor(double v) => Color.lerp(
  _titleInkColor,
  _titleGoldColor,
  ((v + 1) / 2) * _titleGoldSwing,
)!;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.shortestSide >= 600;
    final isLandscape = size.width > size.height;
    final canvas = !isTablet
        ? SettingsCanvas.phone
        : (isLandscape
              ? SettingsCanvas.tabletLandscape
              : SettingsCanvas.tabletPortrait);

    final canvasSize = settingsCanvasSize[canvas]!;
    LeafRect rectOf(SettingsLeaf leaf) =>
        settingsLeafLayout[leaf]!.forCanvas(canvas);

    final buttons = <Widget>[
      _LeafButton(
        title: t.language,
        image: _titleImage(context, 'language'),
        rect: rectOf(SettingsLeaf.language),
        phase: 0.00,
        period: const Duration(milliseconds: 3400),
        onTap: () => _chooseLanguage(context),
      ),
      _LeafButton(
        title: t.bgScreenTitle,
        image: _titleImage(context, 'background'),
        rect: rectOf(SettingsLeaf.background),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BackgroundPickerScreen()),
        ),
        phase: 0.17,
        period: const Duration(milliseconds: 3900),
      ),
      _LeafButton(
        title: t.announcementsTitle,
        image: _titleImage(context, 'announcements'),
        rect: rectOf(SettingsLeaf.announcements),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
        ),
        phase: 0.34,
        period: const Duration(milliseconds: 3600),
      ),
      _LeafButton(
        title: t.dedicationTitle,
        image: _titleImage(context, 'dedication'),
        rect: rectOf(SettingsLeaf.dedication),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DedicationEditorScreen()),
        ),
        phase: 0.51,
        period: const Duration(milliseconds: 4200),
      ),
      if (isRateSupported)
        _LeafButton(
          title: t.rateTitle,
          image: _titleImage(context, 'rate'),
          rect: rectOf(SettingsLeaf.rate),
          minFontSize: 56,
          phase: 0.68,
          period: const Duration(milliseconds: 3700),
          onTap: () => StoreActions.rate(context),
        ),
      _LeafButton(
        title: t.shareTitle,
        image: _titleImage(context, 'share'),
        rect: rectOf(SettingsLeaf.share),
        phase: 0.85,
        period: const Duration(milliseconds: 4000),
        onTap: () => StoreActions.share(context),
      ),
    ];

    return Brand.withFontFamily(
      context,
      family: Brand.settingsFontFor(Localizations.localeOf(context)),
      fallback: Brand.cjkFallback,
      Stack(
        children: [
          Positioned.fill(
            child: isTablet
                ? Image.asset(
                    'assets/images/bg_bodhi_leaf_bleed.png',
                    fit: BoxFit.cover,
                  )
                : const ColoredBox(color: Brand.cream),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        settingsCanvasBackground[canvas]!,
                        fit: BoxFit.fill,
                      ),
                    ),
                    ...buttons,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _chooseLanguage(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ctrl = context.read<LocaleController>();
    final current = ctrl.locale;

    showAppBottomSheet(
      context: context,
      builder: (sheetContext) {
        final s = layoutScale(sheetContext);
        final base = Theme.of(sheetContext).textTheme.bodyLarge;
        final titleStyle = base?.copyWith(fontSize: (base.fontSize ?? 16) * s);
        final iconSize = 24.0 * s;

        Widget? check(bool isCurrent) => isCurrent
            ? Icon(Icons.check, size: iconSize, color: Brand.settingsBrown)
            : null;

        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              minVerticalPadding: 4 * s,
              titleTextStyle: titleStyle,
              leading: Icon(Icons.settings_backup_restore, size: iconSize),
              title: Text(t.langFollowSystem),
              trailing: check(current == null),
              onTap: () {
                ctrl.useSystem();
                Navigator.pop(sheetContext);
              },
            ),
            const Divider(height: 1),

            for (final lang in LocaleController.supportedLanguages)
              ListTile(
                minVerticalPadding: 4 * s,
                titleTextStyle: titleStyle,
                leading: Icon(Icons.translate, size: iconSize),
                title: Text(lang.endonym),
                trailing: check(_isCurrent(current, lang)),
                onTap: () {
                  ctrl.setLanguage(lang.code);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        );
      },
    );
  }

  bool _isCurrent(Locale? current, AppLanguage lang) {
    if (current == null) return false;
    return current.languageCode == lang.locale.languageCode &&
        current.countryCode == lang.locale.countryCode;
  }
}

TextStyle _leafTextStyle(String fontFamily) => TextStyle(
  fontFamily: fontFamily,
  fontFamilyFallback: Brand.cjkFallback,
  fontWeight: FontWeight.w500,
  height: 1.18,
  color: Brand.settingsTitle,
  shadows: const [
    Shadow(color: Color(0xE6FFFCF3), blurRadius: 14),
    Shadow(color: Color(0x80FFFCF3), blurRadius: 4),
  ],
);

class _LeafButton extends StatefulWidget {
  const _LeafButton({
    required this.title,
    required this.rect,
    required this.onTap,
    required this.phase,
    required this.period,
    this.image,
    this.minFontSize = 50,
  });

  final String title;
  final String? image;
  final LeafRect rect;
  final VoidCallback onTap;
  final double minFontSize;
  final double phase;
  final Duration period;

  @override
  State<_LeafButton> createState() => _LeafButtonState();
}

class _LeafButtonState extends State<_LeafButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late final Duration _cycle = widget.period + _breathHold * 2;

  late final double _holdFraction =
      _breathHold.inMilliseconds / _cycle.inMilliseconds;

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: _cycle,
  )..repeat();

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce) {
      _breath.stop();
    } else {
      _breath.repeat();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final family = Brand.settingsFontFor(Localizations.localeOf(context));
    const anim = Duration(milliseconds: 120);
    return Positioned(
      left: widget.rect.left,
      top: widget.rect.top,
      width: widget.rect.width,
      height: widget.rect.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: _breathe(
          AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: anim,
            curve: Curves.easeOut,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (widget.image != null)
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: AnimatedBuilder(
                      animation: _breath,
                      child: Image.asset(
                        widget.image!,
                        fit: BoxFit.contain,
                        semanticLabel: widget.title,
                      ),
                      builder: (context, child) => ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          _titleColor(_phaseValue()),
                          BlendMode.srcIn,
                        ),
                        child: child,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: _FitText(
                        text: widget.title,
                        style: _leafTextStyle(family),
                        maxFontSize: 72,
                        minFontSize: widget.minFontSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _phaseValue() {
    if (_reduceMotion) return 0.0;
    final u = (_breath.value + widget.phase) % 1.0;
    final h = _holdFraction;
    final m = (1 - 2 * h) / 2;
    if (u < h) return -1.0;
    if (u < h + m) return -math.cos(math.pi * (u - h) / m);
    if (u < 2 * h + m) return 1.0;
    return math.cos(math.pi * (u - 2 * h - m) / m);
  }

  Widget _breathe(Widget child) {
    if (_reduceMotion) return child;
    return AnimatedBuilder(
      animation: _breath,
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        final v = _phaseValue();
        return Transform.translate(
          offset: Offset(0, v * _breathFloat),
          child: Transform.scale(scale: 1 + v * _breathScale, child: child),
        );
      },
    );
  }
}

class _FitText extends StatelessWidget {
  const _FitText({
    required this.text,
    required this.style,
    required this.maxFontSize,
    this.minFontSize = 6,
  });

  final String text;
  final TextStyle style;
  final double maxFontSize;
  final double minFontSize;

  static final RegExp _breakable = RegExp(r'[぀-ヿ㐀-鿿豈-﫿가-힯]');
  static final RegExp _splitter = RegExp(r'[\s‐-―\-]+');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final scaler = MediaQuery.textScalerOf(context);
        final safeW = maxW * 0.96;
        final wordMaxW = maxW * 0.92;

        bool fits(double fontSize) {
          final s = style.copyWith(fontSize: fontSize);
          final tp = TextPainter(
            text: TextSpan(text: text, style: s),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            textScaler: scaler,
            maxLines: 2,
          )..layout(maxWidth: safeW);
          if (tp.didExceedMaxLines) return false;
          if (tp.height > maxH || tp.width > safeW) return false;
          for (final token in text.split(_splitter)) {
            if (token.isEmpty || _breakable.hasMatch(token)) continue;
            final wtp = TextPainter(
              text: TextSpan(text: token, style: s),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
            )..layout();
            if (wtp.width > wordMaxW) return false;
          }
          return true;
        }

        double lo = 6, hi = maxFontSize, best = 6;
        for (var i = 0; i < 12; i++) {
          final mid = (lo + hi) / 2;
          if (fits(mid)) {
            best = mid;
            lo = mid;
          } else {
            hi = mid;
          }
        }

        if (best >= minFontSize) {
          return Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: style.copyWith(fontSize: best),
          );
        }

        final overflowW = maxW * 1.9;
        return OverflowBox(
          alignment: Alignment.center,
          minWidth: 0,
          maxWidth: overflowW,
          minHeight: 0,
          maxHeight: double.infinity,
          child: SizedBox(
            width: overflowW,
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: style.copyWith(fontSize: minFontSize),
            ),
          ),
        );
      },
    );
  }
}
