class StoreLinks {
  StoreLinks._();

  static const String androidApplicationId = 'com.earth.amitabha';

  static const String iosAppStoreId = '6753948091';

  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidApplicationId';

  static const String iosStoreUrl =
      'https://apps.apple.com/app/id$iosAppStoreId';

  static const String metaStoreUrl =
      'https://www.meta.com/experiences/app/25113559184976267/';

  static bool get hasIosAppStoreId =>
      iosAppStoreId.isNotEmpty && iosAppStoreId != '0000000000';
}
