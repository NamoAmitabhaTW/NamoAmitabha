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

const String _c1 = '阿啊喔欧奥哦噢额俄';
const String _c2 = '密妹秘弥米咪西';
const String _c3 = '陀斗度的岛朵都投捣德道达托塔妥打哒咑踏豆特哆多';
const String _c4 = '佛会吧巴否';
final RegExp _amituofoTolerant = RegExp(
  '[$_c1][$_c2][$_c3][$_c4]'
  '|[$_c1][$_c2][$_c3]'
  r'|omit'
  r'|[ao][msc]i[td][aou]',
  caseSensitive: false,
);

int countAmitabhaOccurrences(String text) {
  final norm = normalizeForAmitabha(text);
  return _amituofoTolerant.allMatches(norm).length;
}

bool containsAmitabha(String text) => countAmitabhaOccurrences(text) > 0;