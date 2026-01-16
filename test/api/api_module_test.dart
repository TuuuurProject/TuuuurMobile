import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth_api_service.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/api/token_provider.dart';

// Fake AuthApi pour tracer les appels
class FakeAuthApi extends AuthApi {
  int refreshCallCount = 0;
  String? lastBearerToken;
  String? lastRefreshToken;
  ApiResponse<AuthSession>? refreshResponse;

  FakeAuthApi(super.apiClient);

  @override
  Future<ApiResponse<AuthSession>> refreshToken({
    required String bearer,
    required String refreshToken,
  }) async {
    refreshCallCount++;
    lastBearerToken = bearer;
    lastRefreshToken = refreshToken;
    return refreshResponse ??
        ApiResponse.err(message: 'No response configured');
  }
}

// Classe de test qui expose TokenProvider
class TestTokenProvider implements TokenProvider {
  final AuthStore _authStore;
  final AuthApi Function() _authApiGetter;
  
  // Future pour gérer les appels concurrents au refresh
  Future<void>? _refreshInProgress;

  TestTokenProvider(this._authStore, this._authApiGetter);

  @override
  String? get accessToken => _authStore.token?.token;

  @override
  DateTime? get accessTokenExpiresAt => _authStore.token?.validTo;

  @override
  Future<void> refreshIfNeeded() async {
    // Si un refresh est déjà en cours, attendre qu'il se termine
    if (_refreshInProgress != null) {
      await _refreshInProgress;
      return;
    }

    final token = _authStore.token;
    if (token == null) return;

    final now = DateTime.now();
    final expiresAt = token.validTo;

    if (expiresAt == null) return;

    final shouldRefresh =
        now.isAfter(expiresAt.subtract(const Duration(minutes: 5)));

    if (!shouldRefresh) return;

    final refreshToken = token.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return;

    final refreshExpiresAt = token.refreshTokenExpiresAt;
    if (refreshExpiresAt != null && now.isAfter(refreshExpiresAt)) {
      return;
    }

    // Lancer le refresh et stocker le Future
    _refreshInProgress = _performRefresh(token.token, refreshToken);
    
    try {
      await _refreshInProgress;
    } finally {
      _refreshInProgress = null;
    }
  }

