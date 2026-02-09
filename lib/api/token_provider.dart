/// Interface pour fournir le token d'authentification à ApiClient.
/// Permet de préparer l'intégration future du refresh token.
abstract class TokenProvider {
  /// Retourne le token d'accès actuel, ou null si non connecté.
  String? get accessToken;

  /// Retourne la date d'expiration du token, ou null si inconnue.
  DateTime? get accessTokenExpiresAt;

  Future<void> refreshIfNeeded();
}
