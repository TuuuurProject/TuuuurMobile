import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth_api_service.dart';

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
        'id': '456', // String au lieu de int
        'isAdmin': 'true', // String au lieu de bool
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

  group('AuthToken', () {
    test('fromJson crée un token valide', () {
      final json = {
        'token': 'test_token_abc123',
        'validFrom': '2024-01-01T00:00:00Z',
        'validTo': '2024-12-31T23:59:59Z',
      };

      final token = AuthToken.fromJson(json);

      expect(token.token, equals('test_token_abc123'));
      expect(token.validFrom, isNotNull);
      expect(token.validTo, isNotNull);
    });

    test('fromJson gère un token sans dates', () {
      final json = {'token': 'simple_token'};

      final token = AuthToken.fromJson(json);

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
  });
}
