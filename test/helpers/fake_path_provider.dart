// test/helpers/fake_path_provider.dart
// 測試用 path_provider:所有系統目錄都導向同一個暫存根目錄下的子資料夾。
//
// 對應 App 實際用到的 API:
//  - AppPaths.root / ModelPaths.root / 各 prefs → getApplicationSupportPath
//  - AppPaths.background(背景素材快取)        → getApplicationCachePath
//  - ModelPaths.archiveFile / hotwords 暫存    → getTemporaryPath
//  - (保留 documents 以防未來用到)
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.root);

  /// 測試的暫存根目錄(由測試的 setUp 建立、tearDown 刪除)。
  final Directory root;

  String _sub(String name) {
    final dir = Directory(p.join(root.path, name));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async => _sub('support');

  @override
  Future<String?> getApplicationDocumentsPath() async => _sub('documents');

  @override
  Future<String?> getApplicationCachePath() async => _sub('cache');

  @override
  Future<String?> getTemporaryPath() async => _sub('tmp');
}