//amitabha/lib/app/application/app_state.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DailyRecord {
  final DateTime date;
  final int count;
  DailyRecord({required this.date, required this.count});
}

class AppState extends ChangeNotifier {
  bool isRecording = false;
  int sessionCount = 0;
  DateTime? lastHitAt;
  int dataVersion = 0;

  final List<DailyRecord> _records = [];
  List<DailyRecord> get records => List.unmodifiable(_records);

  int get totalCount =>
      _records.fold<int>(0, (sum, r) => sum + r.count) + sessionCount;


  int get practiceDays {
    final set = <DateTime>{};
    for (final r in _records) {
      set.add(DateUtils.dateOnly(r.date));
    }
    return set.length;
  }

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