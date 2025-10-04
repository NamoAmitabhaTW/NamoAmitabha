import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;


const customKeywords = <String>[
  'ā m í t uó f ó :2.5 #0.04 @阿彌陀佛',
  'ā m ī t uó f ó :2.3 #0.05 @阿彌陀佛',
  'ā m í t uó f o :2.3 #0.04 @阿彌陀佛',  
  'ā m ī t uó f o :2.1 #0.06 @阿彌陀佛', 
  'ē m í t uó f ó :2.3 #0.05 @阿彌陀佛',
  'ē m ī t uó f ó :2.3 #0.05 @阿彌陀佛',
  'ē m í t uó f o :2.1 #0.06 @阿彌陀佛',
  'ē m ī t uó f o :2.1 #0.06 @阿彌陀佛',
];


Future<String> writeCustomKeywords(String modelRoot) async {
  final file = File(path.join(modelRoot, 'keywords_custom.txt'));
  await file.writeAsString(customKeywords.join('\n') + '\n', encoding: utf8);
  return file.path;
}
