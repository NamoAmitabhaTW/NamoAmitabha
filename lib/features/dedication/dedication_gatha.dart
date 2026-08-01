// 〈迴向偈〉各語系的預設內容。
// 使用者可於「設定 → 迴向偈」依當前語系分別編輯，會覆寫對應語系的預設值。

/// 繁體中文（八句）
const String kGathaZh =
    '願以此功德\n'
    '莊嚴佛淨土\n'
    '上報四重恩\n'
    '下濟三途苦\n'
    '若有見聞者\n'
    '悉發菩提心\n'
    '盡此一報身\n'
    '同生極樂國';

/// 日本語（四句）
const String kGathaJa =
    '願以此功徳\n'
    '平等施一切\n'
    '同発菩提心\n'
    '往生安楽国';

/// 한국어（六句）
const String kGathaKo =
    '원이차공덕\n'
    '보급어일체\n'
    '아등여중생\n'
    '당생극락국\n'
    '동견무량수\n'
    '개공성불도';

/// Tiếng Việt（八句）
const String kGathaVi =
    'Nguyện dĩ thử công đức\n'
    'Trang nghiêm Phật Tịnh độ\n'
    'Thượng báo tứ trọng ân\n'
    'Hạ tế tam đồ khổ\n'
    'Nhược hữu kiến văn giả\n'
    'Tất phát Bồ đề tâm\n'
    'Tận thử nhất báo thân\n'
    'Đồng sanh Cực Lạc quốc';

/// English / Deutsch / Français 共用英譯。
/// 兩段各為連續文句、隨畫面寬度自然換行，中間空行分段（參考設計稿）。
const String kGathaEn =
    "May the merits and virtues accrued from this work "
    "adorn the Buddha's pure land, "
    "repay the four kinds of kindness above, "
    "and relieve the sufferings of those in the three paths below.\n"
    "\n"
    "May all those who see and hear of this "
    "bring forth the bodhi mind "
    "and at the end of this life, "
    "be born together in the Land of Ultimate Bliss.";

/// 依語系代碼取得預設迴向偈。en / de / fr 共用英譯。
String defaultDedicationGatha(String languageCode) {
  switch (languageCode) {
    case 'zh':
      return kGathaZh;
    case 'ja':
      return kGathaJa;
    case 'ko':
      return kGathaKo;
    case 'vi':
      return kGathaVi;
    case 'en':
    case 'de':
    case 'fr':
    default:
      return kGathaEn;
  }
}
