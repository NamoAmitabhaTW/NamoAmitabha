// test/helpers/real_fonts.dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _fontAssets = <String, List<String>>{
  'NotoSerifTC': ['assets/fonts/NotoSerifTC-ExtraLight.ttf'],
  'NotoSerifGathaJP': ['assets/fonts/NotoSerifJP-Gatha.ttf'],
  'NotoSerifGathaKR': ['assets/fonts/NotoSerifKR-ExtraLight.ttf'],
  'LxgwWenkaiTC': ['assets/fonts/LXGWWenKaiTC-Regular.ttf'],
  'KleeOne': [
    'assets/fonts/KleeOne-Regular.ttf',
    'assets/fonts/KleeOne-SemiBold.ttf',
  ],
};

Future<void> loadAppFonts() async {
  for (final entry in _fontAssets.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final file = File(path);
      if (!file.existsSync()) {
        throw StateError('字型檔不存在：$path（pubspec 與這份清單不同步？）');
      }
      loader.addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }
}
