// lib/core/widgets/app_bottom_sheet.dart

import 'package:flutter/material.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 640,
  double maxHeightFactor = 0.85,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      maxWidth: maxWidth,
    ),
    builder: (sheetContext) => SafeArea(
      child: Scrollbar(child: builder(sheetContext)),
    ),
  );
}
