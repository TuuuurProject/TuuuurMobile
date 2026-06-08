import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/solo/solo_api_service.dart';
import 'package:tuuuur_flutter/api/solo/solo_models.dart';

import 'solo_api_service_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('SoloAnswerDto', () {
    test('fromJson crée une instance correcte', () {
      final json = {'id': 1, 'idQuestion': 10, 'value': 'Paris', 'valid': true};

      final dto = SoloAnswerDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.questionId, equals(10));
      expect(dto.value, equals('Paris'));
      expect(dto.valid, isTrue);
    });

    test('fromJson gère les valeurs nulles', () {
      final json = {'value': 'Test'};

      final dto = SoloAnswerDto.fromJson(json);

      expect(dto.value, equals('Test'));
      expect(dto.id, isNull);
      expect(dto.questionId, isNull);
      expect(dto.valid, isNull);
    });
  });

  group('SoloQuestionDto', () {
    test('fromJson crée une question avec réponses', () {
      final json = {
        'id': 1,
        'label': 'Quelle est la capitale de la France?',
        'idDifficulty': 2,
        'answer': [
          {'id': 1, 'value': 'Paris', 'valid': true},
          {'id': 2, 'value': 'Londres', 'valid': false},
        ],
      };

      final dto = SoloQuestionDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.label, equals('Quelle est la capitale de la France?'));
      expect(dto.difficultyId, equals(2));
      expect(dto.answers.length, equals(2));
      expect(dto.answers[0].value, equals('Paris'));
    });

    test('fromJson gère difficulté dans objet imbriqué', () {
      final json = {
        'id': 1,
        'label': 'Question test',
        'difficulty': {'id': 3, 'label': 'Difficile'},
        'answer': [],
      };

      final dto = SoloQuestionDto.fromJson(json);

      expect(dto.difficultyId, equals(3));
      expect(dto.difficultyLabel, equals('Difficile'));
    });

    test('fromJson crée liste vide si pas de réponses', () {
      final json = {'id': 1, 'label': 'Test'};

      final dto = SoloQuestionDto.fromJson(json);

      expect(dto.answers, isEmpty);
    });
  });

  group('SoloUserPartyQuestionDto', () {
    test('fromJson crée une instance correcte', () {
      final json = {
        'id': 1,
        'idPartyQuestion': 10,
        'idUser': 5,
        'dtPresentedAt': '2024-01-01T10:00:00Z',
        'dtAnsweredAt': '2024-01-01T10:01:00Z',
        'idAnswer': 3,
        'correct': true,
        'score': 100,
      };

      final dto = SoloUserPartyQuestionDto.fromJson(json);

      expect(dto.id, equals(1));
      expect(dto.partyQuestionId, equals(10));
      expect(dto.userId, equals(5));
      expect(dto.answerId, equals(3));
      expect(dto.correct, isTrue);
      expect(dto.score, equals(100));
      expect(dto.isAnswered, isTrue);
    });

    test('isAnswered retourne true si dtAnsweredAt existe', () {
      final dto = SoloUserPartyQuestionDto.fromJson({
        'dtAnsweredAt': '2024-01-01T10:00:00Z',
      });

      expect(dto.isAnswered, isTrue);
    });

    test('isAnswered retourne true si answerId existe', () {
      final dto = SoloUserPartyQuestionDto.fromJson({'idAnswer': 5});

      expect(dto.isAnswered, isTrue);
    });

    test('isAnswered retourne false si non répondu', () {
      final dto = SoloUserPartyQuestionDto.fromJson({});

      expect(dto.isAnswered, isFalse);
    });
  });

  group('SoloCreateResult', () {
    test('crée un résultat avec partyId', () {
      const result = SoloCreateResult(partyId: 'uuid-123');

      expect(result.partyId, equals('uuid-123'));
    });
  });

  group('SoloApi', () {
    late MockApiClient mockApiClient;
    late SoloApi soloApi;

    setUp(() {
      mockApiClient = MockApiClient();
      soloApi = SoloApi(mockApiClient);
    });

    group('createSolo', () {
      test('retourne succès avec partyId', () async {
        final responseData = {'data': 'party-uuid-123'};

        when(
          mockApiClient.postJson(
            any,
            body: anyNamed('body'),
            auth: anyNamed('auth'),
          ),
        ).thenAnswer(
          (_) async => ApiResponse.ok(responseData, statusCode: 201),
        );

        final result = await soloApi.createSolo(
          themeIds: [1],
          difficultyIds: [2],
          nbQuestions: 10,
        );

        expect(result.ok, isTrue);
        expect(result.data?.partyId, equals('party-uuid-123'));
      });

      test('envoie le bon body', () async {
        when(
          mockApiClient.postJson(
            any,
            body: anyNamed('body'),
            auth: anyNamed('auth'),
          ),
        ).thenAnswer(
          (_) async => ApiResponse.ok({'data': 'id'}, statusCode: 200),
        );

        await soloApi.createSolo(
          themeIds: [1, 3],
          difficultyIds: [2],
          nbQuestions: 15,
        );

        final captured = verify(
          mockApiClient.postJson(
            captureAny,
            body: captureAnyNamed('body'),
            auth: captureAnyNamed('auth'),
          ),
        ).captured;

        final body = captured[1] as Map<String, dynamic>;
        expect(body['themes'], equals([1, 3]));
        expect(body['difficulties'], equals([2]));
        expect(body['nbQuestions'], equals(15));
      });

      test('retourne erreur en cas d\'échec', () async {
        when(
          mockApiClient.postJson(
            any,
            body: anyNamed('body'),
            auth: anyNamed('auth'),
          ),
        ).thenAnswer(
          (_) async =>
              ApiResponse.err(message: 'Invalid request', statusCode: 400),
        );

        final result = await soloApi.createSolo(
          themeIds: [1],
          difficultyIds: [2],
          nbQuestions: 10,
        );

        expect(result.ok, isFalse);
        expect(result.message, equals('Invalid request'));
      });

      test('lit le partyId depuis le champ id', () async {
        when(
          mockApiClient.postJson(any, body: anyNamed('body'), auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.ok({'id': 'id-field'}, statusCode: 201),
        );

        final result = await soloApi.createSolo(
          themeIds: [1],
          difficultyIds: [2],
          nbQuestions: 10,
        );

        expect(result.ok, isTrue);
        expect(result.data?.partyId, equals('id-field'));
      });

      test('lit le partyId depuis le champ partyId', () async {
        when(
          mockApiClient.postJson(any, body: anyNamed('body'), auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.ok({'partyId': 'party-field'}, statusCode: 201),
        );

        final result = await soloApi.createSolo(
          themeIds: [1],
          difficultyIds: [2],
          nbQuestions: 10,
        );

        expect(result.data?.partyId, equals('party-field'));
      });

      test('retourne erreur si party id manquant dans la réponse', () async {
        when(
          mockApiClient.postJson(any, body: anyNamed('body'), auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.ok(<String, dynamic>{}, statusCode: 200),
        );

        final result = await soloApi.createSolo(
          themeIds: [1],
          difficultyIds: [2],
          nbQuestions: 10,
        );

        expect(result.ok, isFalse);
        expect(result.message, contains('missing party id'));
      });
    });

    group('getSolo', () {
      test('retourne la partie en cas de succès', () async {
        when(
          mockApiClient.getJson(any, auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.ok(
            {'id': 'party-1', 'finish': false, 'score': 10},
            statusCode: 200,
          ),
        );

        final result = await soloApi.getSolo(partyId: 'party-1');

        expect(result.ok, isTrue);
        expect(result.data?.id, equals('party-1'));
        expect(result.data?.score, equals(10));
      });

      test('appelle le bon endpoint', () async {
        when(
          mockApiClient.getJson(any, auth: anyNamed('auth')),
        ).thenAnswer((_) async => ApiResponse.ok({'id': 'x'}, statusCode: 200));

        await soloApi.getSolo(partyId: 'abc');

        final captured = verify(
          mockApiClient.getJson(captureAny, auth: captureAnyNamed('auth')),
        ).captured;

        expect(captured[0], equals('/api/v1/solo/abc'));
        expect(captured[1], isTrue);
      });

      test('retourne erreur en cas d\'échec', () async {
        when(
          mockApiClient.getJson(any, auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.err(message: 'Not found', statusCode: 404),
        );

        final result = await soloApi.getSolo(partyId: 'party-1');

        expect(result.ok, isFalse);
        expect(result.statusCode, equals(404));
      });
    });

    group('answerSolo', () {
      test('retourne la partie mise à jour en cas de succès', () async {
        when(
          mockApiClient.postJson(any, body: anyNamed('body'), auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.ok(
            {'id': 'party-1', 'score': 20},
            statusCode: 200,
          ),
        );

        final result = await soloApi.answerSolo(partyId: 'party-1', answerId: 3);

        expect(result.ok, isTrue);
        expect(result.data?.score, equals(20));
      });

      test('envoie answerId dans le body', () async {
        when(
          mockApiClient.postJson(any, body: anyNamed('body'), auth: anyNamed('auth')),
        ).thenAnswer((_) async => ApiResponse.ok({'id': 'p'}, statusCode: 200));

        await soloApi.answerSolo(partyId: 'p', answerId: 42);

        final captured = verify(
          mockApiClient.postJson(
            captureAny,
            body: captureAnyNamed('body'),
            auth: captureAnyNamed('auth'),
          ),
        ).captured;

        expect(captured[0], equals('/api/v1/solo/p'));
        final body = captured[1] as Map<String, dynamic>;
        expect(body['answerId'], equals(42));
      });

      test('retourne erreur en cas d\'échec', () async {
        when(
          mockApiClient.postJson(any, body: anyNamed('body'), auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.err(message: 'Bad answer', statusCode: 400),
        );

        final result = await soloApi.answerSolo(partyId: 'p', answerId: 1);

        expect(result.ok, isFalse);
        expect(result.message, equals('Bad answer'));
      });
    });

    group('getHistory', () {
      test('retourne la liste des parties', () async {
        when(
          mockApiClient.getJson(any, auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.ok({
            'data': [
              {'id': 'party-1', 'score': 10},
              {'id': 'party-2', 'score': 20},
            ],
          }, statusCode: 200),
        );

        final result = await soloApi.getHistory();

        expect(result.ok, isTrue);
        expect(result.data?.length, equals(2));
        expect(result.data?[0].id, equals('party-1'));
        expect(result.data?[1].score, equals(20));
      });

      test('retourne liste vide si data n\'est pas une liste', () async {
        when(
          mockApiClient.getJson(any, auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.ok({'data': 'pas une liste'}, statusCode: 200),
        );

        final result = await soloApi.getHistory();

        expect(result.ok, isTrue);
        expect(result.data, isEmpty);
      });

      test('retourne liste vide si data absent', () async {
        when(
          mockApiClient.getJson(any, auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.ok(<String, dynamic>{}, statusCode: 200),
        );

        final result = await soloApi.getHistory();

        expect(result.ok, isTrue);
        expect(result.data, isEmpty);
      });

      test('retourne erreur en cas d\'échec', () async {
        when(
          mockApiClient.getJson(any, auth: anyNamed('auth')),
        ).thenAnswer(
          (_) async => ApiResponse.err(message: 'Server error', statusCode: 500),
        );

        final result = await soloApi.getHistory();

        expect(result.ok, isFalse);
        expect(result.statusCode, equals(500));
      });
    });
  });
}
