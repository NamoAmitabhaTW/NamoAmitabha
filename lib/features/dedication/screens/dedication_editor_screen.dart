// amitabha/lib/features/dedication/screens/dedication_editor_screen.dart
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/features/dedication/dedication_controller.dart';
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

  TextStyle get _editStyle => _isLatin
      ? TextStyle(
          fontSize: _lang == 'vi' ? _viFontSize : _latinFontSize,
          height: _lang == 'vi' ? _viLineHeight : _latinLineHeight,
          fontWeight: FontWeight.w500,
          color: Brand.settingsBrown,
        )
      : const TextStyle(
          fontSize: 30,
          height: 1.5,
          letterSpacing: 3,
          color: Brand.settingsBrown,
        );

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

    return Scaffold(
      appBar: AppBar(title: Text(t.dedicationEdit)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Brand.settingsCardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Brand.settingsShadow,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            style: _editStyle,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
      ),
    );
  }
}
