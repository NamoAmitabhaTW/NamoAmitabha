// test/helpers/asr_controller.dart
import 'package:amitabha/features/asr/asr.dart';

AsrSessionController fileBackedAsrController({
  SpeechSegmentSource Function()? sourceFactory,
  SessionRepository? sessionRepo,
  DailyRepository? dailyRepo,
  PendingCommitStore? pendingStore,
  Future<void> Function(bool keepAwake)? setWakelock,
  Duration? draftEvery,
}) => AsrSessionController(
  sessionRepo: sessionRepo ?? const FileSessionRepository(),
  dailyRepo: dailyRepo ?? const FileDailyRepository(),
  pendingStore: pendingStore ?? const FilePendingCommitStore(),
  setWakelock: setWakelock ?? (_) async {},
  sourceFactory: sourceFactory,
  draftEvery: draftEvery ?? const Duration(seconds: 30),
);
