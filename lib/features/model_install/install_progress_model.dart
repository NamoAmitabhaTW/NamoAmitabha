// lib/features/model_install/install_progress_model.dart
// 安裝進度的 UI 狀態(原 DownloadModel 瘦身改名):
// 只負責進度數值、狀態文字與取消旗標,模型選擇已移至呼叫端/ModelInstaller。
//
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'package:flutter/foundation.dart';

class InstallProgressModel with ChangeNotifier {
  double _progress = 0;
  double get progress => _progress;
  void setProgress(double value) {
    _progress = value >= 1.0 ? 1 : value;
    notifyListeners();
  }

  double _unzipProgress = 0;
  double get unzipProgress => _unzipProgress;
  void setUnzipProgress(double value) {
    _unzipProgress = value >= 1.0 ? 1 : value;
    notifyListeners();
  }

  /// 下載或解壓進行中(用來擋重複進入安裝流程)。
  bool get isBusy =>
      (_progress > 0 && _progress < 1) ||
      (_unzipProgress > 0 && _unzipProgress < 1);

  // ── 狀態提示文字(例如「因空間不足重新嘗試解壓縮中」)──
  String? _statusNote;
  String? get statusNote => _statusNote;
  void setStatusNote(String? note) {
    _statusNote = note;
    notifyListeners();
  }

  // ── 使用者取消旗標 ──
  bool _cancelRequested = false;
  bool get cancelRequested => _cancelRequested;
  void requestCancel() {
    _cancelRequested = true;
    notifyListeners();
  }

  void clearCancel() {
    _cancelRequested = false;
    // 不 notify:僅內部旗標重置,無畫面變化需求
  }

  void reset({bool notify = false}) {
    _progress = 0.0;
    _unzipProgress = 0.0;
    _statusNote = null;
    _cancelRequested = false;
    if (notify) notifyListeners();
  }
}
