// lib/features/announcements/domain/announcement_ports.dart
import 'package:amitabha/features/announcements/domain/announcement_item.dart';

abstract class AnnouncementRepository {
  bool get localOnly;

  Future<List<AnnouncementItem>> loadLocalManifest();

  Future<List<AnnouncementItem>> fetchRemoteManifest();

  Future<String?> loadLocalBody(String id, String lang);

  Future<String?> fetchRemoteBody(String id, String lang);
}

abstract class AnnouncementPreferences {
  Future<Map<String, int>> loadRead();

  Future<void> saveRead(Map<String, int> versions);

  Future<Map<String, int>> loadBodyVersions();

  Future<void> saveBodyVersion(String id, int version);
}
