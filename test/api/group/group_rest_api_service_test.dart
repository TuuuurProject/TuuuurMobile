import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/group/group_rest_api_service.dart';
import 'package:tuuuur_flutter/api/group/group_models.dart';

import 'group_rest_api_service_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('GroupRestApiService', () {
    late MockApiClient mockApiClient;
    late GroupRestApiService service;

    setUp(() {
      mockApiClient = MockApiClient();
      service = GroupRestApiService(apiClient: mockApiClient);
    });

    group('createGroup', () {
      test('crée une nouvelle partie avec succès', () async {
        final responseData = {
          'id': 'new-party-uuid',
          'code': 'ABC123',
          'nbQuestions': 10,
          'inProgress': false,
          'scoreEachRound': false,
          'idPartyType': 2,
          'idUserHost': 'host-user-id',
          'active': true,
          'finish': false,
          'dt': '2024-01-15T10:00:00Z',
          'partyUsers': [],
          'partyTheme': [],
          'partyDifficulty': [],
          'percent': 0.0,
          'score': 0,
          'time': 0,
        };

        when(mockApiClient.postJson('/api/v1/group/create', body: {}, auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 201));

        final result = await service.createGroup();

        expect(result.ok, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('new-party-uuid'));
        expect(result.data!.code, equals('ABC123'));
        expect(result.data!.nbQuestions, equals(10));
      });

      test('retourne erreur si la requête échoue', () async {
        when(mockApiClient.postJson('/api/v1/group/create', body: {}, auth: true))
            .thenAnswer((_) async => ApiResponse.err(
                  message: 'Erreur serveur',
                  statusCode: 500,
                ));

        final result = await service.createGroup();

        expect(result.ok, isFalse);
        expect(result.message, equals('Erreur serveur'));
        expect(result.statusCode, equals(500));
      });

      test('utilise message par défaut si pas de message d\'erreur', () async {
        when(mockApiClient.postJson('/api/v1/group/create', body: {}, auth: true))
            .thenAnswer((_) async => ApiResponse.err(statusCode: 400));

        final result = await service.createGroup();

        expect(result.ok, isFalse);
        expect(result.message, equals('Erreur lors de la création de la partie'));
      });

      test('gère exception pendant la requête', () async {
        when(mockApiClient.postJson('/api/v1/group/create', body: {}, auth: true))
            .thenThrow(Exception('Network error'));

        final result = await service.createGroup();

        expect(result.ok, isFalse);
        expect(result.message, contains('Erreur'));
      });
    });

    group('joinGroup', () {
      test('rejoint une partie existante avec succès', () async {
        final responseData = {
          'id': 'joined-party-uuid',
          'code': 'XYZ789',
          'nbQuestions': 15,
          'inProgress': true,
          'scoreEachRound': true,
          'idPartyType': 2,
          'idUserHost': 'other-host',
          'active': true,
          'finish': false,
          'dt': '2024-01-15T11:00:00Z',
          'partyUsers': [
            {
              'idUser': 'user-1',
              'idParty': 'joined-party-uuid',
              'user': {
                'id': 'user-1',
                'nickName': 'Player1',
                'isAdmin': false,
                'isNew': false,
              },
            },
          ],
          'partyTheme': [],
          'partyDifficulty': [],
          'percent': 50.0,
          'score': 5,
          'time': 60,
        };

        when(mockApiClient.postJson(
          '/api/v1/group/join',
          body: {'code': 'XYZ789'},
          auth: true,
        )).thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await service.joinGroup(code: 'XYZ789');

        expect(result.ok, isTrue);
        expect(result.data!.code, equals('XYZ789'));
        expect(result.data!.partyUsers.length, equals(1));
      });

      test('retourne erreur si code vide', () async {
        final result = await service.joinGroup(code: '');

        expect(result.ok, isFalse);
        expect(result.message, contains('vide'));
      });

      test('retourne erreur si code avec espaces uniquement', () async {
        final result = await service.joinGroup(code: '   ');

        expect(result.ok, isFalse);
        expect(result.message, contains('vide'));
      });

      test('retourne erreur si code invalide', () async {
        when(mockApiClient.postJson(
          '/api/v1/group/join',
          body: {'code': 'INVALID'},
          auth: true,
        )).thenAnswer((_) async => ApiResponse.err(
              message: 'Code invalide',
              statusCode: 404,
            ));

        final result = await service.joinGroup(code: 'INVALID');

        expect(result.ok, isFalse);
        expect(result.message, equals('Code invalide'));
      });

      test('utilise message par défaut en cas d\'erreur', () async {
        when(mockApiClient.postJson(
          '/api/v1/group/join',
          body: {'code': 'TEST'},
          auth: true,
        )).thenAnswer((_) async => ApiResponse.err(statusCode: 500));

        final result = await service.joinGroup(code: 'TEST');

        expect(result.ok, isFalse);
        expect(result.message, equals('Erreur lors de la connexion à la partie'));
      });

      test('gère exception pendant la requête', () async {
        when(mockApiClient.postJson(
          '/api/v1/group/join',
          body: {'code': 'ERROR'},
          auth: true,
        )).thenThrow(Exception('Connection timeout'));

        final result = await service.joinGroup(code: 'ERROR');

        expect(result.ok, isFalse);
        expect(result.message, contains('Erreur'));
      });
    });

    group('leaveGroup', () {
      test('quitte la partie avec succès', () async {
        when(mockApiClient.postJson('/api/v1/group/leave', body: {}, auth: true))
            .thenAnswer((_) async => ApiResponse.ok({}, statusCode: 200));

        final result = await service.leaveGroup();

        expect(result.ok, isTrue);
      });

      test('retourne erreur si échec', () async {
        when(mockApiClient.postJson('/api/v1/group/leave', body: {}, auth: true))
            .thenAnswer((_) async => ApiResponse.err(
                  message: 'Impossible de quitter',
                  statusCode: 400,
                ));

        final result = await service.leaveGroup();

        expect(result.ok, isFalse);
        expect(result.message, equals('Impossible de quitter'));
      });

      test('utilise message par défaut en cas d\'erreur', () async {
        when(mockApiClient.postJson('/api/v1/group/leave', body: {}, auth: true))
            .thenAnswer((_) async => ApiResponse.err(statusCode: 500));

        final result = await service.leaveGroup();

        expect(result.ok, isFalse);
        expect(result.message, equals('Erreur lors de la déconnexion'));
      });

      test('gère exception pendant la requête', () async {
        when(mockApiClient.postJson('/api/v1/group/leave', body: {}, auth: true))
            .thenThrow(Exception('Network error'));

        final result = await service.leaveGroup();

        expect(result.ok, isFalse);
        expect(result.message, contains('Erreur'));
      });
    });

    group('updateSettings', () {
      test('met à jour les paramètres avec succès', () async {
        when(mockApiClient.postJson(
          '/api/v1/group/settings',
          body: {
            'themes': [1, 2, 3],
            'difficulties': [1, 2],
            'nbQuestions': 10,
            'scoreEachRound': true,
          },
          auth: true,
        )).thenAnswer((_) async => ApiResponse.ok({}, statusCode: 200));

        final result = await service.updateSettings(
          themes: [1, 2, 3],
          difficulties: [1, 2],
          nbQuestions: 10,
          scoreEachRound: true,
        );

        expect(result.ok, isTrue);
      });

      test('retourne erreur si liste themes vide', () async {
        final result = await service.updateSettings(
          themes: [],
          difficulties: [1],
          nbQuestions: 10,
          scoreEachRound: false,
        );

        expect(result.ok, isFalse);
        expect(result.message, contains('thèmes'));
      });

      test('retourne erreur si liste difficulties vide', () async {
        final result = await service.updateSettings(
          themes: [1],
          difficulties: [],
          nbQuestions: 10,
          scoreEachRound: false,
        );

        expect(result.ok, isFalse);
        expect(result.message, contains('difficultés'));
      });

      test('accepte nbQuestions = 5', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
          auth: true,
        )).thenAnswer((_) async => ApiResponse.ok({}, statusCode: 200));

        final result = await service.updateSettings(
          themes: [1],
          difficulties: [1],
          nbQuestions: 5,
          scoreEachRound: false,
        );

        expect(result.ok, isTrue);
      });

      test('accepte nbQuestions = 20', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
          auth: true,
        )).thenAnswer((_) async => ApiResponse.ok({}, statusCode: 200));

        final result = await service.updateSettings(
          themes: [1],
          difficulties: [1],
          nbQuestions: 20,
          scoreEachRound: false,
        );

        expect(result.ok, isTrue);
      });

      test('retourne erreur si nbQuestions invalide', () async {
        final result = await service.updateSettings(
          themes: [1],
          difficulties: [1],
          nbQuestions: 7,
          scoreEachRound: false,
        );

        expect(result.ok, isFalse);
        expect(result.message, contains('5, 10, 15 ou 20'));
      });

      test('retourne erreur si échec serveur', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
          auth: true,
        )).thenAnswer((_) async => ApiResponse.err(
              message: 'Non autorisé',
              statusCode: 403,
            ));

        final result = await service.updateSettings(
          themes: [1],
          difficulties: [1],
          nbQuestions: 10,
          scoreEachRound: false,
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Non autorisé'));
      });

      test('utilise message par défaut en cas d\'erreur', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
          auth: true,
        )).thenAnswer((_) async => ApiResponse.err(statusCode: 500));

        final result = await service.updateSettings(
          themes: [1],
          difficulties: [1],
          nbQuestions: 10,
          scoreEachRound: false,
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Erreur lors de la mise à jour des paramètres'));
      });

      test('gère exception pendant la requête', () async {
        when(mockApiClient.postJson(
          any,
          body: anyNamed('body'),
          auth: true,
        )).thenThrow(Exception('Timeout'));

        final result = await service.updateSettings(
          themes: [1],
          difficulties: [1],
          nbQuestions: 10,
          scoreEachRound: false,
        );

        expect(result.ok, isFalse);
        expect(result.message, contains('Erreur'));
      });
    });
  });
}
