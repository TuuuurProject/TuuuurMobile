import 'package:http/http.dart' as http;

import '../stores/auth_store.dart';
import 'api_client.dart';
import 'auth_api_service.dart';
import 'difficulty_api_service.dart';
import 'history_api_service.dart';
import 'solo_api_service.dart';
import 'theme_api_service.dart';
import 'token_provider.dart';

/// Implémentation de TokenProvider qui utilise AuthStore.
class _AuthStoreTokenProvider implements TokenProvider {
  final AuthStore _authStore;
  final AuthApi Function() _authApiGetter;
  
  Future<void>? _refreshInProgress;

  _AuthStoreTokenProvider(this._authStore, this._authApiGetter);

  @override
  String? get accessToken => _authStore.token?.token;

  @override
  DateTime? get accessTokenExpiresAt => _authStore.token?.validTo;

  @override
  Future<void> refreshIfNeeded() async {
    if (_refreshInProgress != null) {
      print('[DEBUG] Refresh already in progress, waiting...');
      await _refreshInProgress;
      return;
    }

    final token = _authStore.token;
    if (token == null) return;

    final now = DateTime.now();
    final expiresAt = token.validTo;
    
    if (expiresAt == null) return;

    final shouldRefresh = now.isAfter(expiresAt.subtract(const Duration(minutes: 5)));
    
    if (!shouldRefresh) return;

    final refreshToken = token.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return;

    final refreshExpiresAt = token.refreshTokenExpiresAt;
    if (refreshExpiresAt != null && now.isAfter(refreshExpiresAt)) {
      return;
    }

    _refreshInProgress = _performRefresh(token.token, refreshToken);
    
    try {
      await _refreshInProgress;
    } finally {
      _refreshInProgress = null;
    }
  }

  Future<void> _performRefresh(String bearer, String refreshToken) async {
    try {
      print('[DEBUG] Refreshing token...');
      final authApi = _authApiGetter();
      final res = await authApi.refreshToken(
        bearer: bearer,
        refreshToken: refreshToken,
      );

      if (res.ok && res.data != null) {
        print('[DEBUG] Token refreshed successfully');
        await _authStore.signInWithSession(res.data!);
      } else {
        print('[DEBUG] Token refresh failed: ${res.message}');
      }
    } catch (e) {
      print('[DEBUG] Error refreshing token: $e');
      // En cas d'erreur, on ne fait rien pour éviter de bloquer les requêtes
    }
  }
}

/// Module central pour les instances API.
/// Crée et partage un seul http.Client et un seul ApiClient pour toutes les classes API.
class ApiModule {
  ApiModule._();

  static final ApiModule _instance = ApiModule._();
  static ApiModule get instance => _instance;

  late final http.Client _httpClient;
  late final TokenProvider _tokenProvider;
  late final ApiClient _apiClient;

  late final AuthApi _authApi;
  late final SoloApi _soloApi;
  late final ThemeApi _themeApi;
  late final DifficultyApi _difficultyApi;
  late final HistoryApi _historyApi;

  bool _initialized = false;

  /// Initialise le module avec l'AuthStore.
  /// Doit être appelé une fois au démarrage de l'application.
  void initialize({required AuthStore authStore}) {
    if (_initialized) return;

    _httpClient = http.Client();
    _tokenProvider = _AuthStoreTokenProvider(authStore, () => _authApi);
    _apiClient = ApiClient(
      httpClient: _httpClient,
      tokenProvider: _tokenProvider,
    );

    _authApi = AuthApi(_apiClient);
    _soloApi = SoloApi(_apiClient);
    _themeApi = ThemeApi(_apiClient);
    _difficultyApi = DifficultyApi(_apiClient);
    _historyApi = HistoryApi(_apiClient);

    _initialized = true;
  }

  /// Accès aux instances API.
  AuthApi get authApi {
    assert(_initialized, 'ApiModule.initialize() doit être appelé avant d\'utiliser les API');
    return _authApi;
  }

  SoloApi get soloApi {
    assert(_initialized, 'ApiModule.initialize() doit être appelé avant d\'utiliser les API');
    return _soloApi;
  }

  ThemeApi get themeApi {
    assert(_initialized, 'ApiModule.initialize() doit être appelé avant d\'utiliser les API');
    return _themeApi;
  }

  DifficultyApi get difficultyApi {
    assert(_initialized, 'ApiModule.initialize() doit être appelé avant d\'utiliser les API');
    return _difficultyApi;
  }

  HistoryApi get historyApi {
    assert(_initialized, 'ApiModule.initialize() doit être appelé avant d\'utiliser les API');
    return _historyApi;
  }

  /// Dispose des ressources (à appeler à la fermeture de l'app si nécessaire).
  void dispose() {
    if (_initialized) {
      _apiClient.dispose();
      _initialized = false;
    }
  }
}
