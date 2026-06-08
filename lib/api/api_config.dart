class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_BASE');

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static String get groupWebSocketUrl {
    if (baseUrl.isEmpty) {
      return 'https://localhost:5001/group';
    }
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/group';
  }

  static String get rankedWebSocketUrl {
    if (baseUrl.isEmpty) {
      return 'https://localhost:5001/ranked';
    }
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/ranked';
  }
}