  Future<void> _performRefresh(String bearer, String refreshToken) async {
    try {
      final authApi = _authApiGetter();
      final res = await authApi.refreshToken(
        bearer: bearer,
        refreshToken: refreshToken,
      );

      if (res.ok && res.data != null) {
        await _authStore.signInWithSession(res.data!);
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock du secure storage
  FlutterSecureStorage.setMockInitialValues({});

  group('TokenProvider refreshIfNeeded', () {
    late AuthStore authStore;
    late FakeAuthApi fakeAuthApi;

    setUp(() async {
      authStore = AuthStore.instance;
      // Nettoyer le store avant chaque test
      await authStore.signOut();
      fakeAuthApi = FakeAuthApi(ApiClient());
    });

    test('ne refresh pas si le token n\'expire pas bientôt', () async {
      // Token valide pour plus de 5 minutes
      final validToken = AuthToken(
        token: 'valid_token',
        validTo: DateTime.now().add(const Duration(minutes: 10)),
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: validToken,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      final tokenProvider = TestTokenProvider(authStore, () => fakeAuthApi);

      await tokenProvider.refreshIfNeeded();

      // Vérifier que l'API n'a pas été appelée
      expect(fakeAuthApi.refreshCallCount, 0);
    });

    test('refresh le token s\'il expire dans moins de 5 minutes', () async {
      // Token expirant dans 3 minutes
      final expiringToken = AuthToken(
        token: 'expiring_token',
        validTo: DateTime.now().add(const Duration(minutes: 3)),
        refreshToken: 'refresh_token_123',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: expiringToken,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      // Préparer la réponse de refresh
      final newToken = AuthToken(
        token: 'new_token',
        validTo: DateTime.now().add(const Duration(hours: 1)),
        refreshToken: 'new_refresh_token',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final newSession = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: newToken,
        isGoogleUser: false,
        raw: {},
      );

      fakeAuthApi.refreshResponse = ApiResponse.ok(newSession);

      final tokenProvider = TestTokenProvider(authStore, () => fakeAuthApi);

      await tokenProvider.refreshIfNeeded();

      // Vérifier que l'API a été appelée avec les bons paramètres
      expect(fakeAuthApi.refreshCallCount, 1);
      expect(fakeAuthApi.lastBearerToken, 'expiring_token');
      expect(fakeAuthApi.lastRefreshToken, 'refresh_token_123');

      // Vérifier que le token a été mis à jour
      expect(authStore.token?.token, 'new_token');
    });

    test('refresh le token s\'il est déjà expiré', () async {
      // Token déjà expiré
      final expiredToken = AuthToken(
        token: 'expired_token',
        validTo: DateTime.now().subtract(const Duration(minutes: 10)),
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: expiredToken,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      // Préparer une réponse
      final newToken = AuthToken(
        token: 'new_token',
        validTo: DateTime.now().add(const Duration(hours: 1)),
        refreshToken: 'new_refresh',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      fakeAuthApi.refreshResponse = ApiResponse.ok(AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: newToken,
        isGoogleUser: false,
        raw: {},
      ));

      final tokenProvider = TestTokenProvider(authStore, () => fakeAuthApi);

      await tokenProvider.refreshIfNeeded();

      // Devrait appeler l'API car le token est expiré
      expect(fakeAuthApi.refreshCallCount, 1);
    });

    test('ne refresh pas si le refresh token est expiré', () async {
      // Token avec refresh token expiré
      final token = AuthToken(
        token: 'token',
        validTo: DateTime.now().add(const Duration(minutes: 2)),
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final session = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: token,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      final tokenProvider = TestTokenProvider(authStore, () => fakeAuthApi);

      await tokenProvider.refreshIfNeeded();

      // Ne devrait pas appeler l'API car le refresh token est expiré
      expect(fakeAuthApi.refreshCallCount, 0);
    });

    test('ne refresh pas si aucun refresh token n\'est disponible', () async {
      // Token sans refresh token
      final token = AuthToken(
        token: 'token',
        validTo: DateTime.now().add(const Duration(minutes: 2)),
      );

      final session = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: token,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      final tokenProvider = TestTokenProvider(authStore, () => fakeAuthApi);

      await tokenProvider.refreshIfNeeded();

      // Ne devrait pas appeler l'API
      expect(fakeAuthApi.refreshCallCount, 0);
    });

    test('ne refresh pas si aucun token n\'est présent', () async {
      // Déconnecter l'utilisateur
      await authStore.signOut();

      final tokenProvider = TestTokenProvider(authStore, () => fakeAuthApi);

      await tokenProvider.refreshIfNeeded();

      // Ne devrait pas appeler l'API
      expect(fakeAuthApi.refreshCallCount, 0);
    });

    test('gère les erreurs de refresh gracieusement', () async {
      // Token expirant
      final expiringToken = AuthToken(
        token: 'expiring_token',
        validTo: DateTime.now().add(const Duration(minutes: 3)),
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: expiringToken,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      // Simuler une erreur de refresh
      fakeAuthApi.refreshResponse = ApiResponse.err(
        message: 'Server error',
        statusCode: 500,
      );

      final tokenProvider = TestTokenProvider(authStore, () => fakeAuthApi);

      // Appeler refreshIfNeeded - ne devrait pas lancer d'exception
      await tokenProvider.refreshIfNeeded();

      // Vérifier que l'API a été appelée
      expect(fakeAuthApi.refreshCallCount, 1);

      // Le token original devrait toujours être présent (pas de changement)
      expect(authStore.token?.token, equals('expiring_token'));
    });

    test('ne refresh pas si le token n\'a pas de date d\'expiration', () async {
      // Token sans validTo
      final token = AuthToken(
        token: 'token_no_expiry',
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: token,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      final tokenProvider = TestTokenProvider(authStore, () => fakeAuthApi);

      await tokenProvider.refreshIfNeeded();

      // Ne devrait pas appeler l'API car pas de date d'expiration
      expect(fakeAuthApi.refreshCallCount, 0);
    });

    test('ne fait qu\'un seul refresh lors d\'appels concurrents', () async {
      // Token expirant
      final expiringToken = AuthToken(
        token: 'expiring_token',
        validTo: DateTime.now().add(const Duration(minutes: 3)),
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: expiringToken,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      // Préparer la réponse de refresh
      final newToken = AuthToken(
        token: 'new_token',
        validTo: DateTime.now().add(const Duration(hours: 1)),
        refreshToken: 'new_refresh_token',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final newSession = AuthSession(
        user: UserDto(id: 1, nickName: 'test'),
        token: newToken,
        isGoogleUser: false,
        raw: {},
      );

      fakeAuthApi.refreshResponse = ApiResponse.ok(newSession);

      final tokenProvider = TestTokenProvider(authStore, () => fakeAuthApi);

      // Lancer 3 appels concurrents
      final futures = [
        tokenProvider.refreshIfNeeded(),
        tokenProvider.refreshIfNeeded(),
        tokenProvider.refreshIfNeeded(),
      ];

      // Attendre que tous se terminent
      await Future.wait(futures);

      // Vérifier qu'il n'y a eu qu'un seul appel à l'API
      expect(fakeAuthApi.refreshCallCount, 1);

      // Vérifier que le token a été mis à jour
      expect(authStore.token?.token, 'new_token');
    });
  });
}
