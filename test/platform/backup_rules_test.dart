// test/platform/backup_rules_test.dart
//
// Android 的備份範圍由 manifest 屬性加 res/xml 規則檔決定，沒辦法在 Flutter
// 測試裡真的跑起來——但「規則存在且內容正確」本身值得守住。這幾個檔案很容易
// 在重新產生 manifest 或調整 flavor 時默默消失，而失效是無聲的：備份照常失敗，
// 不會有任何錯誤訊息，直到使用者換手機才發現記錄不見了。
//
// 寫法比照 architecture/dependency_rule_test.dart：讀專案檔案來斷言約定。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  final rulesApi31 = File(
    'android/app/src/main/res/xml/data_extraction_rules.xml',
  );
  final rulesApi30 = File('android/app/src/main/res/xml/backup_rules.xml');

  test('AndroidManifest 宣告了三個備份屬性', () {
    final xml = manifest.readAsStringSync();

    expect(xml, contains('android:allowBackup="true"'));
    expect(
      xml,
      contains('android:fullBackupContent="@xml/backup_rules"'),
      reason: 'API 30 以下要靠這個屬性指向 backup_rules.xml',
    );
    expect(
      xml,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      reason: 'API 31 以上要靠這個屬性指向 data_extraction_rules.xml',
    );
  });

  test('兩份規則檔都存在，且都排除了 161 MB 的模型目錄', () {
    for (final f in <File>[rulesApi31, rulesApi30]) {
      expect(
        f.existsSync(),
        isTrue,
        reason: '${f.path} 不存在；manifest 已指名它，建置會直接失敗',
      );
      expect(
        f.readAsStringSync(),
        contains('path="amitabha/models"'),
        reason: '${f.path} 漏掉模型目錄 → 該 API 區間仍會超過 25 MB 上限',
      );
    }
  });

  test('兩份規則檔都排除了 app_flutter', () {
    // Flutter debug 版把 Dart kernel 與 snapshot（約 80 MB）放在 app_flutter/，
    // 漏掉這條的話，備份會在那 80 MB 就超過 25 MB 上限——排除規則寫得再對也
    // 驗證不了，因為根本輪不到 files/ 底下的東西。
    for (final f in <File>[rulesApi31, rulesApi30]) {
      expect(
        f.readAsStringSync(),
        contains('domain="root" path="app_flutter"'),
        reason: '${f.path} 漏掉 app_flutter → debug 版的備份必定超標',
      );
    }
  });

  test('API 31 規則含 cloud-backup 與 device-transfer 兩段', () {
    final xml = rulesApi31.readAsStringSync();

    expect(xml, contains('<cloud-backup>'));
    expect(
      xml,
      contains('<device-transfer>'),
      reason: '缺這段的話換機直傳會沿用預設，把 161 MB 模型一起傳過去',
    );
  });
}
