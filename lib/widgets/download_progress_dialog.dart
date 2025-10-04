// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amitabha/download_model.dart';

class DownloadProgressDialog extends StatelessWidget {
  const DownloadProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Please wait patiently'),
      content: Consumer<DownloadModel>(
        builder: (context, m, child) {
          final downloading = m.progress > 0.0 && m.progress < 1.0;
          final unzipping = m.unzipProgress > 0.0 && m.unzipProgress < 1.0;
          final done = m.progress >= 1.0 && m.unzipProgress >= 1.0;
          final idle = !downloading && !unzipping && !done;

          final showingValue = downloading
              ? m.progress
              : (unzipping ? m.unzipProgress : 0.0);

          final label = downloading
              ? 'downloading'
              : (unzipping ? 'unzipping' : (done ? 'completed' : 'preparing'));

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: idle ? null : showingValue),
              const SizedBox(height: 16),
              Text(
                idle
                    ? 'Please wait while preparing...'
                    : 'Please do not perform any operations during $label',
              ),
              const SizedBox(height: 8),
              if (!idle) Text('${(showingValue * 100).toStringAsFixed(2)}%'),
            ],
          );
        },
      ),
      actions: <Widget>[
        Consumer<DownloadModel>(
          builder: (context, m, child) {
            final downloading = m.progress > 0.0 && m.progress < 1.0;
            final unzipping = m.unzipProgress > 0.0 && m.unzipProgress < 1.0;
            final busy = downloading || unzipping;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!busy)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  )
                else ...[
                  TextButton(
                    onPressed: null,
                    child: Text(downloading ? 'Downloading' : 'Unzipping'),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
