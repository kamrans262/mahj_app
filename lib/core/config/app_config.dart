abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://palegreen-crane-342913.hostingersite.com/api',
  );
}
