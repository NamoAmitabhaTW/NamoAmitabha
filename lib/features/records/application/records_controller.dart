// lib/features/records/application/records_controller.dart
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/records/domain/chanting_statistics.dart';

class RecordsController {
  const RecordsController(this._dailyRepo);

  final DailyRepository _dailyRepo;

  Future<ChantingStatistics> load() async =>
      ChantingStatistics.from(await _dailyRepo.readAll());
}
