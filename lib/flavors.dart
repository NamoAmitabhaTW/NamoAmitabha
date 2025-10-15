enum Flavor {
  dev,
  staging,
  prod,
}

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.dev:
        return '念佛 Dev';
      case Flavor.staging:
        return '念佛 Staging';
      case Flavor.prod:
        return '念佛';
    }
  }

}
