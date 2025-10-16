//amitabha/lib/download_model.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'package:flutter/cupertino.dart';

enum ModelKind { asr, kws }

class DownloadModel with ChangeNotifier {

  ModelKind _kind = ModelKind.asr;
  ModelKind get kind => _kind;

  String _modelName =
      "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20";
  String get modelName => _modelName;
  String get channel => _kind == ModelKind.kws ? 'kws-models' : 'asr-models';

  void useAsr([String? name]) {
    _kind = ModelKind.asr;
    _modelName = name ??
        'icefall-asr-zipformer-streaming-wenetspeech-20230615';
    notifyListeners();
  }

  void useKws([String? name]) {
    _kind = ModelKind.kws;
    _modelName = name ??
        'sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile';
    notifyListeners();
  }

  double _progress = 0;
  double get progress => _progress;
  void setProgress(double value) {
    if (value >= 1.0) {
      _progress = 1;
    } else {
      _progress = value;
    }
    notifyListeners();
  }

  double _unzipProgress = 0;
  double get unzipProgress => _unzipProgress;
  void setUnzipProgress(double value) {
    if (value >= 1.0) {
      _unzipProgress = 1;
    } else {
      _unzipProgress = value;
    }
    notifyListeners();
  }

  void reset() {
    _progress = 0.0;
    _unzipProgress = 0.0;
    notifyListeners();
  } 

}