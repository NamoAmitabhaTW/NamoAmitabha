// lib/core/widgets/fitted_title.dart

import 'package:flutter/material.dart';

class FittedTitle extends StatelessWidget {
  const FittedTitle(this.text, {super.key, this.style, this.minFontSize = 14});

  final String text;

  final TextStyle? style;

  final double minFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective =
        (style ??
                theme.appBarTheme.titleTextStyle ??
                theme.textTheme.titleLarge ??
                const TextStyle(fontSize: 20))
            .merge(style);
    final baseSize = effective.fontSize ?? 20;

    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          return Text(text, maxLines: 1, style: effective);
        }

        final painter = TextPainter(
          text: TextSpan(text: text, style: effective),
          maxLines: 1,
          textScaler: scaler,
          textDirection: Directionality.of(context),
        )..layout();

        final factor = painter.width <= maxWidth
            ? 1.0
            : maxWidth / painter.width;
        final fitted = scaler.scale(baseSize) * factor;

        if (fitted >= minFontSize) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, softWrap: false, style: effective),
          );
        }

        return MediaQuery.withNoTextScaling(
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: effective.copyWith(fontSize: minFontSize),
          ),
        );
      },
    );
  }
}
