import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/other/theme_api_service.dart';
import 'package:tuuuur_flutter/api/other/theme_models.dart';

import 'theme_api_service_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('ThemeItemDto', () {
    test('fromJson crée une instance correcte', () {
      final json = {
        'id': 1,
        'icon': 'fa-music',
        'label': 'Musique',
      };

      final dto = ThemeItemDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.icon, equals('fa-music'));
      expect(dto.label, equals('Musique'));
    });

    test('fromJson parse l\'id depuis String', () {
      final json = {
        'id': '42',
        'icon': 'test',
        'label': 'Test',
      };

      final dto = ThemeItemDto.fromJson(json);

      expect(dto.id, equals(42));
    });

    test('fromJson gère les valeurs manquantes', () {
      final json = <String, dynamic>{};

      final dto = ThemeItemDto.fromJson(json);

      expect(dto.id, isNull);
      expect(dto.icon, equals(''));
      expect(dto.label, equals(''));
    });
  });

  group('ThemeDto', () {
    test('fromJson crée une instance complète', () {
      final json = {
        'id': 1,
        'code': 'music',
        'name': 'Musique',
        'description': 'Questions sur la musique',
        'icon': 'fa-music',
      };

      final dto = ThemeDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.key, equals('music'));
      expect(dto.name, equals('Musique'));
      expect(dto.description, equals('Questions sur la musique'));
      expect(dto.icon, equals('fa-music'));
    });

    test('fromJson gère themeId comme clé alternative pour id', () {
      final json = {
        'themeId': 5,
        'code': 'history',
        'name': 'Histoire',
      };

      final dto = ThemeDto.fromJson(json);

      expect(dto.id, equals(5));
    });

    test('fromJson gère key et slug comme alternatives à code', () {
      final json1 = {'id': 1, 'key': 'geography', 'name': 'Géo'};
      final dto1 = ThemeDto.fromJson(json1);
      expect(dto1.key, equals('geography'));

      final json2 = {'id': 2, 'slug': 'science', 'name': 'Science'};
      final dto2 = ThemeDto.fromJson(json2);
      expect(dto2.key, equals('science'));
    });

    test('fromJson gère label et title comme alternatives à name', () {
      final json1 = {'id': 1, 'code': 'sport', 'label': 'Sport'};
      final dto1 = ThemeDto.fromJson(json1);
      expect(dto1.name, equals('Sport'));

      final json2 = {'id': 2, 'code': 'art', 'title': 'Art'};
      final dto2 = ThemeDto.fromJson(json2);
      expect(dto2.name, equals('Art'));
    });

    test('fromJson gère details comme alternative à description', () {
      final json = {
        'id': 1,
        'code': 'cinema',
        'name': 'Cinéma',
        'details': 'Films et acteurs',
      };

      final dto = ThemeDto.fromJson(json);

      expect(dto.description, equals('Films et acteurs'));
    });

    test('fromJson gère faIcon et iconName comme alternatives à icon', () {
      final json1 = {'id': 1, 'code': 'test', 'name': 'Test', 'faIcon': 'fa-test'};
      final dto1 = ThemeDto.fromJson(json1);
      expect(dto1.icon, equals('fa-test'));

      final json2 = {'id': 2, 'code': 'test2', 'name': 'Test2', 'iconName': 'icon-test'};
      final dto2 = ThemeDto.fromJson(json2);
      expect(dto2.icon, equals('icon-test'));
    });

    test('fromJson utilise id comme code par défaut', () {
      final json = {
        'id': 99,
        'name': 'Theme',
      };

      final dto = ThemeDto.fromJson(json);

      expect(dto.key, equals('99'));
    });

    test('fromJson utilise code comme name par défaut', () {
      final json = {
        'id': 1,
        'code': 'default',
      };

      final dto = ThemeDto.fromJson(json);

      expect(dto.name, equals('default'));
    });

    test('fromJson gère les valeurs nulles', () {
      final json = <String, dynamic>{};

      final dto = ThemeDto.fromJson(json);

      expect(dto.id, isNull);
      expect(dto.key, equals(''));
      expect(dto.name, equals(''));
      expect(dto.description, isNull);
      expect(dto.icon, isNull);
    });
  });

  group('ThemeApi', () {
    late MockApiClient mockApiClient;
    late ThemeApi themeApi;

    setUp(() {
      mockApiClient = MockApiClient();
      themeApi = ThemeApi(mockApiClient);
    });

    group('getThemes', () {
      test('retourne la liste des thèmes', () async {
        final responseData = {
          'data': [
            {'id': 1, 'code': 'music', 'name': 'Musique'},
            {'id': 2, 'code': 'sport', 'name': 'Sport'},
          ],
        };

        when(mockApiClient.getJson('/api/v1/theme', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await themeApi.getThemes();

        expect(result.ok, isTrue);
        expect(result.data!.length, equals(2));
        expect(result.data![0].key, equals('music'));
        expect(result.data![1].key, equals('sport'));
      });

      test('gère la clé "items" comme alternative', () async {
        final responseData = {
          'items': [
            {'id': 1, 'code': 'test', 'name': 'Test'},
          ],
        };

        when(mockApiClient.getJson('/api/v1/theme', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await themeApi.getThemes();

        expect(result.ok, isTrue);
        expect(result.data!.length, equals(1));
      });

      test('gère la clé "themes" comme alternative', () async {
        final responseData = {
          'themes': [
            {'id': 1, 'code': 'test', 'name': 'Test'},
          ],
        };

        when(mockApiClient.getJson('/api/v1/theme', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await themeApi.getThemes();

        expect(result.ok, isTrue);
        expect(result.data!.length, equals(1));
      });

      test('retourne une liste vide si pas de données', () async {
        final responseData = <String, dynamic>{};

        when(mockApiClient.getJson('/api/v1/theme', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await themeApi.getThemes();

        expect(result.ok, isTrue);
        expect(result.data!, isEmpty);
      });

      test('retourne une erreur si la requête échoue', () async {
        when(mockApiClient.getJson('/api/v1/theme', auth: true))
            .thenAnswer((_) async => ApiResponse.err(
                  message: 'Erreur serveur',
                  statusCode: 500,
                ));

        final result = await themeApi.getThemes();

        expect(result.ok, isFalse);
        expect(result.message, equals('Erreur serveur'));
        expect(result.statusCode, equals(500));
      });

      test('filtre les éléments qui ne sont pas des Map', () async {
        final responseData = {
          'data': [
            {'id': 1, 'code': 'valid', 'name': 'Valid'},
            'invalid',
            null,
            {'id': 2, 'code': 'also-valid', 'name': 'Also Valid'},
          ],
        };

        when(mockApiClient.getJson('/api/v1/theme', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await themeApi.getThemes();

        expect(result.ok, isTrue);
        expect(result.data!.length, equals(2));
      });

      test('gère un objet data imbriqué', () async {
        final responseData = {
          'value': [
            {'id': 1, 'code': 'nested', 'name': 'Nested Test'},
          ],
        };

        when(mockApiClient.getJson('/api/v1/theme', auth: true))
            .thenAnswer((_) async => ApiResponse.ok(responseData, statusCode: 200));

        final result = await themeApi.getThemes();

        expect(result.ok, isTrue);
        expect(result.data!.length, equals(1));
        expect(result.data![0].key, equals('nested'));
      });
    });
  });
}
