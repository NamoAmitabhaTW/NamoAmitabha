// lib/features/model_install/widgets/download_progress_dialog.dart
import 'dart:async';
import 'package:amitabha/features/model_install/install_progress_model.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DownloadProgressDialog extends StatelessWidget {
  const DownloadProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.pleaseWait),
      content: Consumer<InstallProgressModel>(
        builder: (context, m, child) {
          final downloading = m.progress > 0.0 && m.progress < 1.0;
          final unzipping = m.unzipProgress > 0.0 && m.unzipProgress < 1.0;
          final active = m.progress > 0.0 || m.unzipProgress > 0.0;
          final idle = !active;

          final showingValue = downloading
              ? m.progress
              : (m.unzipProgress > 0.0 ? m.unzipProgress : 0.0);

          final label = downloading
              ? t.downloading
              : (active ? t.unzipping : t.preparing);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: idle ? null : showingValue),
              const SizedBox(height: 16),
              Text(idle ? t.preparingPleaseWait : t.doNotOperateDuring(label)),
              if (m.statusNote != null) ...[
                const SizedBox(height: 4),
                Text(
                  m.statusNote!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              if (downloading)
                Text('${(showingValue * 100).toStringAsFixed(2)}%'),
              if (unzipping) _AnimatedDotsText(text: t.unzipping),
            ],
          );
        },
      ),
      actions: <Widget>[
        Consumer<InstallProgressModel>(
          builder: (context, m, child) {
            final downloading = m.progress > 0.0 && m.progress < 1.0;
            final active = m.progress > 0.0 || m.unzipProgress > 0.0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!active)
                  SizedBox(
                    width: 200,
                    height: 60,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(200, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(t.ok),
                    ),
                  )
                else ...[
                  if (downloading)
                    TextButton(
                      onPressed: m.cancelRequested
                          ? null
                          : () => m.requestCancel(),
                      child: Text(m.cancelRequested ? t.cancelling : t.cancel),
                    ),
                  if (downloading) const SizedBox(width: 12),
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

class _AnimatedDotsText extends StatefulWidget {
  const _AnimatedDotsText({required this.text});

  final String text;

  @override
  State<_AnimatedDotsText> createState() => _AnimatedDotsTextState();
}

class _AnimatedDotsTextState extends State<_AnimatedDotsText> {
  static const _maxDots = 5;
  Timer? _timer;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      setState(() {
        _dotCount = _dotCount >= _maxDots ? 1 : _dotCount + 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.text),
        SizedBox(width: _maxDots * 6.0, child: Text('.' * _dotCount)),
      ],
    );
  }
}
