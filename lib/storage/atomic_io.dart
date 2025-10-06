import 'dart:convert';
import 'dart:io';

Future<void> atomicWriteJson(File file, Object jsonObj) async {
  final dir = file.parent;
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final tmp = File('${file.path}.tmp');
  try {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonObj);
    await tmp.writeAsString(jsonStr, flush: true);

    await tmp.rename(file.path);
  } catch (e) {
 
    if (await tmp.exists()) {
      try { await tmp.delete(); } catch (_) {}
    }
    rethrow;
  }
}

Future<Map<String, dynamic>> readJsonOrEmpty(File file) async {
  if (!await file.exists()) return {};

  String text;
  try {
    text = await file.readAsString();
  } on IOException {
    return {};
  }

  if (text.isEmpty) return {};

  try {
    final obj = jsonDecode(text);
    if (obj is Map<String, dynamic>) return obj;
    return {};
  } on FormatException { 
    return {};
  }
}