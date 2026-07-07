// lib/features/model_install/download_model.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'package:flutter/cupertino.dart';

class DownloadModel with ChangeNotifier {
  String _modelName =
      "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20";
  String get modelName => _modelName;

  /// sherpa-onnx release 的下載頻道(本 App 只用 ASR 模型)。
  String get channel => 'asr-models';

  void useAsr([String? name]) {
    _modelName =
        name ?? 'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20';
    notifyListeners();
  }

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

  // ── 狀態提示文字（例如「因空間不足重新嘗試解壓縮中」）──
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
    // 不 notify：僅內部旗標重置，無畫面變化需求
  }

  void reset({bool notify = false}) {
    _progress = 0.0;
    _unzipProgress = 0.0;
    _statusNote = null;
    _cancelRequested = false;
    if (notify) notifyListeners();
  }
}