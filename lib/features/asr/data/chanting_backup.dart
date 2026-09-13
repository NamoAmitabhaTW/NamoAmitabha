// lib/features/asr/data/chanting_backup.dart

import 'dart:io';

import 'package:amitabha/core/infrastructure/backup_exclusion.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';

Future<Directory> chantingBackupExclusionTarget() async {
  final dir = await ChantingPaths.sessionsDir();
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

Future<void> excludeChantingDataFromBackup() async {
  final dir = await chantingBackupExclusionTarget();
  await excludeFromICloudBackup(dir.path);
}
