// lib/features/dedication/screens/dedication_editor_screen.dart
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:amitabha/core/layout/layout_scale.dart';
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/features/dedication/dedication_controller.dart';
import 'package:amitabha/features/dedication/dedication_style.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DedicationEditorScreen extends StatefulWidget {
  const DedicationEditorScreen({super.key});

  @override
  State<DedicationEditorScreen> createState() => _DedicationEditorScreenState();
}

class _DedicationEditorScreenState extends State<DedicationEditorScreen>
    with WidgetsBindingObserver {
  late final DedicationController _dedication;
  TextEditingController? _controller;
  String _lang = 'zh';
  String _lastSaved = '';
  bool _initialized = false;

  bool get _isLatin => const {'en', 'de', 'fr', 'vi'}.contains(_lang);

  static const double _latinFontSize = 20.0;
  static const double _viFontSize = 22.0;
  static const double _latinLineHeight = 1.6;
  static const double _viLineHeight = 1.6;

  static const List<String> _editFontFallback = <String>[
    'NotoSerifGathaJP',
    'NotoSerifGathaKR',
    Brand.lxgwWenkaiTc,
  ];

  TextStyle get _editStyle {
    final s = layoutScale(context);
    return _isLatin
        ? TextStyle(
            fontFamily: Brand.notoSerifTc,
            fontFamilyFallback: _editFontFallback,
            fontSize: (_lang == 'vi' ? _viFontSize : _latinFontSize) * s,
            height: _lang == 'vi' ? _viLineHeight : _latinLineHeight,
            fontWeight: FontWeight.w500,
            color: Brand.settingsBrown,
          )
        : TextStyle(
            fontFamily: Brand.notoSerifTc,
            fontFamilyFallback: _editFontFallback,
            fontSize: 30 * s,
            height: 1.5,
            letterSpacing: 3 * s,
            color: Brand.settingsBrown,
          );
  }

  @override
  void initState() {
    super.initState();
    _dedication = context.read<DedicationController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _lang = Localizations.localeOf(context).languageCode;
    final text = _dedication.textFor(_lang);
    _controller = TextEditingController(text: text);
    _lastSaved = text;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _persistIfChanged();
    }
  }

  void _persistIfChanged() {
    final text = _controller?.text;
    if (text == null || text == _lastSaved) return;
    _lastSaved = text;
    _dedication.saveFor(_lang, text);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _persistIfChanged();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    final isCjkTitle =
        locale.languageCode == 'zh' || locale.languageCode == 'ja';
    final s = layoutScale(context);

    return DecoratedBox(
      decoration: _paperDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Brand.settingsBrownSoft),

          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              t.dedicationEdit,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: Brand.notoSerifTc,
                fontFamilyFallback: _editFontFallback,
                fontSize: 22 * s,
                fontWeight: FontWeight.w600,
                letterSpacing: (isCjkTitle ? 4 : 0.5) * s,
                color: Brand.settingsTitle,
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 16 * s),
            child: Column(
              children: [
                _GoldDivider(scale: s),
                SizedBox(height: 16 * s),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Brand.settingsCardBg,
                      borderRadius: BorderRadius.circular(20 * s),

                      border: Border.all(
                        color: const Color(0x22B2842E),
                        width: 1,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x146F4E37),
                          blurRadius: 24,
                          spreadRadius: -6,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20 * s),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: _editStyle,
                      cursorColor: DedicationStyle.gold,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
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
}

final BoxDecoration _paperDecoration = const BoxDecoration(
  gradient: RadialGradient(
    center: Alignment(0, -0.25),
    radius: 1.15,
    colors: [DedicationStyle.paperCenter, DedicationStyle.paperEdge],
  ),
);

class _GoldDivider extends StatelessWidget {
  const _GoldDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    Widget line(List<Color> colors) => Container(
      width: 56 * scale,
      height: 1,
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        line(const [Color(0x00B2842E), DedicationStyle.gold]),
        SizedBox(width: 8 * scale),

        Image.asset(AppAssets.lotusDivider, height: 32 * scale),
        SizedBox(width: 8 * scale),
        line(const [DedicationStyle.gold, Color(0x00B2842E)]),
      ],
    );
  }
}
