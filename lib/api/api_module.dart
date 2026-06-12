import 'package:http/http.dart' as http;

import '../stores/auth_store.dart';
import '../stores/group_coordinator.dart';
import '../stores/ranked_coordinator.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'auth/auth_api_service.dart';
import 'other/difficulty_api_service.dart';
import 'group/group_api_service.dart';
import 'group/group_rest_api_service.dart';
import 'other/history_api_service.dart';
import 'ranked/ranked_rest_api_service.dart';
import 'solo/solo_api_service.dart';
import 'other/theme_api_service.dart';
import 'auth/token_provider.dart';

/// TokenProvider implementation using AuthStore.
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
      await _refreshInProgress;
      return;
    }

    final token = _authStore.token;
    if (token == null) {
      return;
    }

    final now = DateTime.now();
    final expiresAt = token.validTo;

    if (expiresAt == null) {
      return;
    }

    final shouldRefresh = now.isAfter(
      expiresAt.subtract(const Duration(minutes: 5)),
    );

    if (!shouldRefresh) return;

    final refreshToken = token.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

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
      final authApi = _authApiGetter();
      final res = await authApi.refreshToken(
        bearer: bearer,
        refreshToken: refreshToken,
      );

      if (res.ok && res.data != null) {
        await _authStore.signInWithSession(res.data!);
      }
    } catch (e) {
      // On error, do nothing to avoid blocking requests
    }
  }
}

/// Central module for API instances. Shares a single http.Client and ApiClient.
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
  late final GroupApi _groupApi;
  late final GroupRestApiService _groupRestApi;
  late final GroupCoordinator _groupCoordinator;
  late final RankedRestApiService _rankedApi;
  RankedCoordinator? _rankedCoordinator;

  bool _initialized = false;

  /// Initializes the module with AuthStore. Must be called once at app startup.
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
    _groupApi = GroupApi(_apiClient);
    _groupRestApi = GroupRestApiService(apiClient: _apiClient);
    _groupCoordinator = GroupCoordinator.create(
      apiClient: _apiClient,
      tokenProvider: _tokenProvider,
      webSocketHubUrl: ApiConfig.groupWebSocketUrl,
    );
    _rankedApi = RankedRestApiService(apiClient: _apiClient);

    _initialized = true;
  }

  Future<void> killRanked() async {
    final old = _rankedCoordinator;
    _rankedCoordinator =
        null; // très important : on coupe la réutilisation tout de suite

    if (old != null) {
      await old.hardDispose();
    }
  }

  Future<RankedCoordinator> restartRanked() async {
    await killRanked();
    final fresh = RankedCoordinator.create(
      tokenProvider: _tokenProvider,
      webSocketHubUrl: ApiConfig.rankedWebSocketUrl,
    );
    _rankedCoordinator = fresh;
    return fresh;
  }

  AuthApi get authApi {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _authApi;
  }

  SoloApi get soloApi {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _soloApi;
  }

  ThemeApi get themeApi {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _themeApi;
  }

  DifficultyApi get difficultyApi {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _difficultyApi;
  }

  HistoryApi get historyApi {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _historyApi;
  }

  GroupApi get groupApi {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _groupApi;
  }

  GroupRestApiService get groupRestApi {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _groupRestApi;
  }

  GroupCoordinator get groupCoordinator {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _groupCoordinator;
  }

  RankedRestApiService get rankedApi {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _rankedApi;
  }

  RankedCoordinator get rankedCoordinator {
    assert(
      _initialized,
      'ApiModule.initialize() must be called before using the API',
    );
    return _rankedCoordinator ??= RankedCoordinator.create(
      tokenProvider: _tokenProvider,
      webSocketHubUrl: ApiConfig.rankedWebSocketUrl,
    );
  }

  /// Disposes resources.
  void dispose() {
    if (_initialized) {
      _apiClient.dispose();
      _initialized = false;
    }
  }
}
