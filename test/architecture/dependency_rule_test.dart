// test/architecture/dependency_rule_test.dart
//
// 把「依賴只能往內」變成一個會失敗的測試。
// 掃描 lib/ 每一行 import 與 export，違反分層或跳過 barrel 就紅燈。

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

List<({String path, String source})> _libSources() {
  final dir = Directory('lib');
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map(
        (f) => (
          path: p.posix.joinAll(p.split(p.relative(f.path, from: 'lib'))),
          source: f.readAsStringSync(),
        ),
      )
      .where((e) => !e.path.startsWith('l10n/'))
      .toList();
}

final _importPattern = RegExp(
  r"^\s*(?:import|export)\s+'([^']+)'",
  multiLine: true,
);
final _featureImport = RegExp(r'^package:amitabha/features/([^/]+)/(.+)$');

void main() {
  test('依賴只能往內：core / domain / application / data / presentation', () {
    final violations = <String>[];

    for (final file in _libSources()) {
      final parts = file.path.split('/');
      final feature = parts.first == 'features' && parts.length > 1
          ? parts[1]
          : null;

      final layer = feature != null && parts.length > 3 ? parts[2] : null;

      for (final m in _importPattern.allMatches(file.source)) {
        final import = m.group(1)!;
        final target = _featureImport.firstMatch(import);

        if (file.path.startsWith('core/') && import.contains('/features/')) {
          violations.add('[core→feature] ${file.path} → $import');
        }

        if (feature == null) continue;

        if (layer == 'domain') {
          if (import.startsWith('package:flutter/material') ||
              import.startsWith('package:flutter/widgets')) {
            violations.add('[domain→Flutter UI] ${file.path} → $import');
          }
          if (target != null &&
              target.group(1) == feature &&
              RegExp(
                r'^(data|application|presentation)/',
              ).hasMatch(target.group(2)!)) {
            violations.add('[domain→外層] ${file.path} → $import');
          }
        }

        if (layer == 'application' &&
            target != null &&
            target.group(1) == feature &&
            RegExp(r'^(data|presentation)/').hasMatch(target.group(2)!)) {
          violations.add('[application→外層] ${file.path} → $import');
        }

        if (layer == 'data' &&
            target != null &&
            target.group(1) == feature &&
            target.group(2)!.startsWith('presentation/')) {
          violations.add('[data→presentation] ${file.path} → $import');
        }

        if (target != null &&
            target.group(1) != feature &&
            target.group(2) != '${target.group(1)}.dart') {
          violations.add('[跨 feature 未走 barrel] ${file.path} → $import');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          '違反依賴方向：\n${violations.join('\n')}\n\n'
          '修法：把要共用的東西移到內層，或讓外層透過 domain 的埠取用；'
          '跨 feature 一律 import features/<name>/<name>.dart。',
    );
  });

  test('素材路徑只准寫在 AppAssets 裡', () {
    final offenders = <String>[];

    for (final file in _libSources()) {
      if (file.path == 'core/assets/app_assets.dart') continue;
      if (RegExp(r"'assets/").hasMatch(file.source)) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '這些檔案直接寫了素材路徑字面值：\n${offenders.join('\n')}\n\n'
          '改用 AppAssets 的常數——素材改名時才會編譯失敗，'
          '而不是在使用者手機上變成一片空白。',
    );
  });
}
