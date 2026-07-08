// lib/features/model_install/model_install_flow.dart
// 模型安裝的「UI 流程層」:整個 App 只有這個檔案可以為安裝流程開對話框。
//
// 職責:確認下載 → 進度對話框 → 呼叫 ModelInstaller → 失敗對話框與重試迴圈
// → 成功通知。每次 await 之後都檢查 context.mounted,不讓 BuildContext
// 跨越 async gap 失效。重試採用迴圈重算狀態(installer.status),
// 取代舊版的遞迴對話框:zip 還在就只解壓,zip 沒了就重新下載。

import 'dart:async';

import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'install_progress_model.dart';
import 'model_installer.dart';
import 'widgets/download_progress_dialog.dart';

/// 一次安裝流程的結果。
enum InstallFlowResult { installed, cancelled, failed }

class ModelInstallFlow {
  ModelInstallFlow({ModelInstaller? installer})
    : _installer = installer ?? ModelInstaller();

  final ModelInstaller _installer;

  /// 確保模型就緒。模型缺件時走「確認 → 下載 → 解壓 → 驗證」流程,
  /// 過程中的所有對話框與重試都在這裡處理。
  Future<InstallFlowResult> ensureReady(
    BuildContext context,
    String modelName,
  ) async {
    return _withWakelock(() => _run(context, modelName));
  }

  Future<InstallFlowResult> _run(BuildContext context, String modelName) async {
    final progress = context.read<InstallProgressModel>();

    // 空間不足重試解壓時,進度框要顯示提示文字(僅該次)
    bool retryUnzipAfterDiskFull = false;

    while (true) {
      final status = await _installer.status(modelName);
      if (status == InstallStatus.ready) return InstallFlowResult.installed;
      if (!context.mounted) return InstallFlowResult.failed;

      final needsDownload = status == InstallStatus.needsDownload ||
          status == InstallStatus.incompleteNeedsDownload;

      // ── 下載步驟(解壓前) ──
      if (needsDownload) {
        final confirmed = await _confirmDownload(context, modelName);
        if (!confirmed) return InstallFlowResult.cancelled;
        if (!context.mounted) return InstallFlowResult.failed;

        progress.clearCancel();
        _openProgressDialog(context);
        // 立刻給非零進度,跳過「準備中」畫面,避免一閃而過
        progress.setProgress(0.001);

        try {
          await _installer.download(
            modelName,
            onProgress: (p) =>
                progress.setProgress(p < 0.001 ? 0.001 : p), // 保持非零
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
          continue; // 重算狀態:zip 還在 → 只解壓;不在 → 重新下載
        }
        // 下載完成 → 同一個進度框內接著解壓
      } else {
        // ── 只需解壓(zip 已在本地) ──
        progress.clearCancel();
        if (retryUnzipAfterDiskFull && context.mounted) {
          progress.setStatusNote(AppLocalizations.of(context).retryUnzipNote);
        }
        if (!context.mounted) return InstallFlowResult.failed;
        _openProgressDialog(context);
      }
      retryUnzipAfterDiskFull = false;

      // ── 解壓步驟 ──
      progress.setUnzipProgress(0.001); // 跳過「準備中」畫面
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
        return InstallFlowResult.cancelled; // zip 保留,之後可只解壓
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

      // ── 成功收尾 ──
      if (context.mounted) {
        _closeProgressDialog(context);
        progress.reset();
        _showSuccessDialog(context); // 唯一的完成通知
      } else {
        progress.reset();
      }
      return InstallFlowResult.installed;
    }
  }

  // ── 進度對話框 ─────────────────────────────────────────────

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

  /// BZip2 + Tar 解碼階段無法取得真實進度,用假進度平滑撐到
  /// [_decodePhaseCap],避免銜接檔案寫入進度時「倒退」。
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

  // ── 對話框 ────────────────────────────────────────────────

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

  /// 依失敗原因顯示對應的錯誤對話框;回傳使用者是否選擇重試。
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
        // 空間不足:文案明確要求「先清出空間」,按鈕語意是「我已清好空間」
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

  // ── 其他 ─────────────────────────────────────────────────

  /// 安裝期間保持螢幕常亮;結束後恢復原狀。
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
