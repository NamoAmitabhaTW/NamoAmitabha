// lib/storage/backup_exclusion.dart


import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('amitabha/ios_backup');

// 標記排除 iCloud/iTunes 備份。
Future<void> excludeFromICloudBackup(String path) async {
  if (!Platform.isIOS) return;
  try {
    await _channel.invokeMethod('excludeFromBackup', {'path': path});
  } catch (_) {
    
  }
}
