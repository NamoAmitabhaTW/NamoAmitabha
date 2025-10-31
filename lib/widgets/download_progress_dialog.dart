// lib/widgets/download_progress_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amitabha/download_model.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';

class DownloadProgressDialog extends StatelessWidget {
  const DownloadProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.pleaseWait),
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
              ? t.downloading
              : (unzipping ? t.unzipping : (done ? t.completed : t.preparing));

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: idle ? null : showingValue),
              const SizedBox(height: 16),
              Text(idle ? t.preparingPleaseWait : t.doNotOperateDuring(label)),
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
                  SizedBox(
                    // 給寬度，讓命中區更好按（可依需要調整 160~240）
                    width: 200,
                    height: 60,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        // 關鍵：設定最小命中區（高度 60）
                        minimumSize: const Size(200, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(t.ok),
                    )
                  )
                else ...[
                  TextButton(
                    onPressed: null,
                    child: Text(downloading ? t.downloading : t.unzipping),
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
