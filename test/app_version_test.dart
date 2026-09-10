import 'package:amitabha/features/app_update/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('解析完整的三段版本號', () {
      final v = AppVersion.tryParse('2.1.3')!;
      expect(v.major, 2);
      expect(v.minor, 1);
      expect(v.patch, 3);
    });

    test('缺少的位數補 0', () {
      expect(AppVersion.tryParse('2.1'), const AppVersion(2, 1, 0));
      expect(AppVersion.tryParse('2'), const AppVersion(2, 0, 0));
    });

    test('忽略 build number 與預發布後綴', () {
      expect(AppVersion.tryParse('2.0.0+16'), const AppVersion(2, 0, 0));
      expect(AppVersion.tryParse('2.0.0-beta'), const AppVersion(2, 0, 0));
    });

    test('去除前後空白', () {
      expect(AppVersion.tryParse('  2.0.0  '), const AppVersion(2, 0, 0));
    });

    test('格式不合回傳 null', () {
      for (final bad in ['', '  ', 'abc', '2.x.0', '1.2.3.4', '-1.0.0']) {
        expect(AppVersion.tryParse(bad), isNull, reason: bad);
      }
      expect(AppVersion.tryParse(null), isNull);
    });
  });

  group('比較', () {
    test('數值比較，不是字串比較', () {
      expect(const AppVersion(2, 10, 0) > const AppVersion(2, 9, 0), isTrue);
      expect(const AppVersion(2, 0, 10) > const AppVersion(2, 0, 9), isTrue);
    });

    test('major 優先於 minor，minor 優先於 patch', () {
      expect(const AppVersion(3, 0, 0) > const AppVersion(2, 99, 99), isTrue);
      expect(const AppVersion(2, 1, 0) > const AppVersion(2, 0, 99), isTrue);
    });

    test('相同版本不算有新版', () {
      expect(const AppVersion(2, 0, 0) <= const AppVersion(2, 0, 0), isTrue);
      expect(const AppVersion(2, 0, 0) > const AppVersion(2, 0, 0), isFalse);
    });

    test('相等與 hashCode 一致', () {
      expect(const AppVersion(2, 0, 0), const AppVersion(2, 0, 0));
      expect(
        const AppVersion(2, 0, 0).hashCode,
        const AppVersion(2, 0, 0).hashCode,
      );
    });

    test('toString 可還原成原字串', () {
      expect(AppVersion.tryParse('2.1.3').toString(), '2.1.3');
    });
  });
}
