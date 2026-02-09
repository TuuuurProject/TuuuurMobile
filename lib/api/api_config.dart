class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
}
