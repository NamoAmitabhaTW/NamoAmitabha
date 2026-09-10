// test/helpers/asr_controller.dart
import 'package:amitabha/features/asr/asr.dart';

AsrSessionController fileBackedAsrController({
  SpeechSegmentSource Function()? sourceFactory,
  SessionRepository? sessionRepo,
  DailyRepository? dailyRepo,
  PendingCommitStore? pendingStore,
  HitLogFactory? hitLogFactory,
  Future<void> Function(bool keepAwake)? setWakelock,
}) => AsrSessionController(
  sessionRepo: sessionRepo ?? const FileSessionRepository(),
  dailyRepo: dailyRepo ?? const FileDailyRepository(),
  pendingStore: pendingStore ?? const FilePendingCommitStore(),
  hitLogFactory: hitLogFactory ?? FileHitLog.new,
  setWakelock: setWakelock ?? (_) async {},
  sourceFactory: sourceFactory,
);
