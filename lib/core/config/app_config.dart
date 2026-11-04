abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.aroundtown.fun/api',
  );

  static const String googleSignInServerClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
  );

  static const String googleSignInIosClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_IOS_CLIENT_ID',
  );
}
