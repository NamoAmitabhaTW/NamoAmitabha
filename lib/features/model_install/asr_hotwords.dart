//amitabha/lib/ars_hotwords.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String> materializeHotwordsFile() async {
  final txt = await rootBundle.loadString('assets/hotwords.txt');
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/hotwords.txt';
  await File(path).writeAsString(txt);
  return path;
}