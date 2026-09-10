// amitabha/lib/features/announcements/widgets/simple_markdown.dart
import 'package:amitabha/core/theme/brand.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SimpleMarkdown extends StatefulWidget {
  const SimpleMarkdown({
    super.key,
    required this.data,
    this.onLinkTap,
    this.textColor = Brand.settingsTitle,
    this.headingColor = Brand.settingsTitle,
    this.linkColor = Brand.settingsBrownSoft,
    this.accentColor,
    this.justify = false,
    this.baseFontSize = 18,
    this.scale = 1.0,
  });

  static const List<String> cjkFallback = [
    'PingFang TC',
    'PingFang SC',
    'Heiti TC',
    'Songti TC',
    'Microsoft JhengHei',
    'Noto Sans CJK TC',
    'sans-serif',
  ];

  final String data;
  final void Function(String url)? onLinkTap;
  final Color textColor;
  final Color headingColor;
  final Color linkColor;

  final Color? accentColor;

  final bool justify;

  final double baseFontSize;

  final double scale;

  @override
  State<SimpleMarkdown> createState() => _SimpleMarkdownState();
}

class _SimpleMarkdownState extends State<SimpleMarkdown> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final blocks = _splitBlocks(widget.data);
    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final w = _buildBlock(blocks[i]);
      if (w == null) continue;
      if (children.isNotEmpty) children.add(const SizedBox(height: 20));
      children.add(w);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<String> _splitBlocks(String data) {
    final lines = data.replaceAll('\r\n', '\n').split('\n');
    final blocks = <String>[];
    final buffer = <String>[];

    void flush() {
      if (buffer.isNotEmpty) {
        blocks.add(buffer.join('\n'));
        buffer.clear();
      }
    }

    for (final line in lines) {
      if (line.trim().isEmpty) {
        flush();
      } else {
        buffer.add(line);
      }
    }
    flush();
    return blocks;
  }

  Widget? _buildBlock(String block) {
    final trimmed = block.trimLeft();

    final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
    if (heading != null && !block.contains('\n')) {
      final level = heading.group(1)!.length;
      final text = heading.group(2)!.trim();
      final size = switch (level) {
        1 => widget.baseFontSize + 6,
        2 => widget.baseFontSize + 3,
        _ => widget.baseFontSize + 1,
      };
      return Text.rich(
        _inlineSpan(
          text,
          TextStyle(
            fontSize: size * widget.scale,
            fontWeight: FontWeight.w700,
            color: widget.headingColor,
            height: 1.35,
            fontFamilyFallback: SimpleMarkdown.cjkFallback,
          ),
        ),
      );
    }

    final lines = block.split('\n');

    if (lines.every((l) => l.trimLeft().startsWith('>'))) {
      final text = lines
          .map((l) => l.replaceFirst(RegExp(r'^\s*>\s?'), ''))
          .join('\n');
      return SelectableText.rich(
        _inlineSpan(
          text,
          TextStyle(
            fontSize: (widget.baseFontSize - 4) * widget.scale,
            color: widget.textColor,
            height: 1.5,
            fontFamilyFallback: SimpleMarkdown.cjkFallback,
          ),
        ),
      );
    }

    final isList = lines.every((l) => RegExp(r'^\s*([-*•])\s+').hasMatch(l));
    if (isList) {
      final baseStyle = TextStyle(
        fontSize: widget.baseFontSize * widget.scale,
        color: widget.textColor,
        height: 1.8,
        fontFamilyFallback: SimpleMarkdown.cjkFallback,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: Text('•', style: baseStyle),
                  ),
                  Expanded(
                    child: Text.rich(
                      _inlineSpan(
                        l.replaceFirst(RegExp(r'^\s*([-*•])\s+'), ''),
                        baseStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    final hasHardBreak = block.contains('\n');
    return SelectableText.rich(
      _inlineSpan(
        block,
        TextStyle(
          fontSize: widget.baseFontSize * widget.scale,
          color: widget.textColor,
          height: 1.85,
          fontFamilyFallback: SimpleMarkdown.cjkFallback,
        ),
      ),
      textAlign: (!hasHardBreak && widget.justify)
          ? TextAlign.justify
          : TextAlign.start,
    );
  }

  TextSpan _inlineSpan(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|\[([^\]]+)\]\(([^)]+)\)');
    var index = 0;

    for (final m in pattern.allMatches(text)) {
      if (m.start > index) {
        spans.add(TextSpan(text: text.substring(index, m.start), style: base));
      }
      if (m.group(1) != null) {
        spans.add(
          TextSpan(
            text: m.group(1),
            style: base.copyWith(
              fontWeight: FontWeight.w700,
              color: widget.accentColor ?? base.color,
            ),
          ),
        );
      } else if (m.group(2) != null) {
        spans.add(
          TextSpan(
            text: m.group(2),
            style: base.copyWith(
              color: Brand.yamabuki,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      } else {
        final label = m.group(3)!;
        final url = m.group(4)!;
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onLinkTap?.call(url);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: label,
            style: base.copyWith(
              color: widget.linkColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: widget.onLinkTap == null ? null : recognizer,
          ),
        );
      }
      index = m.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index), style: base));
    }
    return TextSpan(children: spans);
  }
}
