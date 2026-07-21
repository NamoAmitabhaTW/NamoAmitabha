// lib/features/model_install/model_install_flow.dart

import 'dart:async';

import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'install_progress_model.dart';
import 'model_installer.dart';
import 'widgets/download_progress_dialog.dart';

enum InstallFlowResult { installed, cancelled, failed }

class ModelInstallFlow {
  ModelInstallFlow({ModelInstaller? installer})
    : _installer = installer ?? ModelInstaller();

  final ModelInstaller _installer;


  Future<InstallFlowResult> ensureReady(
    BuildContext context,
    String modelName,
  ) async {
    return _withWakelock(() => _run(context, modelName));
  }

  Future<InstallFlowResult> _run(BuildContext context, String modelName) async {
    final progress = context.read<InstallProgressModel>();

    bool retryUnzipAfterDiskFull = false;

    while (true) {
      final status = await _installer.status(modelName);
      if (status == InstallStatus.ready) return InstallFlowResult.installed;
      if (!context.mounted) return InstallFlowResult.failed;

      final needsDownload = status == InstallStatus.needsDownload ||
          status == InstallStatus.incompleteNeedsDownload;

      if (needsDownload) {
        final confirmed = await _confirmDownload(context, modelName);
        if (!confirmed) return InstallFlowResult.cancelled;
        if (!context.mounted) return InstallFlowResult.failed;

        progress.clearCancel();
        _openProgressDialog(context);
        progress.setProgress(0.001);

        try {
          await _installer.download(
            modelName,
            onProgress: (p) =>
                progress.setProgress(p < 0.001 ? 0.001 : p), 
            isCancelled: () => progress.cancelRequested,
          );
        } on UserCancelledException {
          if (context.mounted) _closeProgressDialog(context);
          progress.reset();
          return InstallFlowResult.cancelled; // 主動取消,不顯示失敗對話框
        } on InstallException catch (e) {
          if (context.mounted) _closeProgressDialog(context);
          progress.reset();
          if (!context.mounted) return InstallFlowResult.failed;
          final retry =
              await _showFailureDialog(context, e.reason, unzipPhase: false);
          if (!retry) return InstallFlowResult.failed;
          continue; 
        }

      } else {

        progress.clearCancel();
        if (retryUnzipAfterDiskFull && context.mounted) {
          progress.setStatusNote(AppLocalizations.of(context).retryUnzipNote);
        }
        if (!context.mounted) return InstallFlowResult.failed;
        _openProgressDialog(context);
      }
      retryUnzipAfterDiskFull = false;

      
      progress.setUnzipProgress(0.001); 
      final smoother = _startDecodeSmoothing(progress);
      try {
        await _installer.unzipAndVerify(
          modelName,
          onProgress: (ratio) {
            smoother.cancel();
            progress.setUnzipProgress(
              _decodePhaseCap + (1 - _decodePhaseCap) * ratio,
            );
          },
          isCancelled: () => progress.cancelRequested,
        );
      } on UserCancelledException {
        smoother.cancel();
        if (context.mounted) _closeProgressDialog(context);
        progress.reset();
        return InstallFlowResult.cancelled; 
      } on InstallException catch (e) {
        smoother.cancel();
        if (context.mounted) _closeProgressDialog(context);
        progress.reset();
        if (!context.mounted) return InstallFlowResult.failed;
        final retry =
            await _showFailureDialog(context, e.reason, unzipPhase: true);
        if (!retry) return InstallFlowResult.failed;
        retryUnzipAfterDiskFull = e.reason == InstallFailureReason.diskFull;
        continue;
      } finally {
        smoother.cancel();
      }


      if (context.mounted) {
        _closeProgressDialog(context);
        progress.reset();
        _showSuccessDialog(context); 
      } else {
        progress.reset();
      }
      return InstallFlowResult.installed;
    }
  }

  

  void _openProgressDialog(BuildContext context) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DownloadProgressDialog(),
    );
  }

  void _closeProgressDialog(BuildContext context) {
    if (!context.mounted) return;
    if (Navigator.canPop(context)) Navigator.of(context).pop();
  }


  static const _decodePhaseCap = 0.35;

  Timer _startDecodeSmoothing(InstallProgressModel progress) {
    progress.setUnzipProgress(0.01);
    late final Timer timer;
    timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      final cur = progress.unzipProgress;
      if (cur >= _decodePhaseCap) {
        timer.cancel();
        return;
      }
      progress.setUnzipProgress((cur + 0.01).clamp(0.0, _decodePhaseCap));
    });
    return timer;
  }

  

  Future<bool> _confirmDownload(BuildContext context, String modelName) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final t = AppLocalizations.of(dialogContext);
            return AlertDialog(
              title: Text(t.downloadRequiredTitle),
              content: Text(t.downloadRequiredBody(modelName)),
              actions: <Widget>[
                TextButton(
                  child: Text(t.cancel),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                TextButton(
                  child: Text(t.download),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }


  Future<bool> _showFailureDialog(
    BuildContext context,
    InstallFailureReason reason, {
    required bool unzipPhase,
  }) async {
    final t = AppLocalizations.of(context);

    final String title;
    final String message;
    final String retryLabel;

    switch (reason) {
      case InstallFailureReason.network:
        title = t.downloadFailedTitle;
        message = t.networkErrorBody;
        retryLabel = t.retry;
      case InstallFailureReason.timeout:
        title = t.downloadFailedTitle;
        message = t.timeoutErrorBody;
        retryLabel = t.retry;
      case InstallFailureReason.server:
        title = t.downloadFailedTitle;
        message = t.serverErrorBody;
        retryLabel = t.retry;
      case InstallFailureReason.diskFull:
        
        if (unzipPhase) {
          title = t.unzipFailedTitle;
          message = t.unzipFailedLowSpaceBody;
          retryLabel = t.retryUnzipAfterFreeSpace;
        } else {
          title = t.downloadFailedLowSpaceTitle;
          message = t.downloadFailedLowSpaceBody;
          retryLabel = t.retryAfterFreeSpace;
        }
      case InstallFailureReason.corruptedArchive:
      case InstallFailureReason.verificationFailed:
      case InstallFailureReason.unknown:
        title = t.downloadFailedTitle;
        message = t.downloadFailedShort;
        retryLabel = t.retry;
    }

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(t.close),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(retryLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final t = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(t.successTitle),
          content: Text(t.successBody),
          actions: <Widget>[
            TextButton(
              child: Text(t.ok),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<T> _withWakelock<T>(Future<T> Function() action) async {
    final wasEnabled = await WakelockPlus.enabled;
    try {
      if (!wasEnabled) {
        await WakelockPlus.enable();
      }
      return await action();
    } finally {
      if (!wasEnabled) {
        await WakelockPlus.disable();
      }
    }
  }
}
