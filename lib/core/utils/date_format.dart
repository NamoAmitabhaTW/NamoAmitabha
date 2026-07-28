// lib/core/utils/date_format.dart
import 'package:intl/intl.dart';

String nowYmdLocal() {
  return DateFormat('yyyyMMdd').format(DateTime.now());
}
