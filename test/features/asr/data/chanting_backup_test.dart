// test/features/asr/data/chanting_backup_test.dart

import 'dart:io';

import 'package:amitabha/features/asr/asr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('namo_backup_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('排除目標是 sessions 目錄本身，不是個別檔案', () async {
    final target = await chantingBackupExclusionTarget();

    // 旗標必須下在目錄上：atomicWriteJson 的 tmp + rename 會產生新的 inode，
    // 檔案層級的 xattr 不會跟著走，旗標會默默失效。
    expect(target, isA<Directory>());
    expect(target.path.split(Platform.pathSeparator).last, 'sessions');
  });

  test('目錄不存在時會先建立，旗標才有對象可下', () async {
    final target = await chantingBackupExclusionTarget();
    expect(await target.exists(), isTrue);
  });

  test('重複呼叫不拋錯，且指向同一個目錄', () async {
    final first = await chantingBackupExclusionTarget();
    final second = await chantingBackupExclusionTarget();
    expect(second.path, first.path);

    // 每次啟動都要重設一次，所以完整流程必須能重複執行。
    await excludeChantingDataFromBackup();
    await excludeChantingDataFromBackup();
  });
}
