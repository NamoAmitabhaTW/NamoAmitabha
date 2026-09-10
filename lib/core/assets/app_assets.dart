// lib/core/assets/app_assets.dart
enum ChantButtonArt { start, pause, save }

enum SettingsTitleArt {
  language,
  background,
  announcements,
  dedication,
  rate,
  share,
}

class AppAssets {
  const AppAssets._();

  static const String appIcon = 'assets/branding/app_icon.png';

  static const Set<String> _calligraphyLocales = {'ja', 'ko', 'vi'};
  static const Set<String> _calligraphySanskritLocales = {'en', 'de', 'fr'};

  static String calligraphy(String languageCode) {
    if (_calligraphyLocales.contains(languageCode)) {
      return 'assets/branding/calligraphy/$languageCode.png';
    }
    if (_calligraphySanskritLocales.contains(languageCode)) {
      return 'assets/branding/calligraphy/sa.png';
    }
    return 'assets/branding/calligraphy/zh.png';
  }

  static const String bodhiLeafPhone =
      'assets/backgrounds/bodhi_leaf/phone.png';
  static const String bodhiLeafTabletPortrait =
      'assets/backgrounds/bodhi_leaf/tablet_portrait.png';
  static const String bodhiLeafTabletLandscape =
      'assets/backgrounds/bodhi_leaf/tablet_landscape.png';

  static const String bodhiLeafBleed =
      'assets/backgrounds/bodhi_leaf/bleed.png';

  static const String mountainStreamThumbnail =
      'assets/backgrounds/mountain_stream/thumbnail.png';
  static const String mountainStreamVideo =
      'assets/backgrounds/mountain_stream/video.mp4';

  static const Set<String> chantButtonLocales = {
    'zh',
    'ja',
    'ko',
    'vi',
    'en',
    'de',
    'fr',
  };

  static String? chantButton(String languageCode, ChantButtonArt art) =>
      chantButtonLocales.contains(languageCode)
      ? 'assets/ui/chant_buttons/$languageCode/${art.name}.png'
      : null;

  static const Set<String> settingsTitleLocales = {
    'zh',
    'en',
    'ja',
    'ko',
    'vi',
    'de',
    'fr',
  };

  static String? settingsTitle(String languageCode, SettingsTitleArt art) =>
      settingsTitleLocales.contains(languageCode)
      ? 'assets/ui/settings_titles/$languageCode/${art.name}.png'
      : null;

  static const String lotusDivider = 'assets/ui/decorations/lotus_divider.png';

  static const String lotusFlower = 'assets/ui/decorations/lotus_flower.webp';

  static const String announcementManifest =
      'assets/content/announcements/manifest.json';

  static String announcementBody(String id, String languageCode) =>
      'assets/content/announcements/$id/$languageCode.md';

  static const String asrModelDir = 'assets/ml/asr';

  static const String asrHotwords = 'assets/ml/asr/hotwords.txt';
}
