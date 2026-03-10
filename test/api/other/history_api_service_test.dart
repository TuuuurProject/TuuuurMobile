import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/other/history_api_service.dart';
import 'package:tuuuur_flutter/api/other/history_models.dart';

import 'history_api_service_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('HistoryPartyTypeDto', () {
    test('fromJson crée une instance correcte', () {
      final json = {
        'id': 1,
        'label': 'Solo',
      };

      final dto = HistoryPartyTypeDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.label, equals('Solo'));
    });

    test('fromJson gère les valeurs nulles', () {
      final json = <String, dynamic>{};

      final dto = HistoryPartyTypeDto.fromJson(json);

      expect(dto.id, isNull);
      expect(dto.label, equals(''));
    });
  });

  group('HistoryDifficultyDto', () {
    test('fromJson crée une instance correcte', () {
      final json = {
        'id': 2,
        'label': 'Moyen',
      };

      final dto = HistoryDifficultyDto.fromJson(json);

      expect(dto.id, equals(2));
      expect(dto.label, equals('Moyen'));
    });
  });

  group('HistoryThemeDto', () {
    test('fromJson crée une instance avec icon', () {
      final json = {
        'id': 5,
        'label': 'Musique',
        'icon': 'fa-music',
      };

      final dto = HistoryThemeDto.fromJson(json);

      expect(dto.id, equals(5));
      expect(dto.label, equals('Musique'));
      expect(dto.icon, equals('fa-music'));
    });

    test('fromJson gère icon optionnel', () {
      final json = {
        'id': 3,
        'label': 'Sport',
      };

      final dto = HistoryThemeDto.fromJson(json);

      expect(dto.icon, isNull);
    });
  });

  group('HistoryPartyDifficultyDto', () {
    test('fromJson avec difficulty imbriquée', () {
      final json = {
        'id': 1,
        'difficulty': {
          'id': 2,
          'label': 'Difficile',
        },
      };

      final dto = HistoryPartyDifficultyDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.difficulty, isNotNull);
      expect(dto.difficulty!.id, equals(2));
      expect(dto.difficulty!.label, equals('Difficile'));
    });

    test('fromJson sans difficulty', () {
      final json = {'id': 1};

      final dto = HistoryPartyDifficultyDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.difficulty, isNull);
    });
  });

  group('HistoryPartyThemeDto', () {
    test('fromJson avec theme imbriqué', () {
      final json = {
        'id': 1,
        'theme': {
          'id': 5,
          'label': 'Géographie',
          'icon': 'fa-globe',
        },
      };

      final dto = HistoryPartyThemeDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.theme, isNotNull);
      expect(dto.theme!.id, equals(5));
      expect(dto.theme!.label, equals('Géographie'));
    });
  });

  group('HistoryMatchDto', () {
    test('fromJson crée une instance complète', () {
      final json = {
        'id': 'uuid-123',
        'dt': '2024-01-15T10:30:00Z',
        'finish': true,
        'nbQuestions': 10,
        'score': 8,
        'time': 120,
        'percent': 80,
        'partyType': {
          'id': 1,
          'label': 'Solo',
        },
        'partyDifficulty': [
          {
            'id': 1,
            'difficulty': {'id': 2, 'label': 'Moyen'},
          },
        ],
        'partyTheme': [
          {
            'id': 1,
            'theme': {'id': 3, 'label': 'Histoire'},
          },
        ],
      };

      final dto = HistoryMatchDto.fromJson(json);

      expect(dto.id, equals('uuid-123'));
      expect(dto.dt, isNotNull);
      expect(dto.finish, isTrue);
      expect(dto.nbQuestions, equals(10));
      expect(dto.score, equals(8));
      expect(dto.time, equals(120));
      expect(dto.percent, equals(80));
      expect(dto.partyType, isNotNull);
      expect(dto.partyDifficulty.length, equals(1));
      expect(dto.partyTheme.length, equals(1));
    });

    test('fromJson gère les clés alternatives pour les champs', () {
      final json = {
        'id': 'test-id',
        'date': '2024-01-01T00:00:00Z',
        'finished': true,
        'duration': 60,
        'successPercent': 90,
      };

      final dto = HistoryMatchDto.fromJson(json);

      expect(dto.dt, isNotNull);
      expect(dto.finish, isTrue);
      expect(dto.time, equals(60));
      expect(dto.percent, equals(90));
    });

    test('fromJson gère elapsedSeconds comme alternative à time', () {
      final json = {
        'id': 'test',
        'finish': true,
        'elapsedSeconds': 45,
      };

      final dto = HistoryMatchDto.fromJson(json);

      expect(dto.time, equals(45));
    });

    test('fromJson gère isFinished comme alternative à finish', () {
      final json = {
        'id': 'test',
        'isFinished': true,
      };

      final dto = HistoryMatchDto.fromJson(json);

      expect(dto.finish, isTrue);
    });

    test('fromJson gère listes vides', () {
      final json = {
        'id': 'empty-test',
        'finish': false,
        'partyDifficulty': [],
        'partyTheme': [],
      };

      final dto = HistoryMatchDto.fromJson(json);

      expect(dto.partyDifficulty, isEmpty);
      expect(dto.partyTheme, isEmpty);
    });
  });

  group('HistoryPageDto', () {
    test('fromJson crée une page avec items', () {
      final json = {
        'history': [
          {
            'id': 'match-1',
            'finish': true,
            'partyDifficulty': [],
            'partyTheme': [],
          },
          {
            'id': 'match-2',
            'finish': false,
            'partyDifficulty': [],
            'partyTheme': [],
          },
        ],
        'totalParties': 50,
        'page': 1,
        'totalPages': 5,
      };

      final dto = HistoryPageDto.fromJson(json);

      expect(dto.items.length, equals(2));
      expect(dto.totalCount, equals(50));
      expect(dto.currentPage, equals(1));
      expect(dto.totalPages, equals(5));
    });

    test('fromJson gère data wrapper', () {
      final json = {
        'data': {
          'history': [
            {
              'id': 'test',
              'finish': true,
              'partyDifficulty': [],
              'partyTheme': [],
            },
          ],
          'totalParties': 1,
        },
      };

      final dto = HistoryPageDto.fromJson(json);

      expect(dto.items.length, equals(1));
      expect(dto.totalCount, equals(1));
    });

    test('fromJson gère clé "items" comme alternative', () {
      final json = {
        'items': [
          {
            'id': 'test',
            'finish': true,
            'partyDifficulty': [],
            'partyTheme': [],
          },
        ],
      };

      final dto = HistoryPageDto.fromJson(json);

      expect(dto.items.length, equals(1));
    });

    test('fromJson crée liste vide si pas de données', () {
      final json = <String, dynamic>{};

      final dto = HistoryPageDto.fromJson(json);

      expect(dto.items, isEmpty);
      expect(dto.totalCount, isNull);
    });
  });

  group('HistoryApi', () {
    late MockApiClient mockApiClient;
    late HistoryApi historyApi;

    setUp(() {
      mockApiClient = MockApiClient();
      historyApi = HistoryApi(mockApiClient);
    });

    group('getHistory', () {
      test('retourne la page d\'historique avec paramètres par défaut', () async {
        final responseData = {
          'history': [
            {
              'id': 'match-1',
              'finish': true,
              'partyDifficulty': [],
              'partyTheme': [],
            },
          ],
          'totalParties': 20,
        };

        when(mockApiClient.getJson('/api/v1/history?page=1&size=10', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await historyApi.getHistory();

        expect(result.ok, isTrue);
        expect(result.data!.items.length, equals(1));
        expect(result.data!.totalCount, equals(20));
      });

      test('accepte les paramètres page et size personnalisés', () async {
        final responseData = {
          'history': [],
          'page': 2,
        };

        when(mockApiClient.getJson('/api/v1/history?page=2&size=20', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await historyApi.getHistory(page: 2, size: 20);

        expect(result.ok, isTrue);
        verify(mockApiClient.getJson('/api/v1/history?page=2&size=20', auth: true))
            .called(1);
      });

      test('retourne une erreur si la requête échoue', () async {
        when(mockApiClient.getJson(any, auth: true))
            .thenAnswer((_) async => ApiResponse.err(
                  message: 'Non autorisé',
                  statusCode: 401,
                ));

        final result = await historyApi.getHistory();

        expect(result.ok, isFalse);
        expect(result.message, equals('Non autorisé'));
        expect(result.statusCode, equals(401));
      });
    });

    group('getPartyDetail', () {
      test('retourne les détails d\'une partie', () async {
        final responseData = {
          'id': 'party-123',
          'finish': true,
          'nbQuestions': 15,
          'score': 12,
          'questions': [],
          'users': [],
        };

        when(mockApiClient.getJson('/api/v1/history/party-123', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await historyApi.getPartyDetail('party-123');

        expect(result.ok, isTrue);
        expect(result.data, isNotNull);
      });

      test('retourne une erreur si la partie n\'existe pas', () async {
        when(mockApiClient.getJson('/api/v1/history/not-found', auth: true))
            .thenAnswer((_) async => ApiResponse.err(
                  message: 'Partie non trouvée',
                  statusCode: 404,
                ));

        final result = await historyApi.getPartyDetail('not-found');

        expect(result.ok, isFalse);
        expect(result.statusCode, equals(404));
      });
    });

    group('getSoloPartyDetail', () {
      test('retourne les détails d\'une partie solo', () async {
        final responseData = {
          'id': 'solo-456',
          'finish': true,
          'score': 8,
          'questions': [],
          'users': [],
        };

        when(mockApiClient.getJson('/api/v1/solo/solo-456', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await historyApi.getSoloPartyDetail('solo-456');

        expect(result.ok, isTrue);
        expect(result.data, isNotNull);
      });

      test('retourne une erreur en cas d\'échec', () async {
        when(mockApiClient.getJson('/api/v1/solo/error', auth: true))
            .thenAnswer((_) async => ApiResponse.err(
                  message: 'Erreur serveur',
                  statusCode: 500,
                ));

        final result = await historyApi.getSoloPartyDetail('error');

        expect(result.ok, isFalse);
        expect(result.message, equals('Erreur serveur'));
      });
    });
  });
}
