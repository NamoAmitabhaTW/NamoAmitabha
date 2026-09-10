// lib/features/asr/domain/speech_segment_source.dart
abstract class SpeechSegmentSource {
  Future<bool> hasPermission();

  Future<void> start({required void Function(String text) onSegment});

  Future<void> stop();

  Future<void> dispose();
}
