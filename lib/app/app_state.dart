// lib/app/app_state.dart
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool isRecording = false;
  int sessionCount = 0;
  DateTime? lastHitAt;
  int dataVersion = 0;

  // ==== 提供給 ASR（或其他邏輯層）呼叫的 API ====

  /// 錄音狀態（開始/暫停/停止）
  void setRecording(bool recording) {
    if (isRecording == recording) return;
    isRecording = recording;
    notifyListeners();
  }

  /// ASR 命中即時更新（UI 立即反映）
  void setAsrTempProgress({required int count, DateTime? last}) {
    sessionCount = count;
    lastHitAt = last;
    notifyListeners();
  }

  /// 本輪提交完成（資料已寫入 repo，由邏輯層處理），這裡只負責把 UI 歸零
  void onSessionCommitted() {
    sessionCount = 0;
    lastHitAt = null;
    isRecording = false; // 提交後視情況同步為非錄音
    dataVersion++;
    notifyListeners();
  }

  VoidCallback? startAsr;
  VoidCallback? stopAsr;
  VoidCallback? saveAsr;

  void bindAsrHandlers({
    VoidCallback? onStart,
    VoidCallback? onStop,
    VoidCallback? onSave,
  }) {
    startAsr = onStart;
    stopAsr = onStop;
    saveAsr = onSave;
  }
}
