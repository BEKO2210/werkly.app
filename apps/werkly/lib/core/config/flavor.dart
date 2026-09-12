/// Build flavor for Werkly (dev / staging / prod).
enum Flavor {
  dev,
  staging,
  prod,
}

abstract final class FlavorConfig {
  static Flavor current = Flavor.dev;

  static String get label => current.name;

  static bool get isProd => current == Flavor.prod;

  static String get sentryEnvironment => current.name;
}
