import 'dart:math' as math;

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
    this.scale = 1.0,
    this.onCompleted,
    this.onProgress,
  });

  final String text;
  final String? languageCode;
  final int perCharMs;
  final TextStyle? baseStyle;
  final TextStyle? fillStyle;
  final double rowSpacing;

  final double scale;

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

  bool _isLineStructured = false;
  List<String> _lineTexts = const [];
  List<List<int>> _lineCuts = const [];

  List<List<String>> _gridLines = const [];
  List<int> _gridStarts = const [];

  static const int _latinPerCharMs = 75;

  static bool _looksLatin(String t) => RegExp(r'[A-Za-z]').hasMatch(t);

  static const int _kLineStructuredMaxChars = 40;

  static bool _looksLineStructured(String t) {
    final lines = t.split('\n');
    if (lines.length < 2) return false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return false;
      if (trimmed.characters.length > _kLineStructuredMaxChars) return false;
    }
    return true;
  }

  int get _perCharMs => _isLatin ? _latinPerCharMs : widget.perCharMs;

  void _recompute() {
    _isLatin = _looksLatin(widget.text);
    _isLineStructured = _isLatin && _looksLineStructured(widget.text);
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

    if (!_isLineStructured) {
      _lineTexts = const [];
      _lineCuts = const [];
      return;
    }
    final texts = <String>[];
    final lineCuts = <List<int>>[];
    for (final line in widget.text.split('\n')) {
      texts.add(line);
      final marks = <int>[0];
      var at = 0;
      for (final g in line.characters) {
        at += g.length;
        marks.add(at);
      }
      lineCuts.add(marks);
    }
    _lineTexts = texts;
    _lineCuts = lineCuts;
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

    if (!_isLatin) {
      return LayoutBuilder(
        builder: (context, box) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: _gridMaxTextScale(box.maxWidth, base),
          child: AnimatedBuilder(
            animation: _ac,
            builder: (clampedContext, __) =>
                _buildGrid(clampedContext, _elapsedMs, base, fill),
          ),
        ),
      );
    }

    final size = _latinFontSize;
    final lbase = _latinStyle(base, size);
    final lfill = _latinStyle(fill, size);

    if (!_isLineStructured) {
      return AnimatedBuilder(
        animation: _ac,
        builder: (_, __) => _buildLatinFlow(context, _elapsedMs, lbase, lfill),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final fitted = _fitLineFontSize(context, box.maxWidth, lbase, size);
        if (fitted == null) {
          return AnimatedBuilder(
            animation: _ac,
            builder: (_, __) =>
                _buildLatinFlow(context, _elapsedMs, lbase, lfill),
          );
        }
        return AnimatedBuilder(
          animation: _ac,
          builder: (_, __) => _buildLines(
            _elapsedMs,
            lbase.copyWith(fontSize: fitted),
            lfill.copyWith(fontSize: fitted),
          ),
        );
      },
    );
  }

  int get _elapsedMs => (_ac.value * _totalMs).round().clamp(0, _totalMs);

  static const double _kLatinFontSize = 20.0;
  static const double _kViFontSize = 22.0;
  static const double _kLatinLineHeight = 1.6;
  static const double _kViLineHeight = 1.6;

  static const double _kLatinMeasureEm = 32.0;

  static const double _kCellToGlyph = 2.0;

  static const double _kLatinMinFontSize = 14.0;

  double get _latinFontSize =>
      (widget.languageCode == 'vi' ? _kViFontSize : _kLatinFontSize) *
      widget.scale;

  double get _latinLineHeight =>
      widget.languageCode == 'vi' ? _kViLineHeight : _kLatinLineHeight;

  TextStyle _latinStyle(TextStyle from, double size) => from.copyWith(
    fontSize: size,
    height: _latinLineHeight,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    shadows: const [],
  );

  double? _fitLineFontSize(
    BuildContext context,
    double maxWidth,
    TextStyle style,
    double size,
  ) {
    if (!maxWidth.isFinite || maxWidth <= 0) return size;

    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var widest = 0.0;
    for (final line in _lineTexts) {
      if (line.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: line, style: style),
        maxLines: 1,
        textScaler: scaler,
        textDirection: direction,
      )..layout();
      widest = math.max(widest, painter.width);
    }
    if (widest <= 0) return size;

    final factor = widest <= maxWidth ? 1.0 : maxWidth / widest;
    if (scaler.scale(size) * factor < _kLatinMinFontSize) return null;
    return size * factor;
  }

  Widget _buildLines(int elapsedMs, TextStyle lbase, TextStyle lfill) {
    final filledCount = (elapsedMs / _perCharMs).floor().clamp(0, _latinTotal);
    var remaining = filledCount;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_lineTexts.length, (i) {
          final text = _lineTexts[i];
          final cuts = _lineCuts[i];
          final chars = cuts.length - 1;
          final cut = cuts[remaining.clamp(0, chars)];
          remaining -= chars;
          return Text.rich(
            TextSpan(
              children: [
                TextSpan(text: text.substring(0, cut), style: lfill),
                TextSpan(text: text.substring(cut), style: lbase),
              ],
            ),
            softWrap: false,
            maxLines: 1,
            textAlign: TextAlign.left,
          );
        }),
      ),
    );
  }

  Widget _buildLatinFlow(
    BuildContext context,
    int elapsedMs,
    TextStyle lbase,
    TextStyle lfill,
  ) {
    final filledCount = (elapsedMs / _perCharMs).floor().clamp(0, _latinTotal);
    final cut = _latinCut[filledCount];
    final filled = _latinText.substring(0, cut);
    final rest = _latinText.substring(cut);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              _kLatinMeasureEm *
              MediaQuery.textScalerOf(
                context,
              ).scale(lbase.fontSize ?? _kLatinFontSize),
        ),
        child: Align(
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
        ),
      ),
    );
  }

  double _gridMaxTextScale(double availableWidth, TextStyle base) {
    if (!availableWidth.isFinite || availableWidth <= 0) {
      return double.infinity;
    }
    final longest = _gridLines.fold<int>(0, (a, c) => math.max(a, c.length));
    final fontSize = base.fontSize ?? 30;
    if (longest <= 0 || fontSize <= 0) return double.infinity;

    final cell = availableWidth / longest;
    return math.max(1.0, (cell - (base.letterSpacing ?? 0)) / fontSize);
  }

  Widget _buildGrid(
    BuildContext context,
    int elapsedMs,
    TextStyle base,
    TextStyle fill,
  ) {
    final lines = _gridLines;
    final starts = _gridStarts;

    final longest = lines.fold<int>(0, (a, c) => math.max(a, c.length));
    final scaler = MediaQuery.textScalerOf(context);
    final glyph = scaler.scale(base.fontSize ?? 30) + (base.letterSpacing ?? 0);
    final maxWidth = longest * glyph * _kCellToGlyph;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
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
        ),
      ),
    );
  }
}
