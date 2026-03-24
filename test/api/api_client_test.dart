import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:tuuuur_flutter/api/api_client.dart';

import 'api_client_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('ApiResponse', () {
    test('factory ok crée une réponse réussie', () {
      final response = ApiResponse.ok({'key': 'value'}, statusCode: 200);

      expect(response.ok, isTrue);
      expect(response.data, equals({'key': 'value'}));
      expect(response.statusCode, equals(200));
      expect(response.message, isNull);
    });

    test('factory err crée une réponse d\'erreur', () {
      final response = ApiResponse<Map<String, dynamic>>.err(
        message: 'Error occurred',
        statusCode: 404,
      );

      expect(response.ok, isFalse);
      expect(response.data, isNull);
      expect(response.statusCode, equals(404));
      expect(response.message, equals('Error occurred'));
    });
  });

  group('ApiClient', () {
    late MockClient mockHttpClient;
    late ApiClient apiClient;

    setUp(() {
      mockHttpClient = MockClient();
      apiClient = ApiClient(
        httpClient: mockHttpClient,
        baseUrl: 'https://api.test.com',
      );
    });

    group('getJson', () {
      test('retourne succès avec données valides', () async {
        final responseBody = jsonEncode({'result': 'success'});
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        final result = await apiClient.getJson('/test');

        expect(result.ok, isTrue);
        expect(result.data, equals({'result': 'success'}));
        expect(result.statusCode, equals(200));
      });

      test('retourne erreur avec code 404', () async {
        final responseBody = jsonEncode({'error': 'Not found'});
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response(responseBody, 404));

        final result = await apiClient.getJson('/notfound');

        expect(result.ok, isFalse);
        expect(result.statusCode, equals(404));
        expect(result.message, isNotNull);
      });

      test('retourne erreur en cas d\'exception réseau', () async {
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenThrow(Exception('Network error'));

        final result = await apiClient.getJson('/test');

        expect(result.ok, isFalse);
        expect(result.message, contains('Impossible de contacter le serveur'));
      });

      test('ajoute les bons headers', () async {
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await apiClient.getJson('/test', headers: {'X-Custom': 'value'});

        final captured = verify(
          mockHttpClient.get(captureAny, headers: captureAnyNamed('headers')),
        ).captured;

        final headers = captured[1] as Map<String, String>;
        expect(headers['Accept'], equals('application/json'));
        expect(headers['X-Custom'], equals('value'));
      });
    });

    group('postJson', () {
      test('retourne succès avec données valides', () async {
        final responseBody = jsonEncode({'id': 123});
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 201));

        final result = await apiClient.postJson(
          '/create',
          body: {'name': 'test'},
        );

        expect(result.ok, isTrue);
        expect(result.data, equals({'id': 123}));
        expect(result.statusCode, equals(201));
      });

      test('envoie le body JSON correctement', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await apiClient.postJson('/test', body: {'key': 'value'});

        final captured = verify(
          mockHttpClient.post(
            captureAny,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        final body = captured[2] as String;
        expect(body, equals('{"key":"value"}'));
      });

      test('gère les erreurs 400', () async {
        final responseBody = jsonEncode({
          'title': 'Bad Request',
          'detail': 'Invalid data',
        });
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 400));

        final result = await apiClient.postJson('/test', body: {});

        expect(result.ok, isFalse);
        expect(result.statusCode, equals(400));
        expect(result.message, contains('Bad Request'));
      });
    });

    group('putJson', () {
      test('retourne succès avec données valides', () async {
        final responseBody = jsonEncode({'updated': true});
        when(
          mockHttpClient.put(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        final result = await apiClient.putJson('/update', body: {'id': 1});

        expect(result.ok, isTrue);
        expect(result.data, equals({'updated': true}));
      });

      test('gère les erreurs de conflit 409', () async {
        when(
          mockHttpClient.put(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', 409));

        final result = await apiClient.putJson('/update', body: {});

        expect(result.ok, isFalse);
        expect(result.statusCode, equals(409));
        expect(result.message, contains('Conflit'));
      });
    });

    group('delete', () {
      test('retourne succès', () async {
        when(
          mockHttpClient.delete(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{}', 204));

        final result = await apiClient.delete('/delete/123');

        expect(result.ok, isTrue);
        expect(result.statusCode, equals(204));
      });

      test('gère les erreurs 404', () async {
        when(
          mockHttpClient.delete(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{"error": "Not found"}', 404));

        final result = await apiClient.delete('/delete/999');

        expect(result.ok, isFalse);
        expect(result.statusCode, equals(404));
      });
    });

    group('_humanizeError', () {
      test('extrait les erreurs avec title et detail', () async {
        final responseBody = jsonEncode({
          'title': 'Validation Error',
          'detail': 'Email is required',
        });
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response(responseBody, 422));

        final result = await apiClient.getJson('/test');

        expect(result.ok, isFalse);
        expect(result.message, contains('Validation Error'));
        expect(result.message, contains('Email is required'));
      });

      test('extrait les erreurs depuis un tableau', () async {
        final responseBody = jsonEncode({
          'errors': [
            {'description': 'First error'},
            {'description': 'Second error'},
          ],
        });
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response(responseBody, 400));

        final result = await apiClient.getJson('/test');

        expect(result.ok, isFalse);
        expect(result.message, equals('First error'));
      });

      test('utilise le message direct si disponible', () async {
        final responseBody = jsonEncode({'message': 'Custom error message'});
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response(responseBody, 500));

        final result = await apiClient.getJson('/test');

        expect(result.ok, isFalse);
        expect(result.message, equals('Custom error message'));
      });
    });

    group('URI construction', () {
      test('normalise les chemins avec slash', () async {
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await apiClient.getJson('test');

        final captured = verify(
          mockHttpClient.get(captureAny, headers: anyNamed('headers')),
        ).captured;

        final uri = captured[0] as Uri;
        expect(uri.toString(), equals('https://api.test.com/test'));
      });

      test('supprime les trailing slashes de la base URL', () async {
        final client = ApiClient(
          httpClient: mockHttpClient,
          baseUrl: 'https://api.test.com///',
        );

        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await client.getJson('/test');

        final captured = verify(
          mockHttpClient.get(captureAny, headers: anyNamed('headers')),
        ).captured;

        final uri = captured[0] as Uri;
        expect(uri.toString(), equals('https://api.test.com/test'));
      });
    });

    group('timeout', () {
      test('utilise le timeout par défaut de 10 secondes', () async {
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await apiClient.getJson('/test');

        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('permet de spécifier un timeout personnalisé', () async {
        when(
          mockHttpClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await apiClient.getJson('/test', timeout: Duration(seconds: 5));

        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(1);
      });
    });

    test('dispose ferme le client HTTP', () {
      apiClient.dispose();
      verify(mockHttpClient.close()).called(1);
    });
  });
}
