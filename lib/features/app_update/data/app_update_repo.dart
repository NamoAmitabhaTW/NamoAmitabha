// lib/features/app_update/data/app_update_repo.dart
import 'dart:convert';
import 'dart:io';
import 'package:amitabha/features/app_update/domain/app_update_ports.dart';
import 'package:http/http.dart' as http;

class HttpLatestVersionSource implements LatestVersionSource {
  const HttpLatestVersionSource();

  static const String url =
      'https://raw.githubusercontent.com/Aaron-Tsai-iosDeveloper/NamoAmitabha/main/app-release/version.json';

  @override
  Future<String?> fetchLatest() async {
    final key = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
        ? 'android'
        : null;
    if (key == null) return null;

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw HttpException('version HTTP ${res.statusCode}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (data is! Map) return null;
    final entry = data[key];
    if (entry is! Map) return null;
    final latest = entry['latest'];
    return latest is String ? latest : null;
  }
}
