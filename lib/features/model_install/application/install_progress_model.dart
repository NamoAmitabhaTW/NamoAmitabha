// lib/features/model_install/application/install_progress_model.dart

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

  bool get isBusy =>
      (_progress > 0 && _progress < 1) ||
      (_unzipProgress > 0 && _unzipProgress < 1);

  String? _statusNote;
  String? get statusNote => _statusNote;
  void setStatusNote(String? note) {
    _statusNote = note;
    notifyListeners();
  }

  bool _cancelRequested = false;
  bool get cancelRequested => _cancelRequested;
  void requestCancel() {
    _cancelRequested = true;
    notifyListeners();
  }

  void clearCancel() {
    _cancelRequested = false;
  }

  void reset({bool notify = false}) {
    _progress = 0.0;
    _unzipProgress = 0.0;
    _statusNote = null;
    _cancelRequested = false;
    if (notify) notifyListeners();
  }
}
