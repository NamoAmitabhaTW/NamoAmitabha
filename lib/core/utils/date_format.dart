// lib/core/utils/date_format.dart
import 'package:intl/intl.dart';

/// 本地時區的 yyyyMMdd(daily 檔名 / 每日彙總 key 用)。
String nowYmdLocal() {
  return DateFormat('yyyyMMdd').format(DateTime.now());
}
