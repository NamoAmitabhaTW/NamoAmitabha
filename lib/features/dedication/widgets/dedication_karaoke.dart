// amitabha/lib/features/dedication/widgets/dedication_karaoke.dart
import 'package:amitabha/features/dedication/widgets/dedication_paragraph.dart';
import 'package:flutter/material.dart';

class DedicationKaraoke extends StatefulWidget {
  const DedicationKaraoke({
    super.key,
    required this.text,
    this.languageCode,
    this.perCharMs = 400,
    this.baseStyle,
    this.fillStyle,
    this.rowSpacing = 10,
    this.onCompleted,
    this.onProgress,
  });

  final String text;
  final String? languageCode;
  final int perCharMs;
  final TextStyle? baseStyle;
  final TextStyle? fillStyle;
  final double rowSpacing;
  final VoidCallback? onCompleted;
  final ValueChanged<double>? onProgress;

  @override
  State<DedicationKaraoke> createState() => _DedicationKaraokeState();
}

class _DedicationKaraokeState extends State<DedicationKaraoke>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late int _totalMs;
  late bool _isLatin;
  int _fillable = 0;

  String _latinText = '';
  List<int> _latinCut = const [0];
  int _latinTotal = 0;

  List<List<String>> _gridLines = const [];
  List<int> _gridStarts = const [];

  static const int _latinPerCharMs = 75;

  static bool _looksLatin(String t) => RegExp(r'[A-Za-z]').hasMatch(t);

  int get _perCharMs => _isLatin ? _latinPerCharMs : widget.perCharMs;

  void _recompute() {
    _isLatin = _looksLatin(widget.text);
    if (_isLatin) {
      _prepareLatin();
      _fillable = _latinTotal;
    } else {
      _prepareGrid();
      _fillable = _gridStarts.isEmpty
          ? 0
          : _gridLines.fold(0, (a, c) => a + c.length);
    }
    _totalMs = (_fillable * _perCharMs).clamp(1, 1 << 31);
  }

  void _prepareGrid() {
    _gridLines = splitGathaLines(widget.text);
    final starts = <int>[];
    var cursor = 0;
    for (final cells in _gridLines) {
      starts.add(cursor);
      cursor += cells.length * _perCharMs;
    }
    _gridStarts = starts;
  }

  void _prepareLatin() {
    _latinText = widget.text;
    final cuts = <int>[0];
    var offset = 0;
    var fillable = 0;
    for (final g in widget.text.characters) {
      offset += g.length;
      if (g != '\n') {
        fillable++;
        cuts.add(offset);
      }
    }
    _latinCut = cuts;
    _latinTotal = fillable;
  }

  @override
  void initState() {
    super.initState();
    _recompute();
    _ac =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: _totalMs),
          )
          ..addListener(() => widget.onProgress?.call(_ac.value))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onCompleted?.call();
            }
          });
    _ac.forward();
  }

  @override
  void didUpdateWidget(covariant DedicationKaraoke oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.perCharMs != widget.perCharMs) {
      _recompute();
      _ac.duration = Duration(milliseconds: _totalMs);
      _ac.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        widget.baseStyle ??
        const TextStyle(fontSize: 30, height: 1.5, color: Colors.black26);
    final fill =
        widget.fillStyle ??
        const TextStyle(
          fontSize: 30,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB8860B),
        );

    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        final elapsedMs = (_ac.value * _totalMs).round().clamp(0, _totalMs);
        return _isLatin
            ? _buildLatin(elapsedMs, base, fill)
            : _buildGrid(elapsedMs, base, fill);
      },
    );
  }

  static const double _kLatinFontSize = 20.0;
  static const double _kViFontSize = 22.0;
  static const double _kLatinLineHeight = 1.6;
  static const double _kViLineHeight = 1.6;

  Widget _buildLatin(int elapsedMs, TextStyle base, TextStyle fill) {
    final isVi = widget.languageCode == 'vi';
    final size = isVi ? _kViFontSize : _kLatinFontSize;
    final lineHeight = isVi ? _kViLineHeight : _kLatinLineHeight;
    const weight = FontWeight.w500;
    final lbase = base.copyWith(
      fontSize: size,
      height: lineHeight,
      fontWeight: weight,
      shadows: const [],
    );
    final lfill = fill.copyWith(
      fontSize: size,
      height: lineHeight,
      fontWeight: weight,
      shadows: const [],
    );

    final filledCount = (elapsedMs / _perCharMs).floor().clamp(0, _latinTotal);
    final cut = _latinCut[filledCount];
    final filled = _latinText.substring(0, cut);
    final rest = _latinText.substring(cut);

    return Align(
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: filled, style: lfill),
            TextSpan(text: rest, style: lbase),
          ],
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildGrid(int elapsedMs, TextStyle base, TextStyle fill) {
    final lines = _gridLines;
    final starts = _gridStarts;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(lines.length, (li) {
        final cells = lines[li];
        final startMs = starts[li];
        return Padding(
          padding: EdgeInsets.only(
            bottom: li == lines.length - 1 ? 0 : widget.rowSpacing,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: List.generate(cells.length, (i) {
              final cellStart = startMs + i * _perCharMs;
              final prog = ((elapsedMs - cellStart) / _perCharMs).clamp(
                0.0,
                1.0,
              );
              return Expanded(
                child: Center(
                  child: Stack(
                    children: [
                      Text(
                        cells[i],
                        style: base,
                        textAlign: TextAlign.center,
                        softWrap: false,
                      ),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: prog,
                          child: Text(
                            cells[i],
                            style: fill,
                            textAlign: TextAlign.center,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
