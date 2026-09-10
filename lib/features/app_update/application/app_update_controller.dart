// lib/features/app_update/application/app_update_controller.dart
import 'dart:io' show Platform;
import 'package:amitabha/core/config/store_links.dart';
import 'package:amitabha/features/app_update/domain/app_update_ports.dart';
import 'package:amitabha/features/app_update/domain/app_version.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateController {
  AppUpdateController(this._latestVersion, this._prefs);

  final LatestVersionSource _latestVersion;
  final AppUpdatePreferences _prefs;

  static const bool debugAlwaysShow = false;

  static const Duration dismissWindow = Duration(hours: 24);

  AppVersion? _current;

  AppVersion? _pendingLatest;

  Future<bool> check() async {
    if (debugAlwaysShow) return true;

    final String? rawLatest;
    try {
      rawLatest = await _latestVersion.fetchLatest();
    } catch (e) {
      debugPrint('版本資訊載入失敗: $e');
      return false;
    }

    final latest = AppVersion.tryParse(rawLatest);
    final current = await _currentVersion();
    if (latest == null || current == null) return false;
    if (latest <= current) return false;

    _pendingLatest = latest;

    final dismissed = await _prefs.load();
    final at = dismissed.at;
    if (dismissed.version == latest.toString() &&
        at != null &&
        DateTime.now().difference(at) < dismissWindow) {
      return false;
    }
    return true;
  }

  Future<void> dismiss() async {
    if (debugAlwaysShow) return;
    final latest = _pendingLatest;
    if (latest == null) return;
    await _prefs.saveDismissed(latest.toString());
  }

  Future<bool> openStore() async {
    final url = Platform.isIOS
        ? StoreLinks.iosStoreUrl
        : StoreLinks.androidStoreUrl;
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('開啟商店失敗: $e');
      return false;
    }
  }

  Future<AppVersion?> _currentVersion() async {
    final cached = _current;
    if (cached != null) return cached;
    try {
      final info = await PackageInfo.fromPlatform();
      return _current = AppVersion.tryParse(info.version);
    } catch (e) {
      debugPrint('取得目前版本失敗: $e');
      return null;
    }
  }
}
