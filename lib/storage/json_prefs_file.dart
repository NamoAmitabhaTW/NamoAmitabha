// lib/storage/json_prefs_file.dart
// settings/ 下單一 JSON 設定檔的共用讀寫:
// 統一 theme/locale/background prefs 原本各自複製的樣板,
// 並一律走原子寫入(舊實作直接覆寫,寫到一半中斷會損毀設定檔)。
import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_paths.dart';
import 'atomic_io.dart';

class JsonPrefsFile {
  JsonPrefsFile(this.name);

  /// 檔名(不含副檔名),實際位置為 `settings/<name>.json`。
  final String name;

  Future<File> file() async {
    final root = await AppPaths.root();
    final f = File(p.join(root.path, 'settings', '$name.json'));
    await f.parent.create(recursive: true);
    return f;
  }

  /// 讀取;檔案不存在、空白或損毀一律回 null(呼叫端用預設值)。
  Future<Map<String, dynamic>?> read() async {
    final f = await file();
    if (!await f.exists()) return null;
    final j = await readJsonOrEmpty(f);
    return j.isEmpty ? null : j;
  }

  /// 原子寫入(先寫暫存檔再 rename)。
  Future<void> write(Map<String, dynamic> json) async {
    final f = await file();
    await atomicWriteJson(f, json);
  }
}
