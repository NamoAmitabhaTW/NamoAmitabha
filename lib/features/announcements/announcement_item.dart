class AnnouncementItem {
  final String id;

  final int version;

  final String date;

  final bool pinned;

  final Map<String, String> titles;

  final List<String> langs;

  const AnnouncementItem({
    required this.id,
    required this.version,
    required this.date,
    required this.pinned,
    required this.titles,
    required this.langs,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    final titles = <String, String>{};
    if (rawTitle is Map) {
      for (final e in rawTitle.entries) {
        if (e.value is String) titles[e.key.toString().toLowerCase()] = e.value as String;
      }
    } else if (rawTitle is String) {
      titles['zh'] = rawTitle;
    }

    final rawLangs = json['langs'];
    final langs = <String>[];
    if (rawLangs is List) {
      for (final l in rawLangs) {
        if (l is String) langs.add(l.toLowerCase());
      }
    }

    return AnnouncementItem(
      id: json['id'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      date: json['date'] as String? ?? '',
      pinned: json['pinned'] as bool? ?? false,
      titles: titles,
      langs: langs,
    );
  }

  String displayTitle(String languageCode) {
    for (final code in _fallbackChain(languageCode)) {
      final t = titles[code];
      if (t != null && t.isNotEmpty) return t;
    }
    for (final t in titles.values) {
      if (t.isNotEmpty) return t;
    }
    return id;
  }

  String? resolveBodyLang(String languageCode) {
    for (final code in _fallbackChain(languageCode)) {
      if (langs.contains(code)) return code;
    }
    return langs.isNotEmpty ? langs.first : null;
  }

  static List<String> _fallbackChain(String languageCode) {
    final lang = languageCode.toLowerCase();
    final chain = <String>[lang];
    if (!chain.contains('en')) chain.add('en');
    if (!chain.contains('zh')) chain.add('zh');
    return chain;
  }
}
