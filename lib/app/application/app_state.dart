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

  void hit() {
    sessionCount++;
    notifyListeners();
  }

  void toggleRecording() {
    isRecording = !isRecording;
    notifyListeners();
  }

  void saveSession() {
    if (sessionCount <= 0) return;
    _records.insert(0, DailyRecord(date: DateTime.now(), count: sessionCount));
    sessionCount = 0;
    notifyListeners();
  }
}