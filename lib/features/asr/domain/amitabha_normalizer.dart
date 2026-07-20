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

// 阿彌陀佛的四音節容錯字元類。因為目前的模型是「中英模型」,聽到外語念佛時
// 會用中文近音字去近似輸出,所以這裡列的是「實際會被辨識出的常見字」,不是讀音本身:
//   _c1 第一音「阿」:台灣有 ㄚ/ㄜ/ㄛ 等讀法 → 阿啊(ㄚ)、喔哦噢欧(ㄛ/ㄡ)、额俄(ㄜ)、奥。
//   _c2 第二音「彌」:弥米密…;越南語「A Di Đà」的「Di」被辨識成「西(si)」,故也收「西」。
//   _c3 第三音「陀」:陀托塔…(「托」是「欧米托佛」漏判的主因,補上)。
//   _c4 第四音「佛」:佛…。
const String _c1 = '阿啊喔欧奥哦噢额俄';
const String _c2 = '密妹秘弥米咪西';
const String _c3 = '陀斗度的岛朵都投捣德道达托塔妥打哒咑踏豆特哆多';
const String _c4 = '佛会吧巴否';

// 命中樣式(單一正則、依序嘗試;allMatches 非重疊,四音節優先於三音節,不會重複計數):
//   1) 中/日文近似的「阿弥陀佛」四音節。
//   2) 只念到三音節「阿弥陀」(未接「佛」)也算一次。
//   3) 羅馬拼音字幹「a/o - m/s + i - t/d - a/o/u」:涵蓋日語 Amida/Amita、
//      梵文 Amitabha、韓文 Amita(bul)、越南語 Asida、英文/台語念法 Amituofo/Omitofo 等。
// caseSensitive: false 只影響拉丁字母;對中日文無作用。
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