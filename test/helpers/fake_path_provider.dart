import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.root);

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
