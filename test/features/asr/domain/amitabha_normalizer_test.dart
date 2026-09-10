// test/features/asr/domain/amitabha_normalizer_test.dart
//
// 守住佛號辨識的容錯比對。
// 語音辨識輸出不會每次一致，正規化要吸收合理差異又不能寬鬆到誤判。

import 'package:amitabha/features/asr/domain/amitabha_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 涵蓋繁簡、同音字、全形空白與一句多聲四種情況。
  group('Amitabha detection', () {
    test('baseline hits: 阿彌陀佛 / 阿弥陀佛', () {
      expect(countAmitabhaOccurrences('阿彌陀佛'), 1);
      expect(countAmitabhaOccurrences('阿弥陀佛'), 1);
    });

    test('tolerant hits: 阿米陀佛 / 阿咪陀佛', () {
      expect(countAmitabhaOccurrences('阿米陀佛'), 1);
      expect(countAmitabhaOccurrences('阿咪陀佛'), 1);
    });

    test('ignore spaces/punctuations (含全形空白)', () {
      expect(countAmitabhaOccurrences('阿　彌 陀　佛'), 1);
      expect(countAmitabhaOccurrences('阿彌，陀佛。'), 1);
      expect(countAmitabhaOccurrences('阿彌陀佛!!'), 1);
    });

    test('multiple occurrences in a single string', () {
      expect(countAmitabhaOccurrences('阿彌陀佛阿彌陀佛'), 2);
      expect(countAmitabhaOccurrences('阿弥陀佛…阿米陀佛…阿咪陀佛'), 3);
    });

    test('no match', () {
      expect(countAmitabhaOccurrences('南無觀世音菩薩'), 0);
      expect(containsAmitabha('南無觀世音菩薩'), false);
    });

    test('normalization mapping sanity', () {
      final n = normalizeForAmitabha('阿驮佛/阿彌陀仏');
      expect(n.contains('陀'), true);
      expect(n.contains('弥'), true);
      expect(n.contains('佛'), true);
    });
  });
}
