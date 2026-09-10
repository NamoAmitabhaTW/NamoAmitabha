// lib/core/layout/layout_scale.dart
import 'package:flutter/widgets.dart';

const double kTabletBreakpoint = 600;

const double kFullScaleWidth = 820;

const double kDefaultMaxScale = 1.5;

double layoutScale(BuildContext context, {double maxScale = kDefaultMaxScale}) {
  final shortestSide = MediaQuery.sizeOf(context).shortestSide;
  if (shortestSide <= kTabletBreakpoint) return 1.0;

  final progress =
      ((shortestSide - kTabletBreakpoint) /
              (kFullScaleWidth - kTabletBreakpoint))
          .clamp(0.0, 1.0);
  return 1.0 + (maxScale - 1.0) * progress;
}
