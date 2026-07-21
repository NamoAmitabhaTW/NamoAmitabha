// amitabha/lib/features/background/background_item.dart
import 'dart:io';

enum BackgroundType { video, image }


enum BackgroundUiState {
  activeBuiltin, 
  idleBuiltin, 
  activeDownloaded, 
  idleDownloaded, 
  downloading, 
  notDownloaded, 
}

class BackgroundItem {
  final String id;
  final String name; 
  final String? nameEn;

  final Map<String, String> names;

  final BackgroundType type;

  final String thumbnail;

  final String fileUrl;

  final int fileSize;

  final int version;

  final bool isBuiltin;

  final String? assetPath;

  bool isDownloaded;
  bool isDownloading;
  double downloadProgress; 
  bool needsUpdate; 

  BackgroundItem({
    required this.id,
    required this.name,
    required this.type,
    required this.thumbnail,
    this.nameEn,
    this.names = const {},
    this.fileUrl = '',
    this.fileSize = 0,
    this.version = 1,
    this.isBuiltin = false,
    this.assetPath,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0,
    this.needsUpdate = false,
  });

  factory BackgroundItem.fromJson(Map<String, dynamic> json) {

    final names = <String, String>{};
    for (final entry in json.entries) {
      final k = entry.key;
      if (k.length > 4 &&
          k.startsWith('name') &&
          k != 'nameEn' &&
          entry.value is String) {
        final code = k.substring(4).toLowerCase(); 
        names[code] = entry.value as String;
      }
    }

    return BackgroundItem(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String?,
      names: names,
      type: (json['type'] as String) == 'image'
          ? BackgroundType.image
          : BackgroundType.video,
      thumbnail: json['thumbnailUrl'] as String,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
    );
  }

  String get ext => type == BackgroundType.image ? 'jpg' : 'mp4';

  BackgroundUiState uiState(bool isActive) {
    if (isDownloading) return BackgroundUiState.downloading;
    if (isBuiltin) {
      return isActive
          ? BackgroundUiState.activeBuiltin
          : BackgroundUiState.idleBuiltin;
    }
    if (!isDownloaded) return BackgroundUiState.notDownloaded;
    return isActive
        ? BackgroundUiState.activeDownloaded
        : BackgroundUiState.idleDownloaded;
  }

  String displayName(String languageCode) {
    final lang = languageCode.toLowerCase();

    final explicit = names[lang];
    if (explicit != null && explicit.isNotEmpty) return explicit;

    switch (lang) {
      case 'zh':
        return name;
      case 'ja':
      case 'ko':
      case 'vi':
        return name; 
      case 'de':
      case 'fr':
        return nameEn ?? name; 
      case 'en':
        return nameEn ?? _prettifyId(id);
      default:
        return nameEn ?? name;
    }
  }

  static String _prettifyId(String id) => id
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  static List<BackgroundItem> builtinDefaults() => [
        BackgroundItem(
          id: 'mountain_stream',
          name: '清流明澈',
          nameEn: 'Clear Stream',
          names: const {
            'ja': '清流明澈',
            'ko': '맑은 물줄기',
            'vi': 'Dòng suối trong',
            'de': 'Klarer Strom',
            'fr': 'Courant limpide',
          },
          type: BackgroundType.video,
          thumbnail: 'assets/images/bg_mountain_stream.png',
          isBuiltin: true,
          assetPath: 'assets/videos/bg_mountain_stream.mp4',
        ),
      ];
}

class BackgroundSource {
  final BackgroundType type;
  final String? assetPath; 
  final File? file; 
  final int revision; 
  BackgroundSource({
    required this.type,
    this.assetPath,
    this.file,
    this.revision = 1,
  });
}
