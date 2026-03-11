import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/group/group_api_service.dart';

import 'group_api_service_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('GroupResult', () {
    test('fromJson crée une instance complète', () {
      final json = {
        'id': 'party-uuid-123',
        'code': 'ABCD12',
        'nbQuestions': 10,
        'inProgress': true,
        'scoreEachRound': false,
        'idUserHost': 'host-uuid',
        'active': true,
        'finish': false,
        'dt': '2024-01-15T10:00:00Z',
        'percent': 75,
        'score': 8,
        'time': 120,
        'partyUsers': [
          {
            'idUser': 'user-1',
            'idParty': 'party-uuid-123',
          },
        ],
        'partyTheme': [
          {'idTheme': 1},
          {'idTheme': 3},
        ],
        'partyDifficulty': [
          {'idDifficulty': 2},
        ],
      };

      final result = GroupResult.fromJson(json);

      expect(result.partyId, equals('party-uuid-123'));
      expect(result.code, equals('ABCD12'));
      expect(result.nbQuestions, equals(10));
      expect(result.inProgress, isTrue);
      expect(result.scoreEachRound, isFalse);
      expect(result.hostUserId, equals('host-uuid'));
      expect(result.active, isTrue);
      expect(result.finish, isFalse);
      expect(result.dt, equals('2024-01-15T10:00:00Z'));
      expect(result.percent, equals(75));
      expect(result.score, equals(8));
      expect(result.time, equals(120));
      expect(result.partyUsers.length, equals(1));
      expect(result.themeIds, equals([1, 3]));
      expect(result.difficultyIds, equals([2]));
    });

    test('fromJson gère partyId comme clé alternative', () {
      final json = {
        'partyId': 'test-id',
        'code': 'TEST',
      };

      final result = GroupResult.fromJson(json);

      expect(result.partyId, equals('test-id'));
    });

    test('fromJson gère valeurs nulles et listes vides', () {
      final json = {
        'id': 'minimal-id',
        'code': 'MIN',
      };

      final result = GroupResult.fromJson(json);

      expect(result.partyId, equals('minimal-id'));
      expect(result.code, equals('MIN'));
      expect(result.nbQuestions, isNull);
      expect(result.inProgress, isNull);
      expect(result.partyUsers, isEmpty);
      expect(result.themeIds, isEmpty);
      expect(result.difficultyIds, isEmpty);
    });

    test('fromJson filtre thèmes sans idTheme', () {
      final json = {
        'id': 'test',
        'code': 'TEST',
        'partyTheme': [
          {'idTheme': 1},
          {'other': 'value'}, // pas d'idTheme
          {'idTheme': 2},
        ],
      };

      final result = GroupResult.fromJson(json);

      expect(result.themeIds, equals([1, 2]));
    });

    test('fromJson filtre difficultés sans idDifficulty', () {
      final json = {
        'id': 'test',
        'code': 'TEST',
        'partyDifficulty': [
          {'idDifficulty': 1},
          {'wrong': 'key'},
          {'idDifficulty': 3},
        ],
      };

      final result = GroupResult.fromJson(json);

      expect(result.difficultyIds, equals([1, 3]));
    });

    test('empty constante a des valeurs vides', () {
      expect(GroupResult.empty.partyId, equals(''));
      expect(GroupResult.empty.code, equals(''));
    });
  });

  group('GroupApi', () {
    late MockApiClient mockApiClient;
    late GroupApi groupApi;

    setUp(() {
      mockApiClient = MockApiClient();
      groupApi = GroupApi(mockApiClient);
    });

    group('createGroup', () {
      test('crée une partie avec succès', () async {
        final responseData = {
          'id': 'new-party-id',
          'code': 'NEW123',
          'partyUsers': [],
        };

        when(mockApiClient.postJson(
          '/api/v1/group/create',
          headers: null,
          body: {},
        )).thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 201));

        final result = await groupApi.createGroup();

        expect(result.ok, isTrue);
        expect(result.data!.partyId, equals('new-party-id'));
        expect(result.data!.code, equals('NEW123'));
      });

      test('gère réponse avec data wrapper', () async {
        final responseData = {
          'data': {
            'id': 'wrapped-id',
            'code': 'WRAP',
          },
        };

        when(mockApiClient.postJson(
          '/api/v1/group/create',
          headers: null,
          body: {},
        )).thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 201));

        final result = await groupApi.createGroup();

        expect(result.ok, isTrue);
        expect(result.data!.partyId, equals('wrapped-id'));
      });

      test('gère réponse avec data wrapper double', () async {
        final responseData = {
          'data': {
            'data': {
              'id': 'wrapped-id',
              'code': 'WRAP',
            },
          },
        };

        when(mockApiClient.postJson(
          '/api/v1/group/create',
          headers: null,
          body: {},
        )).thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 201));

        final result = await groupApi.createGroup();

        expect(result.ok, isTrue);
        expect(result.data!.partyId, equals('wrapped-id'));
        expect(result.data!.code, equals('WRAP'));
      });

      test('retourne erreur si id ou code manquant', () async {
        final responseData = {'code': 'NO-ID'};

        when(mockApiClient.postJson(
          '/api/v1/group/create',
          headers: null,
          body: {},
        )).thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 201));

        final result = await groupApi.createGroup();

        expect(result.ok, isFalse);
        expect(result.message, contains('inattendue'));
      });

      test('retourne erreur si la requête échoue', () async {
        when(mockApiClient.postJson(
          '/api/v1/group/create',
          headers: null,
          body: {},
        )).thenAnswer((_) async => ApiResponse.err(
              message: 'Erreur serveur',
              statusCode: 500,
            ));

        final result = await groupApi.createGroup();

        expect(result.ok, isFalse);
        expect(result.message, equals('Erreur serveur'));
      });

      test('accepte des headers personnalisés', () async {
        final headers = {'Custom': 'Header'};
        final responseData = {'id': 'test', 'code': 'TEST'};

        when(mockApiClient.postJson(
          '/api/v1/group/create',
          headers: headers,
          body: {},
        )).thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 201));

        final result = await groupApi.createGroup(headers: headers);

        expect(result.ok, isTrue);
        verify(mockApiClient.postJson(
          '/api/v1/group/create',
          headers: headers,
          body: {},
        )).called(1);
      });
    });

    group('joinGroup', () {
      test('rejoint une partie avec succès', () async {
        final responseData = {
          'id': 'joined-party',
          'code': 'JOIN99',
          'partyUsers': [],
        };

        when(mockApiClient.postJson(
          '/api/v1/group/join',
          headers: null,
          body: {'code': 'JOIN99'},
        )).thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await groupApi.joinGroup(code: 'JOIN99');

        expect(result.ok, isTrue);
        expect(result.data!.code, equals('JOIN99'));
      });

      test('retourne erreur si code invalide', () async {
        when(mockApiClient.postJson(
          '/api/v1/group/join',
          headers: null,
          body: {'code': 'WRONG'},
        )).thenAnswer((_) async => ApiResponse.err(
              message: 'Code invalide',
              statusCode: 404,
            ));

        final result = await groupApi.joinGroup(code: 'WRONG');

        expect(result.ok, isFalse);
        expect(result.message, equals('Code invalide'));
      });

      test('retourne erreur si réponse invalide', () async {
        final responseData = {'incomplete': 'data'};

        when(mockApiClient.postJson(
          '/api/v1/group/join',
          headers: null,
          body: {'code': 'TEST'},
        )).thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await groupApi.joinGroup(code: 'TEST');

        expect(result.ok, isFalse);
        expect(result.message, contains('inattendue'));
      });
    });

    group('updateSettings', () {
      test('met à jour les paramètres avec succès', () async {
        when(mockApiClient.postJson(
          '/api/v1/group/settings',
          headers: null,
          body: {
            'themes': [1, 2, 3],
            'difficulties': [2],
            'nbQuestions': 10,
            'scoreEachRound': true,
          },
        )).thenAnswer((_) async => ApiResponse.ok({}, statusCode: 204));

        final result = await groupApi.updateSettings(
          themeIds: [1, 2, 3],
          difficultyIds: [2],
          nbQuestions: 10,
          scoreEachRound: true,
        );

        expect(result.ok, isTrue);
      });

      test('accepte différentes valeurs de nbQuestions', () async {
        when(mockApiClient.postJson(
          any,
          headers: null,
          body: anyNamed('body'),
        )).thenAnswer((_) async => ApiResponse.ok({}, statusCode: 204));

        final result = await groupApi.updateSettings(
          themeIds: [1],
          difficultyIds: [1],
          nbQuestions: 20,
          scoreEachRound: false,
        );

        expect(result.ok, isTrue);
      });

      test('retourne erreur si échec', () async {
        when(mockApiClient.postJson(
          any,
          headers: null,
          body: anyNamed('body'),
        )).thenAnswer((_) async => ApiResponse.err(
              message: 'Non autorisé',
              statusCode: 403,
            ));

        final result = await groupApi.updateSettings(
          themeIds: [1],
          difficultyIds: [1],
          nbQuestions: 10,
          scoreEachRound: true,
        );

        expect(result.ok, isFalse);
        expect(result.statusCode, equals(403));
      });
    });

    group('leaveGroup', () {
      test('quitte la partie avec succès', () async {
        final responseData = {
          'id': 'left-party',
          'code': 'LEFT',
        };

        when(mockApiClient.postJson(
          '/api/v1/group/leave',
          headers: null,
          body: {},
        )).thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await groupApi.leaveGroup();

        expect(result.ok, isTrue);
        expect(result.data, isNotNull);
      });

      test('retourne empty si pas de données', () async {
        when(mockApiClient.postJson(
          '/api/v1/group/leave',
          headers: null,
          body: {},
        )).thenAnswer((_) async => ApiResponse.ok({}, statusCode: 204));

        final result = await groupApi.leaveGroup();

        expect(result.ok, isTrue);
        expect(result.data!.partyId, equals(''));
        expect(result.data!.code, equals(''));
      });

      test('retourne erreur si échec', () async {
        when(mockApiClient.postJson(
          '/api/v1/group/leave',
          headers: null,
          body: {},
        )).thenAnswer((_) async => ApiResponse.err(
              message: 'Impossible de quitter',
              statusCode: 400,
            ));

        final result = await groupApi.leaveGroup();

        expect(result.ok, isFalse);
        expect(result.message, equals('Impossible de quitter'));
      });
    });
  });
}
