import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;


const customKeywords = <String>[
  'ā m í t uó f ó :2.0 #0.2 @阿彌陀佛',
  'ā m ī t uó f ó :2.0 #0.2 @阿彌陀佛',
];


Future<String> writeCustomKeywords(String modelRoot) async {
  final file = File(path.join(modelRoot, 'keywords_custom.txt'));
  await file.writeAsString(customKeywords.join('\n') + '\n', encoding: utf8);
  return file.path;
}
