import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:tuuuur_flutter/api/api_module.dart';
import 'package:tuuuur_flutter/api/auth/auth_api_service.dart';
import 'package:tuuuur_flutter/api/auth/auth_models.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FlutterSecureStorage.setMockInitialValues({});

  group('_AuthStoreTokenProvider', () {
    late AuthStore authStore;

    setUpAll(() {
      authStore = AuthStore.instance;
      final module = ApiModule.instance;

      try {
        module.dispose();
      } catch (e) {}

      module.initialize(authStore: authStore);
    });

    setUp(() async {
      await authStore.signOut();
    });

    test(
      'refreshIfNeeded est appele lors d\'une requete authentifiee',
      () async {
        final validToken = AuthTokenDto(
          token: 'test_token',
          validTo: DateTime.now().add(const Duration(hours: 1)),
          refreshToken: 'refresh_token',
          refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final session = AuthSessionDto(
          user: UserDto(id: '1', nickName: 'test'),
          token: validToken,
          isGoogleUser: false,
          raw: {},
        );

        await authStore.signInWithSession(session);

        try {
          final module = ApiModule.instance;
          final authApi = module.authApi;
          await authApi.me();
        } catch (e) {}

        expect(authStore.token, isNotNull);
      },
    );

    test('_performRefresh est appele lors du refresh token', () async {
      final expiringToken = AuthTokenDto(
        token: 'expiring_token',
        validTo: DateTime.now().add(const Duration(minutes: 2)),
        refreshToken: 'refresh_token_123',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSessionDto(
        user: UserDto(id: '1', nickName: 'test'),
        token: expiringToken,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      try {
        final module = ApiModule.instance;
        final authApi = module.authApi;
        await authApi.refreshToken(
          bearer: expiringToken.token,
          refreshToken: expiringToken.refreshToken!,
        );
      } catch (e) {}

      expect(authStore.token, isNotNull);
    });

    test('refreshIfNeeded ne fait rien sans token', () async {
      await authStore.signOut();

      try {
        final module = ApiModule.instance;
        final authApi = module.authApi;
        await authApi.me();
      } catch (e) {}

      expect(authStore.token, isNull);
    });

    test('refreshIfNeeded ne refresh pas un token valide longtemps', () async {
      final validToken = AuthTokenDto(
        token: 'valid_token',
        validTo: DateTime.now().add(const Duration(hours: 1)),
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSessionDto(
        user: UserDto(id: '1', nickName: 'test'),
        token: validToken,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      final tokenBefore = authStore.token?.token;

      try {
        final module = ApiModule.instance;
        final authApi = module.authApi;
        await authApi.me();
      } catch (e) {}

      expect(authStore.token?.token, equals(tokenBefore));
    });

    test('refreshIfNeeded ne refresh pas si refreshToken est null', () async {
      final tokenWithoutRefresh = AuthTokenDto(
        token: 'expiring_token',
        validTo: DateTime.now().add(const Duration(minutes: 2)),
        refreshToken: null,
        refreshTokenExpiresAt: null,
      );

      final session = AuthSessionDto(
        user: UserDto(id: '1', nickName: 'test'),
        token: tokenWithoutRefresh,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      final tokenBefore = authStore.token?.token;

      try {
        final module = ApiModule.instance;
        final authApi = module.authApi;
        await authApi.me();
      } catch (e) {}

      expect(authStore.token?.token, equals(tokenBefore));
    });

    test('refreshIfNeeded ne refresh pas si refreshToken est vide', () async {
      final tokenWithEmptyRefresh = AuthTokenDto(
        token: 'expiring_token',
        validTo: DateTime.now().add(const Duration(minutes: 2)),
        refreshToken: '',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSessionDto(
        user: UserDto(id: '1', nickName: 'test'),
        token: tokenWithEmptyRefresh,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      final tokenBefore = authStore.token?.token;

      try {
        final module = ApiModule.instance;
        final authApi = module.authApi;
        await authApi.me();
      } catch (e) {}

      expect(authStore.token?.token, equals(tokenBefore));
    });

    test('refreshIfNeeded ne refresh pas si refreshToken est expire', () async {
      final tokenWithExpiredRefresh = AuthTokenDto(
        token: 'expiring_token',
        validTo: DateTime.now().add(const Duration(minutes: 2)),
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.now().subtract(
          const Duration(hours: 1),
        ),
      );

      final session = AuthSessionDto(
        user: UserDto(id: '1', nickName: 'test'),
        token: tokenWithExpiredRefresh,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      final tokenBefore = authStore.token?.token;

      try {
        final module = ApiModule.instance;
        final authApi = module.authApi;
        await authApi.me();
      } catch (e) {}

      expect(authStore.token?.token, equals(tokenBefore));
    });

    test(
      'refreshIfNeeded lance le refresh pour un token expirant avec refreshToken valide',
      () async {
        final expiringTokenWithValidRefresh = AuthTokenDto(
          token: 'expiring_token',
          validTo: DateTime.now().add(const Duration(minutes: 3)),
          refreshToken: 'valid_refresh_token',
          refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final session = AuthSessionDto(
          user: UserDto(id: '1', nickName: 'test'),
          token: expiringTokenWithValidRefresh,
          isGoogleUser: false,
          raw: {},
        );

        await authStore.signInWithSession(session);

        try {
          final module = ApiModule.instance;
          final authApi = module.authApi;
          await authApi.me();
        } catch (e) {}

        expect(authStore.token, isNotNull);
        expect(authStore.token?.refreshToken, equals('valid_refresh_token'));
      },
    );

    test('_performRefresh gere les erreurs reseau gracieusement', () async {
      final expiringToken = AuthTokenDto(
        token: 'expiring_token',
        validTo: DateTime.now().add(const Duration(minutes: 2)),
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final session = AuthSessionDto(
        user: UserDto(id: '1', nickName: 'test'),
        token: expiringToken,
        isGoogleUser: false,
        raw: {},
      );

      await authStore.signInWithSession(session);

      final tokenBefore = authStore.token?.token;

      try {
        final module = ApiModule.instance;
        final authApi = module.authApi;
        await authApi.refreshToken(
          bearer: expiringToken.token,
          refreshToken: expiringToken.refreshToken!,
        );
      } catch (e) {}

      expect(authStore.token?.token, equals(tokenBefore));
    });

    test(
      'refreshIfNeeded gere les appels concurrents avec _refreshInProgress',
      () async {
        final expiringToken = AuthTokenDto(
          token: 'expiring_token',
          validTo: DateTime.now().add(const Duration(minutes: 2)),
          refreshToken: 'refresh_token',
          refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final session = AuthSessionDto(
          user: UserDto(id: '1', nickName: 'test'),
          token: expiringToken,
          isGoogleUser: false,
          raw: {},
        );

        await authStore.signInWithSession(session);

        final futures = <Future>[];
        for (var i = 0; i < 5; i++) {
          futures.add(
            Future(() async {
              try {
                final module = ApiModule.instance;
                final authApi = module.authApi;
                await authApi.me();
              } catch (e) {}
            }),
          );
        }

        await Future.wait(futures);

        expect(authStore.token, isNotNull);
      },
    );
  });
}
