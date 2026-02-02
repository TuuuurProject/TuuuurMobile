import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth/auth_api_service.dart';

import 'auth_api_service_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('UserDto', () {
    test('fromJson crée une instance complète', () {
      final json = {
        'id': 123,
        'nickName': 'testUser',
        'email': 'test@example.com',
        'avatar': 'avatar.png',
        'isAdmin': true,
        'isNew': false,
      };

      final user = UserDto.fromJson(json);

      expect(user.id, equals(123));
      expect(user.nickName, equals('testUser'));
      expect(user.email, equals('test@example.com'));
      expect(user.avatar, equals('avatar.png'));
      expect(user.isAdmin, isTrue);
      expect(user.isNew, isFalse);
    });

    test('fromJson gère les valeurs nulles', () {
      final user = UserDto.fromJson(null);

      expect(user.id, isNull);
      expect(user.nickName, isNull);
      expect(user.email, isNull);
      expect(user.avatar, isNull);
      expect(user.isAdmin, isNull);
      expect(user.isNew, isNull);
    });

    test('fromJson gère les types de données variés', () {
      final json = {
        'id': '456',
        'isAdmin': 'true',
      };

      final user = UserDto.fromJson(json);

      expect(user.id, equals(456));
      expect(user.isAdmin, isTrue);
    });

    test('toJson sérialise correctement', () {
      final user = UserDto(
        id: 1,
        nickName: 'John',
        email: 'john@test.com',
        avatar: 'pic.jpg',
        isAdmin: false,
        isNew: true,
      );

      final json = user.toJson();

      expect(json['id'], equals(1));
      expect(json['nickName'], equals('John'));
      expect(json['email'], equals('john@test.com'));
      expect(json['avatar'], equals('pic.jpg'));
      expect(json['isAdmin'], isFalse);
      expect(json['isNew'], isTrue);
    });
  });

  group('AuthTokenDto', () {
    test('fromJson crée un token valide', () {
      final json = {
        'token': 'test_token_abc123',
        'validFrom': '2024-01-01T00:00:00Z',
        'validTo': '2024-12-31T23:59:59Z',
      };

      final token = AuthTokenDto.fromJson(json);

      expect(token.token, equals('test_token_abc123'));
      expect(token.validFrom, isNotNull);
      expect(token.validTo, isNotNull);
    });

    test('fromJson gère un token sans dates', () {
      final json = {'token': 'simple_token'};

      final token = AuthTokenDto.fromJson(json);

      expect(token.token, equals('simple_token'));
      expect(token.validFrom, isNull);
      expect(token.validTo, isNull);
    });

    test('fromJson utilise une string vide si token manquant', () {
      final token = AuthToken.fromJson({});

      expect(token.token, equals(''));
    });
  });

  group('AuthSession', () {
    test('crée une session complète', () {
      final user = UserDto(id: 1, nickName: 'test');
      final token = AuthToken(token: 'abc');
      final raw = {'extra': 'data'};

      final session = AuthSession(
        user: user,
        token: token,
        isGoogleUser: false,
        raw: raw,
      );

      expect(session.user, equals(user));
      expect(session.token, equals(token));
      expect(session.isGoogleUser, isFalse);
      expect(session.raw, equals(raw));
    });
  });

  group('RegisterResult', () {
    test('crée un résultat d\'inscription', () {
      final raw = {'status': 'pending'};
      final result = RegisterResult(
        verificationRequired: true,
        delivery: 'email',
        raw: raw,
        verificationId: 'verify123',
      );

      expect(result.verificationRequired, isTrue);
      expect(result.delivery, equals('email'));
      expect(result.verificationId, equals('verify123'));
      expect(result.raw, equals(raw));
    });
  });

  group('LoginResult', () {
    test('crée un résultat de login avec 2FA', () {
      final result = LoginResult(
        requires2fa: true,
        delivery: 'sms',
        emailHint: '+33***1234',
      );

      expect(result.requires2fa, isTrue);
      expect(result.delivery, equals('sms'));
      expect(result.emailHint, equals('+33***1234'));
      expect(result.session, isNull);
    });

    test('crée un résultat de login direct', () {
      final user = UserDto(id: 1);
      final token = AuthToken(token: 'token');
      final session = AuthSession(
        user: user,
        token: token,
        isGoogleUser: false,
        raw: {},
      );

      final result = LoginResult(
        requires2fa: false,
        session: session,
      );

      expect(result.requires2fa, isFalse);
      expect(result.session, equals(session));
    });
  });

  group('AuthApi', () {
    late MockApiClient mockApiClient;
    late AuthApi authApi;

    setUp(() {
      mockApiClient = MockApiClient();
      authApi = AuthApi(mockApiClient);
    });

    group('register', () {
      test('retourne succès avec verificationId', () async {
        final responseData = {
          'verificationId': 'verify_123',
          'delivery': 'email',
        };

        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.register(
          email: 'test@example.com',
          nickName: 'testuser',
          password: 'password123',
        );

        expect(result.ok, isTrue);
        expect(result.data?.verificationRequired, isTrue);
        expect(result.data?.verificationId, equals('verify_123'));
        expect(result.data?.delivery, equals('email'));
      });

      test('trim les espaces dans email et nickName', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok({'delivery': 'email'}, statusCode: 200),
        );

        await authApi.register(
          email: '  test@example.com  ',
          nickName: '  testuser  ',
          password: 'pass',
        );

        final captured = verify(mockApiClient.postJson(
          captureAny,
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[1] as Map<String, dynamic>;
        expect(body['email'], equals('test@example.com'));
        expect(body['nickName'], equals('testuser'));
      });

      test('retourne erreur en cas d\'échec', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Email déjà utilisé',
            statusCode: 409,
          ),
        );

        final result = await authApi.register(
          email: 'existing@example.com',
          nickName: 'test',
          password: 'pass',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Email déjà utilisé'));
        expect(result.statusCode, equals(409));
      });

      test('utilise delivery par défaut si non fourni', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok({}, statusCode: 200),
        );

        final result = await authApi.register(
          email: 'test@example.com',
          nickName: 'test',
          password: 'pass',
        );

        expect(result.data?.delivery, equals('email'));
      });
    });

    group('login', () {
      test('retourne succès pour un login valide', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok({}, statusCode: 200),
        );

        final result = await authApi.login(
          login: 'test@example.com',
          password: 'password123',
        );

        expect(result.ok, isTrue);
        expect(result.data, isTrue);
        expect(result.statusCode, equals(200));
      });

      test('trim le login', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok({}, statusCode: 200),
        );

        await authApi.login(
          login: '  user@example.com  ',
          password: 'pass',
        );

        final captured = verify(mockApiClient.postJson(
          captureAny,
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[1] as Map<String, dynamic>;
        expect(body['login'], equals('user@example.com'));
      });

      test('retourne erreur pour identifiants invalides', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Invalid credentials',
            statusCode: 401,
          ),
        );

        final result = await authApi.login(
          login: 'wrong@example.com',
          password: 'wrongpass',
        );

        expect(result.ok, isFalse);
        expect(result.statusCode, equals(401));
      });

      test('extrait le message d\'erreur depuis un tableau', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Error',
            statusCode: 401,
            raw: [
              {'description': 'Identifiants incorrects'}
            ],
          ),
        );

        final result = await authApi.login(
          login: 'test@example.com',
          password: 'wrong',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Identifiants incorrects'));
      });

      test('utilise message par défaut si extraction échoue', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.err(statusCode: 401),
        );

        final result = await authApi.login(
          login: 'test@example.com',
          password: 'wrong',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Échec de la connexion.'));
      });
    });

    group('loginWithGoogle', () {
      test('retourne une session valide', () async {
        final responseData = {
          'user': {
            'id': 1,
            'nickName': 'googleUser',
            'email': 'user@gmail.com',
          },
          'token': {
            'token': 'google_token_123',
          },
          'isGoogleUser': true,
        };

        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.loginWithGoogle(
          idToken: 'google_id_token',
        );

        expect(result.ok, isTrue);
        expect(result.data?.user.nickName, equals('googleUser'));
        expect(result.data?.token.token, equals('google_token_123'));
        expect(result.data?.isGoogleUser, isTrue);
      });

      test('utilise isGoogleUser true par défaut', () async {
        final responseData = {
          'user': {'id': 1},
          'token': {'token': 'token'},
        };

        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.loginWithGoogle(
          idToken: 'token',
        );

        expect(result.data?.isGoogleUser, isTrue);
      });

      test('retourne erreur en cas d\'échec', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Invalid Google token',
            statusCode: 401,
          ),
        );

        final result = await authApi.loginWithGoogle(
          idToken: 'invalid_token',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Invalid Google token'));
      });
    });

    group('updateNickname', () {
      test('retourne succès pour une mise à jour valide', () async {
        final responseData = {
          'success': true,
          'value': {
            'id': 1,
            'nickName': 'NewNickname',
            'email': 'test@example.com',
          },
        };

        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.updateNickname(
          nickname: 'NewNickname',
        );

        expect(result.ok, isTrue);
        expect(result.data?.nickName, equals('NewNickname'));
        expect(result.statusCode, equals(200));
      });

      test('trim le nickname', () async {
        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(
            {'success': true, 'value': {'id': 1, 'nickName': 'TestNick'}},
            statusCode: 200,
          ),
        );

        await authApi.updateNickname(
          nickname: '  TestNick  ',
        );

        final captured = verify(mockApiClient.putJson(
          captureAny,
          body: captureAnyNamed('body'),
          auth: anyNamed('auth'),
        )).captured;

        final body = captured[1] as Map<String, dynamic>;
        expect(body['nickname'], equals('TestNick'));
      });

      test('gère une réponse avec value en Map', () async {
        final responseData = {
          'success': true,
          'value': {
            'id': 123,
            'nickName': 'UpdatedUser',
            'email': 'user@test.com',
            'avatar': 'pic.png',
          },
        };

        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.updateNickname(
          nickname: 'UpdatedUser',
        );

        expect(result.ok, isTrue);
        expect(result.data?.id, equals(123));
        expect(result.data?.nickName, equals('UpdatedUser'));
        expect(result.data?.email, equals('user@test.com'));
      });

      test('gère une réponse avec value en List', () async {
        final responseData = {
          'success': true,
          'value': [
            {
              'id': 456,
              'nickName': 'ListUser',
              'email': 'list@test.com',
            }
          ],
        };

        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.updateNickname(
          nickname: 'ListUser',
        );

        expect(result.ok, isTrue);
        expect(result.data?.id, equals(456));
        expect(result.data?.nickName, equals('ListUser'));
      });

      test('retourne erreur en cas d\'échec', () async {
        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Pseudo déjà utilisé',
            statusCode: 409,
          ),
        );

        final result = await authApi.updateNickname(
          nickname: 'existing',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Pseudo déjà utilisé'));
        expect(result.statusCode, equals(409));
      });

      test('retourne erreur si success est false', () async {
        final responseData = {
          'success': false,
          'message': 'Échec de la validation',
        };

        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.updateNickname(
          nickname: 'invalid',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Échec de la validation'));
      });

      test('extrait le message d\'erreur depuis errors', () async {
        final responseData = {
          'success': false,
          'errors': [
            {'description': 'Pseudo trop court'}
          ],
        };

        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.updateNickname(
          nickname: 'ab',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Pseudo trop court'));
      });

      test('utilise message par défaut si extraction échoue', () async {
        final responseData = {
          'success': false,
        };

        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.updateNickname(
          nickname: 'test',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Échec de la mise à jour du pseudo.'));
      });

      test('utilise success true par défaut si non fourni', () async {
        final responseData = {
          'value': {
            'id': 1,
            'nickName': 'DefaultSuccess',
          },
        };

        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.updateNickname(
          nickname: 'DefaultSuccess',
        );

        expect(result.ok, isTrue);
        expect(result.data?.nickName, equals('DefaultSuccess'));
      });
    });

    group('refreshToken', () {
      test('retourne succès avec nouvelle session', () async {
        final responseData = {
          'user': {
            'id': 1,
            'nickName': 'testUser',
            'email': 'test@example.com',
          },
          'token': {
            'token': 'new_access_token',
            'validFrom': '2026-01-15T10:00:00Z',
            'validTo': '2026-01-15T11:00:00Z',
            'refreshToken': 'new_refresh_token',
            'refreshTokenExpiresAt': '2026-01-22T10:00:00Z',
          },
          'isGoogleUser': false,
        };

        when(mockApiClient.postJson(
          '/api/v1/auth/refresh',
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.refreshToken(
          bearer: 'old_access_token',
          refreshToken: 'old_refresh_token',
        );

        expect(result.ok, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.token.token, equals('new_access_token'));
        expect(result.data!.token.refreshToken, equals('new_refresh_token'));
        expect(result.data!.user.nickName, equals('testUser'));
        expect(result.data!.isGoogleUser, isFalse);

        final capturedCall = verify(mockApiClient.postJson(
          '/api/v1/auth/refresh',
          body: captureAnyNamed('body'),
        )).captured;

        expect(capturedCall.length, equals(1));
        final body = capturedCall[0] as Map<String, dynamic>;
        expect(body['bearer'], equals('old_access_token'));
        expect(body['refreshToken'], equals('old_refresh_token'));
      });

      test('retourne erreur si refresh échoue', () async {
        when(mockApiClient.postJson(
          '/api/v1/auth/refresh',
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Refresh token expired',
            statusCode: 401,
          ),
        );

        final result = await authApi.refreshToken(
          bearer: 'old_access_token',
          refreshToken: 'expired_refresh_token',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Refresh token expired'));
        expect(result.statusCode, equals(401));
      });

      test('gère les tokens manquants dans la réponse', () async {
        final responseData = {
          'user': {'id': 1},
          'token': {},
          'isGoogleUser': false,
        };

        when(mockApiClient.postJson(
          '/api/v1/auth/refresh',
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.refreshToken(
          bearer: 'token',
          refreshToken: 'refresh',
        );

        expect(result.ok, isTrue);
        expect(result.data!.token.token, equals(''));
        expect(result.data!.token.refreshToken, isNull);
      });
    });

    group('passwordReset', () {
      test('retourne succès pour un reset valide', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok({}, statusCode: 200),
        );

        final result = await authApi.passwordReset(
          login: 'test@example.com',
          code: '123456',
          password: 'NewPassword123!',
        );

        expect(result.ok, isTrue);
        expect(result.data, isTrue);
        expect(result.statusCode, equals(200));
      });

      test('trim le login et le code', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok({}, statusCode: 200),
        );

        await authApi.passwordReset(
          login: '  user@test.com  ',
          code: '  123456  ',
          password: 'pass',
        );

        final captured = verify(mockApiClient.postJson(
          captureAny,
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[1] as Map<String, dynamic>;
        expect(body['login'], equals('user@test.com'));
        expect(body['code'], equals('123456'));
      });

      test('retourne erreur pour un code invalide', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Code invalide ou expiré',
            statusCode: 400,
          ),
        );

        final result = await authApi.passwordReset(
          login: 'test@example.com',
          code: 'wrongcode',
          password: 'NewPass',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Code invalide ou expiré'));
        expect(result.statusCode, equals(400));
      });

      test('utilise message par défaut si non fourni', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.err(statusCode: 500),
        );

        final result = await authApi.passwordReset(
          login: 'test@example.com',
          code: '123456',
          password: 'pass',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Réinitialisation impossible.'));
      });
    });

    group('verify2fa', () {
      test('retourne une session valide pour un code correct', () async {
        final responseData = {
          'user': {
            'id': 1,
            'nickName': 'testUser',
            'email': 'test@example.com',
          },
          'token': {
            'token': '2fa_verified_token',
            'validTo': '2026-01-16T12:00:00Z',
            'refreshToken': 'refresh_token_2fa',
          },
          'isGoogleUser': false,
        };

        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.verify2fa(
          login: 'test@example.com',
          code: '123456',
        );

        expect(result.ok, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.token.token, equals('2fa_verified_token'));
        expect(result.data!.user.nickName, equals('testUser'));
        expect(result.data!.isGoogleUser, isFalse);
      });

      test('trim le login et le code', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(
            {
              'user': {'id': 1},
              'token': {'token': 'token'},
            },
            statusCode: 200,
          ),
        );

        await authApi.verify2fa(
          login: '  user@test.com  ',
          code: '  654321  ',
        );

        final captured = verify(mockApiClient.postJson(
          captureAny,
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[1] as Map<String, dynamic>;
        expect(body['login'], equals('user@test.com'));
        expect(body['code'], equals('654321'));
      });

      test('retourne erreur pour un code incorrect', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Code 2FA invalide',
            statusCode: 401,
          ),
        );

        final result = await authApi.verify2fa(
          login: 'test@example.com',
          code: 'wrong',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Code 2FA invalide'));
        expect(result.statusCode, equals(401));
      });

      test('utilise isGoogleUser false par défaut', () async {
        final responseData = {
          'user': {'id': 1},
          'token': {'token': 'token'},
        };

        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.verify2fa(
          login: 'test@example.com',
          code: '123456',
        );

        expect(result.data?.isGoogleUser, isFalse);
      });

      test('gère les données manquantes gracieusement', () async {
        final responseData = {
          'user': {},
          'token': {},
        };

        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.verify2fa(
          login: 'test@example.com',
          code: '123456',
        );

        expect(result.ok, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.token.token, equals(''));
      });
    });

    group('me', () {
      test('retourne les informations de l\'utilisateur connecté', () async {
        final responseData = {
          'id': 42,
          'nickName': 'CurrentUser',
          'email': 'current@example.com',
          'avatar': 'avatar.png',
          'isAdmin': false,
          'isNew': false,
        };

        when(mockApiClient.getJson(
          any,
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 200),
        );

        final result = await authApi.me();

        expect(result.ok, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, equals(42));
        expect(result.data!.nickName, equals('CurrentUser'));
        expect(result.data!.email, equals('current@example.com'));

        verify(mockApiClient.getJson('/api/v1/me', auth: true)).called(1);
      });

      test('retourne erreur si non authentifié', () async {
        when(mockApiClient.getJson(
          any,
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Non authentifié',
            statusCode: 401,
          ),
        );

        final result = await authApi.me();

        expect(result.ok, isFalse);
        expect(result.message, equals('Non authentifié'));
        expect(result.statusCode, equals(401));
      });

      test('gère les réponses vides', () async {
        when(mockApiClient.getJson(
          any,
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok({}, statusCode: 200),
        );

        final result = await authApi.me();

        expect(result.ok, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, isNull);
      });
    });

    group('changePassword', () {
      test('retourne succès pour un changement valide', () async {
        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok({}, statusCode: 200),
        );

        final result = await authApi.changePassword(
          currentPassword: 'OldPassword123',
          newPassword: 'NewPassword456',
        );

        expect(result.ok, isTrue);
        expect(result.data, isTrue);
        expect(result.statusCode, equals(200));

        verify(mockApiClient.putJson(
          '/api/v1/me/change-password',
          body: anyNamed('body'),
          auth: true,
        )).called(1);
      });

      test('envoie currentPassword et oldPassword dans le body', () async {
        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.ok({}, statusCode: 200),
        );

        await authApi.changePassword(
          currentPassword: 'current',
          newPassword: 'new',
        );

        final captured = verify(mockApiClient.putJson(
          captureAny,
          body: captureAnyNamed('body'),
          auth: anyNamed('auth'),
        )).captured;

        final body = captured[1] as Map<String, dynamic>;
        expect(body['currentPassword'], equals('current'));
        expect(body['oldPassword'], equals('current'));
        expect(body['newPassword'], equals('new'));
      });

      test('retourne erreur si le mot de passe actuel est incorrect', () async {
        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Mot de passe actuel incorrect',
            statusCode: 400,
          ),
        );

        final result = await authApi.changePassword(
          currentPassword: 'wrong',
          newPassword: 'new',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Mot de passe actuel incorrect'));
        expect(result.statusCode, equals(400));
      });

      test('retourne erreur si non authentifié', () async {
        when(mockApiClient.putJson(
          any,
          body: anyNamed('body'),
          auth: anyNamed('auth'),
        )).thenAnswer(
          (_) async => ApiResponse.err(
            message: 'Non authentifié',
            statusCode: 401,
          ),
        );

        final result = await authApi.changePassword(
          currentPassword: 'current',
          newPassword: 'new',
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Non authentifié'));
        expect(result.statusCode, equals(401));
      });
    });
  });

  group('AuthToken avec refreshToken', () {
    test('fromJson crée un token avec refresh token', () {
      final json = {
        'token': 'access_token',
        'validFrom': '2026-01-15T10:00:00Z',
        'validTo': '2026-01-15T11:00:00Z',
        'refreshToken': 'refresh_token',
        'refreshTokenExpiresAt': '2026-01-22T10:00:00Z',
      };

      final token = AuthToken.fromJson(json);

      expect(token.token, equals('access_token'));
      expect(token.refreshToken, equals('refresh_token'));
      expect(token.refreshTokenExpiresAt, isNotNull);
    });

    test('toJson sérialise tous les champs', () {
      final token = AuthToken(
        token: 'access_token',
        validFrom: DateTime.parse('2026-01-15T10:00:00Z'),
        validTo: DateTime.parse('2026-01-15T11:00:00Z'),
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: DateTime.parse('2026-01-22T10:00:00Z'),
      );

      final json = token.toJson();

      expect(json['token'], equals('access_token'));
      expect(json['validFrom'], equals('2026-01-15T10:00:00.000Z'));
      expect(json['validTo'], equals('2026-01-15T11:00:00.000Z'));
      expect(json['refreshToken'], equals('refresh_token'));
      expect(json['refreshTokenExpiresAt'], equals('2026-01-22T10:00:00.000Z'));
    });

    test('fromJson gère un token sans refreshToken', () {
      final json = {
        'token': 'access_only',
        'validTo': '2026-01-15T11:00:00Z',
      };

      final token = AuthToken.fromJson(json);

      expect(token.token, equals('access_only'));
      expect(token.refreshToken, isNull);
      expect(token.refreshTokenExpiresAt, isNull);
    });

    test('toJson gère les champs null', () {
      final token = AuthToken(token: 'basic_token');

      final json = token.toJson();

      expect(json['token'], equals('basic_token'));
      expect(json['validFrom'], isNull);
      expect(json['validTo'], isNull);
      expect(json['refreshToken'], isNull);
      expect(json['refreshTokenExpiresAt'], isNull);
    });
  });
}
