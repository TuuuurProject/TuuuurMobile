/// Interface pour fournir le token d'authentification à ApiClient.
/// Permet de préparer l'intégration future du refresh token.
abstract class TokenProvider {
  /// Retourne le token d'accès actuel, ou null si non connecté.
  String? get accessToken;

  /// Retourne la date d'expiration du token, ou null si inconnue.
  DateTime? get accessTokenExpiresAt;

  /// Méthode appelée par ApiClient avant une requête authentifiée.
  /// Permet de vérifier si le token est expiré et de le rafraîchir si nécessaire.
  /// 
  /// Pour l'instant, cette méthode ne fait rien (placeholder).
  /// L'implémentation du refresh token sera ajoutée ultérieurement.
  Future<void> refreshIfNeeded();
}
