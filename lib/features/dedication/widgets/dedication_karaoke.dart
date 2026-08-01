import 'package:amitabha/features/dedication/widgets/dedication_paragraph.dart';
import 'package:flutter/material.dart';

/// 迴向偈的 KTV 逐字填色效果。
/// - 中日韓（方塊字）：以「行」為單位，每行等寬均分、逐字由左至右填滿。
/// - 拉丁文字（英/德/法/越南）：自然換行的整段文字，逐字依閱讀順序填色。
/// - 全部跑完後呼叫 [onCompleted]（只會呼叫一次）。
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

  final String text; // 可含多行（\n）
  final String? languageCode; // 用於拉丁文字的語系微調（如越南語字級）
  final int perCharMs; // 每個字填滿所需毫秒數（方塊字用；拉丁文字另用較快速度）
  final TextStyle? baseStyle;
  final TextStyle? fillStyle;
  final double rowSpacing;
  final VoidCallback? onCompleted;
  final ValueChanged<double>? onProgress; // 動畫進度 0..1（供自動捲動）

  @override
  State<DedicationKaraoke> createState() => _DedicationKaraokeState();
}

class _DedicationKaraokeState extends State<DedicationKaraoke>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late int _totalMs;
  late bool _isLatin;
  int _fillable = 0;

  // 拉丁版快取：僅在文字變更時計算，避免每幀重做字素切分與計數。
  String _latinText = '';
  List<int> _latinCut = const [0]; // 第 k 個可填字之後的字串位移
  int _latinTotal = 0;

  // 方塊字版快取：解析後的行與每行起始時間，僅文字/速度變更時重算。
  List<List<String>> _gridLines = const [];
  List<int> _gridStarts = const [];

  // 拉丁文字字數遠多於方塊字，需用較快的逐字速度才不會過久。
  static const int _latinPerCharMs = 75;

  static bool _looksLatin(String t) => RegExp(r'[A-Za-z]').hasMatch(t);

  int get _perCharMs => _isLatin ? _latinPerCharMs : widget.perCharMs;

  /// 文字變更時重算：判斷語系、算可填字數（拉丁另建切點快取）、更新總時長。
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

  /// 預先解析方塊字的行與每行起始時間，之後每幀直接取用、不再重新切分。
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

  /// 預先算好整段字串與每個「可填字」對應的切點，之後每幀只需兩次 substring。
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
    _ac = AnimationController(
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
    final base = widget.baseStyle ??
        const TextStyle(fontSize: 30, height: 1.5, color: Colors.black26);
    final fill = widget.fillStyle ??
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

  /// 拉丁文字：整段自然換行、靠左對齊，依閱讀順序把前 N 個字上色。
  /// 已填/未填「只差顏色」，字級與字重完全相同 → 不會因換色而重排、無抖動。
  // 拉丁文字字級 / 行距：英/德/法共用；越南語可獨立調整。
  static const double _kLatinFontSize = 20.0;
  static const double _kViFontSize = 22.0; // ← 調整越南語迴向頁字級
  static const double _kLatinLineHeight = 1.6;
  static const double _kViLineHeight = 1.6; // ← 調整越南語迴向頁行距

  Widget _buildLatin(int elapsedMs, TextStyle base, TextStyle fill) {
    final isVi = widget.languageCode == 'vi';
    final size = isVi ? _kViFontSize : _kLatinFontSize;
    final lineHeight = isVi ? _kViLineHeight : _kLatinLineHeight;
    const weight = FontWeight.w500;
    // 以 copyWith 保留傳入樣式的字型（明體）與 fallback；拉丁段落不加光暈。
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

    // 每幀只做兩次 substring（切點在文字變更時已預先算好）。
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

  /// 方塊字：每行等寬均分、逐字由左至右填滿。（行與起始時間已預先快取）
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
              final prog =
                  ((elapsedMs - cellStart) / _perCharMs).clamp(0.0, 1.0);
              return Expanded(
                child: Center(
                  child: Stack(
                    children: [
                      Text(cells[i],
                          style: base,
                          textAlign: TextAlign.center,
                          softWrap: false),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: prog,
                          child: Text(cells[i],
                              style: fill,
                              textAlign: TextAlign.center,
                              softWrap: false),
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
