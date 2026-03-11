import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/other/difficulty_api_service.dart';
import 'package:tuuuur_flutter/api/other/difficulty_models.dart';

import 'difficulty_api_service_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('DifficultyDto', () {
    test('fromJson crée une instance avec id et label', () {
      final json = {
        'id': 1,
        'label': 'Facile',
      };

      final dto = DifficultyDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.label, equals('Facile'));
    });

    test('fromJson gère difficultyId comme clé alternative', () {
      final json = {
        'difficultyId': 2,
        'label': 'Moyen',
      };

      final dto = DifficultyDto.fromJson(json);

      expect(dto.id, equals(2));
      expect(dto.label, equals('Moyen'));
    });

    test('fromJson gère name et title comme alternatives à label', () {
      final json1 = {'id': 1, 'name': 'Difficile'};
      final dto1 = DifficultyDto.fromJson(json1);
      expect(dto1.label, equals('Difficile'));

      final json2 = {'id': 2, 'title': 'Expert'};
      final dto2 = DifficultyDto.fromJson(json2);
      expect(dto2.label, equals('Expert'));
    });

    test('fromJson utilise id comme label par défaut', () {
      final json = {'id': 3};

      final dto = DifficultyDto.fromJson(json);

      expect(dto.id, equals(3));
      expect(dto.label, equals('3'));
    });

    test('fromJson gère les valeurs nulles', () {
      final json = <String, dynamic>{};

      final dto = DifficultyDto.fromJson(json);

      expect(dto.id, isNull);
      expect(dto.label, equals(''));
    });
  });

  group('DifficultyApi', () {
    late MockApiClient mockApiClient;
    late DifficultyApi difficultyApi;

    setUp(() {
      mockApiClient = MockApiClient();
      difficultyApi = DifficultyApi(mockApiClient);
    });

    group('getDifficulties', () {
      test('retourne la liste des difficultés triée par id', () async {
        final responseData = {
          'data': [
            {'id': 3, 'label': 'Difficile'},
            {'id': 1, 'label': 'Facile'},
            {'id': 2, 'label': 'Moyen'},
          ],
        };

        when(mockApiClient.getJson('/api/v1/difficulty', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await difficultyApi.getDifficulties();

        expect(result.ok, isTrue);
        expect(result.data!.length, equals(3));
        expect(result.data![0].id, equals(1));
        expect(result.data![0].label, equals('Facile'));
        expect(result.data![1].id, equals(2));
        expect(result.data![2].id, equals(3));
      });

      test('gère la clé "items" comme alternative', () async {
        final responseData = {
          'items': [
            {'id': 1, 'label': 'Test'},
          ],
        };

        when(mockApiClient.getJson('/api/v1/difficulty', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await difficultyApi.getDifficulties();

        expect(result.ok, isTrue);
        expect(result.data!.length, equals(1));
      });

      test('gère la clé "difficulties" comme alternative', () async {
        final responseData = {
          'difficulties': [
            {'id': 1, 'label': 'Test'},
          ],
        };

        when(mockApiClient.getJson('/api/v1/difficulty', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await difficultyApi.getDifficulties();

        expect(result.ok, isTrue);
        expect(result.data!.length, equals(1));
      });

      test('retourne une liste vide si pas de données', () async {
        final responseData = <String, dynamic>{};

        when(mockApiClient.getJson('/api/v1/difficulty', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await difficultyApi.getDifficulties();

        expect(result.ok, isTrue);
        expect(result.data!, isEmpty);
      });

      test('retourne une erreur si la requête échoue', () async {
        when(mockApiClient.getJson('/api/v1/difficulty', auth: true))
            .thenAnswer((_) async => ApiResponse.err(
                  message: 'Erreur réseau',
                  statusCode: 500,
                ));

        final result = await difficultyApi.getDifficulties();

        expect(result.ok, isFalse);
        expect(result.message, equals('Erreur réseau'));
        expect(result.statusCode, equals(500));
      });

      test('filtre les éléments qui ne sont pas des Map', () async {
        final responseData = {
          'data': [
            {'id': 1, 'label': 'Valid'},
            'invalid',
            123,
            {'id': 2, 'label': 'Also valid'},
          ],
        };

        when(mockApiClient.getJson('/api/v1/difficulty', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await difficultyApi.getDifficulties();

        expect(result.ok, isTrue);
        expect(result.data!.length, equals(2));
      });
    });
  });
}
