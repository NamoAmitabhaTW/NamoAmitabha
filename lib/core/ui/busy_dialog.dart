// lib/core/ui/busy_dialog.dart
import 'package:flutter/material.dart';

Future<void> showBusyDialog(BuildContext context, String title, String message) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    ),
  );
}