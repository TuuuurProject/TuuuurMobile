import 'package:http/http.dart' as http;

import '../stores/auth_store.dart';
import 'api_client.dart' as api_client_file;
import 'auth_api_service.dart' as auth_api_file;
import 'difficulty_api_service.dart' as difficulty_api_file;
import 'history_api_service.dart' as history_api_file;
import 'solo_api_service.dart' as solo_api_file;
import 'theme_api_service.dart' as theme_api_file;
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

  _AuthStoreTokenProvider(this._authStore);

  @override
  String? get accessToken => _authStore.token?.token;

  @override
  DateTime? get accessTokenExpiresAt => _authStore.token?.validTo;

  @override
  Future<void> refreshIfNeeded() async {
    // TODO: implémenter la logique de refresh token
    // Pour l'instant, cette méthode ne fait rien (placeholder).
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
    _tokenProvider = _AuthStoreTokenProvider(authStore);
    _apiClient = ApiClient(
      httpClient: _httpClient,
      tokenProvider: _tokenProvider,
    );

    _authApi = AuthApi(_apiClient);
    _soloApi = SoloApi(_apiClient);
    _themeApi = ThemeApi(_apiClient);
    _difficultyApi = DifficultyApi(_apiClient);
    _historyApi = HistoryApi(_apiClient);

    // Initialise les instances globales pour compatibilité
    api_client_file.apiClient = _apiClient;
    auth_api_file.authApi = _authApi;
    solo_api_file.soloApi = _soloApi;
    theme_api_file.themeApi = _themeApi;
    difficulty_api_file.difficultyApi = _difficultyApi;
    history_api_file.historyApi = _historyApi;

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
