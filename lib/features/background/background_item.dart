// amitabha/lib/features/background/background_item.dart
import 'dart:io';

enum BackgroundType { video, image }

/// 驅動卡片要顯示哪些按鈕的「顯示狀態」,由 uiState() 從底層欄位推導。
enum BackgroundUiState {
  activeBuiltin, // 內建・使用中
  idleBuiltin, // 內建・未使用
  activeDownloaded, // 已下載・使用中
  idleDownloaded, // 已下載・未使用
  downloading, // 下載中
  notDownloaded, // 未下載
}

class BackgroundItem {
  final String id;
  final String name; // 中文原名(必填)
  final String? nameEn;

  /// 其餘語系名稱:key 為語系碼(ja/ko/de/fr…),value 為該語名稱。
  /// 來自 manifest 的 nameJa / nameKo… 欄位,缺漏時走 displayName 的 fallback。
  final Map<String, String> names;

  final BackgroundType type;

  /// 預覽縮圖:builtin 為 asset 路徑,遠端為 jsDelivr 網址。
  final String thumbnail;

  /// 大檔網址(影片/圖片本體);builtin 不需要,留空。
  final String fileUrl;

  /// 檔案大小(bytes),用於在下載鈕旁顯示;builtin 為 0。
  final int fileSize;

  /// 內容版本;manifest 端在替換素材時 +1,用來偵測已下載者需更新。builtin 固定 1。
  final int version;

  /// 是否為隨 App 打包的內建預設背景。
  final bool isBuiltin;

  /// builtin 專用:打包在 App 內的素材路徑(pubspec assets)。
  final String? assetPath;

  // ── 執行期狀態(非來自 JSON,啟動時比對本地檔案後填入)──
  bool isDownloaded;
  bool isDownloading;
  double downloadProgress; // 0.0 ~ 1.0
  bool needsUpdate; // 已下載,但 manifest 有更新版

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
    // 收集所有 nameXx 欄位(nameJa / nameKo / nameDe / nameFr / nameVi…)
    // 鍵正規化為小寫語系碼:nameJa -> 'ja'
    final names = <String, String>{};
    for (final entry in json.entries) {
      final k = entry.key;
      if (k.length > 4 &&
          k.startsWith('name') &&
          k != 'nameEn' &&
          entry.value is String) {
        final code = k.substring(4).toLowerCase(); // 'Ja' -> 'ja'
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

  /// 依語系取顯示名,fallback 規則:
  ///  - ja/ko/vi:有對應 nameXx 就用;沒有 → 退回中文原名(漢字/漢越圈,比英文貼近)。
  ///  - de/fr:有對應 nameXx 就用;沒有 → 退回 nameEn(依設計,德法用英文名即可)。
  ///  - en:nameEn ?? 由 id 推導。
  ///  - 其餘 / 找不到:nameEn ?? 中文原名。
  String displayName(String languageCode) {
    final lang = languageCode.toLowerCase();

    // 1) 該語系有明確翻譯,直接用
    final explicit = names[lang];
    if (explicit != null && explicit.isNotEmpty) return explicit;

    // 2) 依語系給 fallback
    switch (lang) {
      case 'zh':
        return name;
      case 'ja':
      case 'ko':
      case 'vi':
        return name; // 漢字/漢越圈:退中文原名(比英文貼近)
      case 'de':
      case 'fr':
        return nameEn ?? name; // 拉丁語系:退英文
      case 'en':
        return nameEn ?? _prettifyId(id);
      default:
        return nameEn ?? name;
    }
  }

  // cherry_blossom → Cherry Blossom(用空格,當標籤比 CherryBlossom 好讀)
  static String _prettifyId(String id) => id
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  /// 內建預設背景(隨 App 打包,用程式碼宣告)。
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

/// ChantingBackground 拿這個決定要播 asset 還是本地檔案。
class BackgroundSource {
  final BackgroundType type;
  final String? assetPath; // builtin
  final File? file; // 已下載
  final int revision; // 內容版本;更新後改變,讓播放端偵測到並重載
  BackgroundSource({
    required this.type,
    this.assetPath,
    this.file,
    this.revision = 1,
  });
}
