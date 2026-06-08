import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/solo/solo_models.dart';

void main() {
  group('SoloThemeDto', () {
    test('fromJson complet', () {
      final dto = SoloThemeDto.fromJson({
        'id': 3,
        'label': 'Histoire',
        'icon': 'book',
      });

      expect(dto.id, 3);
      expect(dto.label, 'Histoire');
      expect(dto.icon, 'book');
    });

    test('fromJson minimal applique les valeurs par défaut', () {
      final dto = SoloThemeDto.fromJson({});

      expect(dto.id, isNull);
      expect(dto.label, '');
      expect(dto.icon, isNull);
    });
  });

  group('SoloQuestionThemeDto', () {
    test('fromJson avec thème imbriqué', () {
      final dto = SoloQuestionThemeDto.fromJson({
        'id': 1,
        'theme': {'id': 2, 'label': 'Sport'},
      });

      expect(dto.id, 1);
      expect(dto.theme, isNotNull);
      expect(dto.theme!.label, 'Sport');
    });

    test('fromJson sans thème laisse theme null', () {
      final dto = SoloQuestionThemeDto.fromJson({'id': 1});

      expect(dto.id, 1);
      expect(dto.theme, isNull);
    });
  });

  group('SoloPartyThemeDto', () {
    test('fromJson avec thème imbriqué', () {
      final dto = SoloPartyThemeDto.fromJson({
        'id': 9,
        'theme': {'id': 4, 'label': 'Géographie'},
      });

      expect(dto.id, 9);
      expect(dto.theme?.label, 'Géographie');
    });

    test('fromJson sans thème laisse theme null', () {
      final dto = SoloPartyThemeDto.fromJson({'id': 9});

      expect(dto.theme, isNull);
    });
  });

  group('SoloQuestionDto', () {
    test('fromJson parse questionTheme', () {
      final dto = SoloQuestionDto.fromJson({
        'id': 1,
        'label': 'Q ?',
        'answer': [],
        'questionTheme': [
          {
            'id': 1,
            'theme': {'id': 1, 'label': 'Général'},
          },
          {
            'id': 2,
            'theme': {'id': 2, 'label': 'Cinéma'},
          },
        ],
      });

      expect(dto.questionTheme.length, 2);
      expect(dto.questionTheme[1].theme?.label, 'Cinéma');
    });

    test('fromJson sans questionTheme retourne liste vide', () {
      final dto = SoloQuestionDto.fromJson({'id': 1, 'label': 'Q'});

      expect(dto.questionTheme, isEmpty);
    });

    test('fromJson difficulté via idDifficulty seul', () {
      final dto = SoloQuestionDto.fromJson({
        'id': 1,
        'label': 'Q',
        'idDifficulty': 4,
      });

      expect(dto.difficultyId, 4);
      expect(dto.difficultyLabel, isNull);
    });
  });

  group('SoloUserPartyQuestionDto', () {
    test('fromJson complet avec answersOrder', () {
      final dto = SoloUserPartyQuestionDto.fromJson({
        'id': 1,
        'idPartyQuestion': 2,
        'idUser': 3,
        'dtPresentedAt': '2024-01-01T10:00:00Z',
        'dtAnsweredAt': '2024-01-01T10:01:00Z',
        'idAnswer': 7,
        'correct': false,
        'score': 0,
        'answersOrder': 'a,b,c',
      });

      expect(dto.id, 1);
      expect(dto.partyQuestionId, 2);
      expect(dto.userId, 3);
      expect(dto.dtPresentedAt, isNotNull);
      expect(dto.answerId, 7);
      expect(dto.correct, isFalse);
      expect(dto.score, 0);
      expect(dto.answersOrderRaw, 'a,b,c');
      expect(dto.isAnswered, isTrue);
    });

    test('isAnswered false quand ni dtAnsweredAt ni answerId', () {
      final dto = SoloUserPartyQuestionDto.fromJson({'id': 1});
      expect(dto.isAnswered, isFalse);
    });
  });

  group('SoloPartyQuestionDto', () {
    test('fromJson complet avec question et userPartyQuestion', () {
      final dto = SoloPartyQuestionDto.fromJson({
        'id': 1,
        'idQuestion': 10,
        'idParty': 'party-uuid',
        'order': 2,
        'question': {
          'id': 10,
          'label': 'Capitale ?',
          'answer': [
            {'id': 1, 'value': 'Paris', 'valid': true},
          ],
        },
        'userPartyQuestion': {'idAnswer': 1, 'correct': true, 'score': 10},
      });

      expect(dto.id, 1);
      expect(dto.questionId, 10);
      expect(dto.partyId, 'party-uuid');
      expect(dto.order, 2);
      expect(dto.question?.label, 'Capitale ?');
      expect(dto.userAnswer?.answerId, 1);
      expect(dto.isAnswered, isTrue);
    });

    test('fromJson sans question/userPartyQuestion', () {
      final dto = SoloPartyQuestionDto.fromJson({'id': 1, 'order': 1});

      expect(dto.question, isNull);
      expect(dto.userAnswer, isNull);
      expect(dto.isAnswered, isFalse);
    });
  });

  group('SoloPartyDto', () {
    Map<String, dynamic> partyQuestionJson({
      required int order,
      required bool answered,
      String label = 'Q',
    }) {
      return {
        'id': order,
        'idQuestion': order * 10,
        'order': order,
        'question': {
          'id': order * 10,
          'label': label,
          'answer': [
            {'id': order * 10 + 1, 'value': 'A', 'valid': true},
          ],
        },
        if (answered)
          'userPartyQuestion': {
            'idAnswer': order * 10 + 1,
            'correct': true,
            'score': 10,
          },
      };
    }

    test('fromJson complet', () {
      final dto = SoloPartyDto.fromJson({
        'id': 'party-1',
        'dt': '2024-01-01T10:00:00Z',
        'code': 'ABC',
        'idPartyType': 1,
        'idUserHost': 5,
        'active': true,
        'finish': false,
        'score': 42,
        'nbQuestions': 3,
        'partyQuestions': [
          partyQuestionJson(order: 1, answered: true),
          partyQuestionJson(order: 2, answered: false),
        ],
        'partyTheme': [
          {
            'id': 1,
            'theme': {'id': 1, 'label': 'Général'},
          },
        ],
      });

      expect(dto.id, 'party-1');
      expect(dto.dt, isNotNull);
      expect(dto.code, 'ABC');
      expect(dto.idPartyType, 1);
      expect(dto.idUserHost, 5);
      expect(dto.active, isTrue);
      expect(dto.score, 42);
      expect(dto.nbQuestions, 3);
      expect(dto.partyQuestions.length, 2);
      expect(dto.partyTheme.length, 1);
    });

    test('isFinished reflète finish', () {
      final finie = SoloPartyDto.fromJson({'id': 'p', 'finish': true});
      final enCours = SoloPartyDto.fromJson({'id': 'p', 'finish': false});
      final nulle = SoloPartyDto.fromJson({'id': 'p'});

      expect(finie.isFinished, isTrue);
      expect(enCours.isFinished, isFalse);
      expect(nulle.isFinished, isFalse);
    });

    test('answeredCount compte les questions répondues', () {
      final dto = SoloPartyDto.fromJson({
        'id': 'p',
        'partyQuestions': [
          partyQuestionJson(order: 1, answered: true),
          partyQuestionJson(order: 2, answered: true),
          partyQuestionJson(order: 3, answered: false),
        ],
      });

      expect(dto.answeredCount, 2);
    });

    test('currentEntry retourne la première non répondue', () {
      final dto = SoloPartyDto.fromJson({
        'id': 'p',
        'partyQuestions': [
          partyQuestionJson(order: 1, answered: true, label: 'Q1'),
          partyQuestionJson(order: 2, answered: false, label: 'Q2'),
        ],
      });

      expect(dto.currentEntry?.order, 2);
      expect(dto.currentQuestion?.label, 'Q2');
    });

    test('currentEntry retourne la dernière si toutes répondues', () {
      final dto = SoloPartyDto.fromJson({
        'id': 'p',
        'partyQuestions': [
          partyQuestionJson(order: 1, answered: true, label: 'Q1'),
          partyQuestionJson(order: 2, answered: true, label: 'Q2'),
        ],
      });

      expect(dto.currentEntry?.order, 2);
      expect(dto.currentQuestion?.label, 'Q2');
    });

    test('currentEntry/currentQuestion null si aucune question', () {
      final dto = SoloPartyDto.fromJson({'id': 'p', 'partyQuestions': []});

      expect(dto.currentEntry, isNull);
      expect(dto.currentQuestion, isNull);
      expect(dto.answeredCount, 0);
    });
  });
}
