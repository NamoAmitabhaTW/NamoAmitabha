// TODO: add Amitabha hit-counter tests
// 目的：驗證阿彌陀佛的辨識是否正確
// 涵蓋：基準用例、口音變體、空白/標點去除、多次命中、無命中、正規化字形映射。
import 'package:flutter_test/flutter_test.dart';
import 'package:amitabha/amitabha_normalizer.dart';

void main() {
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
      expect(n.contains('陀'), true); // 驮→陀
      expect(n.contains('弥'), true); // 彌→弥
      expect(n.contains('佛'), true); // 仏→佛
    });
  });
}
