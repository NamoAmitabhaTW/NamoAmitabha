// lib/core/utils/audio_convert.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation
import 'package:flutter/foundation.dart';

Float32List convertBytesToFloat32(
  Uint8List bytes, [
  Endian endian = Endian.little,
]) {
  final pairCount = bytes.length >> 1;
  if (pairCount == 0) return Float32List(0);

  final out = Float32List(pairCount);
  final data = ByteData.sublistView(bytes);

  for (int j = 0, i = 0; j < pairCount; j++, i += 2) {
    final s = data.getInt16(i, endian);
    out[j] = s / 32768.0;
  }
  return out;
}
