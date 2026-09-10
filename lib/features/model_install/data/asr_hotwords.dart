// lib/features/model_install/data/asr_hotwords.dart
import 'dart:io';
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String> materializeHotwordsFile() async {
  final txt = await rootBundle.loadString(AppAssets.asrHotwords);
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/hotwords.txt';
  await File(path).writeAsString(txt);
  return path;
}
