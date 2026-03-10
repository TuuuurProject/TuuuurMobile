import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/other/difficulty_api_service.dart';
import 'package:tuuuur_flutter/api/other/difficulty_models.dart';
import 'package:tuuuur_flutter/api/other/theme_api_service.dart';
import 'package:tuuuur_flutter/api/other/theme_models.dart';

import 'services_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('DifficultyDto', () {
    test('fromJson crée une instance valide', () {
      final json = {
        'id': 1,
        'label': 'Facile',
      };

      final dto = DifficultyDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.label, equals('Facile'));
    });

    test('fromJson gère plusieurs formats de clés', () {
      final json = {
        'difficultyId': 2,
        'name': 'Moyen',
      };

      final dto = DifficultyDto.fromJson(json);

      expect(dto.id, equals(2));
      expect(dto.label, equals('Moyen'));
    });

    test('fromJson utilise id comme label par défaut', () {
      final json = {'id': 3};

      final dto = DifficultyDto.fromJson(json);

      expect(dto.label, equals('3'));
    });

    test('fromJson parse les id en string', () {
      final json = {
        'id': '5',
        'label': 'Difficile',
      };

      final dto = DifficultyDto.fromJson(json);

      expect(dto.id, equals(5));
    });
  });

  group('DifficultyApi', () {
    late MockApiClient mockApiClient;
    late DifficultyApi difficultyApi;

    setUp(() {
      mockApiClient = MockApiClient();
      difficultyApi = DifficultyApi(mockApiClient);
    });

    test('getDifficulties retourne une liste triée', () async {
      final responseData = {
        'data': [
          {'id': 3, 'label': 'Difficile'},
          {'id': 1, 'label': 'Facile'},
          {'id': 2, 'label': 'Moyen'},
        ],
      };

      when(mockApiClient.getJson(
        any,
        auth: anyNamed('auth'),
      )).thenAnswer(
        (_) async => ApiResponse.ok(responseData, statusCode: 200),
      );

      final result = await difficultyApi.getDifficulties();

      expect(result.ok, isTrue);
      expect(result.data?.length, equals(3));
      expect(result.data?[0].label, equals('Facile'));
      expect(result.data?[1].label, equals('Moyen'));
      expect(result.data?[2].label, equals('Difficile'));
    });

    test('getDifficulties gère différentes clés d\'enveloppe', () async {
      final responseData = {
        'difficulties': [
          {'id': 1, 'label': 'Test'},
        ],
      };

      when(mockApiClient.getJson(
        any,
        auth: anyNamed('auth'),
      )).thenAnswer(
        (_) async => ApiResponse.ok(responseData, statusCode: 200),
      );

      final result = await difficultyApi.getDifficulties();

      expect(result.ok, isTrue);
      expect(result.data?.length, equals(1));
    });

    test('getDifficulties retourne une liste vide si pas de tableau', () async {
      final responseData = {'message': 'no data'};

      when(mockApiClient.getJson(
        any,
        auth: anyNamed('auth'),
      )).thenAnswer(
        (_) async => ApiResponse.ok(responseData, statusCode: 200),
      );

      final result = await difficultyApi.getDifficulties();

      expect(result.ok, isTrue);
      expect(result.data, isEmpty);
    });

    test('getDifficulties propage les erreurs', () async {
      when(mockApiClient.getJson(
        any,
        auth: anyNamed('auth'),
      )).thenAnswer(
        (_) async => ApiResponse.err(
          message: 'Server error',
          statusCode: 500,
        ),
      );

      final result = await difficultyApi.getDifficulties();

      expect(result.ok, isFalse);
      expect(result.message, equals('Server error'));
      expect(result.statusCode, equals(500));
    });
  });

  group('ThemeItemDto', () {
    test('fromJson crée une instance valide', () {
      final json = {
        'id': 1,
        'icon': 'gamepad',
        'label': 'Général',
      };

      final dto = ThemeItemDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.icon, equals('gamepad'));
      expect(dto.label, equals('Général'));
    });

    test('fromJson parse id depuis string', () {
      final json = {
        'id': '42',
        'icon': 'music',
        'label': 'Musique',
      };

      final dto = ThemeItemDto.fromJson(json);

      expect(dto.id, equals(42));
    });

    test('fromJson gère les valeurs manquantes', () {
      final json = <String, dynamic>{};

      final dto = ThemeItemDto.fromJson(json);

      expect(dto.id, isNull);
      expect(dto.icon, isEmpty);
      expect(dto.label, isEmpty);
    });
  });

  group('ThemeDto', () {
    test('fromJson crée une instance complète', () {
      final json = {
        'id': 1,
        'code': 'general',
        'name': 'Culture Générale',
        'description': 'Questions variées',
        'icon': 'fa-book',
      };

      final dto = ThemeDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.key, equals('general'));
      expect(dto.name, equals('Culture Générale'));
      expect(dto.description, equals('Questions variées'));
      expect(dto.icon, equals('fa-book'));
    });

    test('fromJson gère plusieurs clés alternatives', () {
      final json = {
        'themeId': 2,
        'slug': 'science',
        'title': 'Sciences',
      };

      final dto = ThemeDto.fromJson(json);

      expect(dto.id, equals(2));
      expect(dto.key, equals('science'));
      expect(dto.name, equals('Sciences'));
    });

    test('fromJson utilise l\'id comme key par défaut', () {
      final json = {
        'id': 5,
        'label': 'Sport',
      };

      final dto = ThemeDto.fromJson(json);

      expect(dto.key, equals('5'));
      expect(dto.name, equals('Sport'));
    });

    test('fromJson utilise key comme name par défaut', () {
      final json = {'key': 'test'};

      final dto = ThemeDto.fromJson(json);

      expect(dto.name, equals('test'));
    });
  });

  group('ThemeApi', () {
    late MockApiClient mockApiClient;
    late ThemeApi themeApi;

    setUp(() {
      mockApiClient = MockApiClient();
      themeApi = ThemeApi(mockApiClient);
    });

    test('getThemes retourne une liste de thèmes', () async {
      final responseData = {
        'data': [
          {
            'id': 1,
            'code': 'general',
            'name': 'Général',
          },
          {
            'id': 2,
            'code': 'sport',
            'name': 'Sport',
          },
        ],
      };

      when(mockApiClient.getJson(
        any,
        auth: anyNamed('auth'),
      )).thenAnswer(
        (_) async => ApiResponse.ok(responseData, statusCode: 200),
      );

      final result = await themeApi.getThemes();

      expect(result.ok, isTrue);
      expect(result.data?.length, equals(2));
      expect(result.data?[0].key, equals('general'));
      expect(result.data?[1].key, equals('sport'));
    });

    test('getThemes gère clé "themes"', () async {
      final responseData = {
        'themes': [
          {'id': 1, 'key': 'test', 'name': 'Test'},
        ],
      };

      when(mockApiClient.getJson(
        any,
        auth: anyNamed('auth'),
      )).thenAnswer(
        (_) async => ApiResponse.ok(responseData, statusCode: 200),
      );

      final result = await themeApi.getThemes();

      expect(result.ok, isTrue);
      expect(result.data?.length, equals(1));
    });

    test('getThemes retourne liste vide si pas de tableau', () async {
      final responseData = {'status': 'ok'};

      when(mockApiClient.getJson(
        any,
        auth: anyNamed('auth'),
      )).thenAnswer(
        (_) async => ApiResponse.ok(responseData, statusCode: 200),
      );

      final result = await themeApi.getThemes();

      expect(result.ok, isTrue);
      expect(result.data, isEmpty);
    });

    test('getThemes propage les erreurs', () async {
      when(mockApiClient.getJson(
        any,
        auth: anyNamed('auth'),
      )).thenAnswer(
        (_) async => ApiResponse.err(
          message: 'Not found',
          statusCode: 404,
        ),
      );

      final result = await themeApi.getThemes();

      expect(result.ok, isFalse);
      expect(result.message, equals('Not found'));
    });


  });
}
