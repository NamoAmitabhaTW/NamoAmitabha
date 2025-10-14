//amitabha/lib/amitabha_normalizer.dart
String normalizeForAmitabha(String s) {
  final noSpace = s.replaceAll(RegExp(r'\s+'), '');
  final noPunct = noSpace.replaceAll(
    RegExp(r'[，。、「」‘’“”!.?？,~\-—…·\[\]\(\)【】<>《》:：;；、]'),
    '',
  );

  final sb = StringBuffer();
  for (final ch in noPunct.runes) {
    if (ch == 0x3000) {
      continue;
    } else if (ch >= 0xFF01 && ch <= 0xFF5E) {
      sb.writeCharCode(ch - 0xFEE0);
    } else {
      sb.write(String.fromCharCode(ch));
    }
  }
  var t = sb.toString();

  t = t
      .replaceAll('彌', '弥') 
      .replaceAll('仏', '佛') 
      .replaceAll('驮', '陀'); 

  return t;
}

final RegExp _amituofoTolerant = RegExp(r'阿[弥米咪]陀佛');

int countAmitabhaOccurrences(String text) {
  final norm = normalizeForAmitabha(text);
  return _amituofoTolerant.allMatches(norm).length;
}

bool containsAmitabha(String text) => countAmitabhaOccurrences(text) > 0;