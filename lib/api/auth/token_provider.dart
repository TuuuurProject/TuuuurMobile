abstract class TokenProvider {
  String? get accessToken;

  DateTime? get accessTokenExpiresAt;

  Future<void> refreshIfNeeded();
}
