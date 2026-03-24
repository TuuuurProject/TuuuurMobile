import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/other/history_models.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // HistoryPartyTypeDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryPartyTypeDto', () {
    test('fromJson parse id et label', () {
      final dto = HistoryPartyTypeDto.fromJson({'id': 1, 'label': 'Solo'});
      expect(dto.id, 1);
      expect(dto.label, 'Solo');
    });

    test('fromJson gère id null', () {
      final dto = HistoryPartyTypeDto.fromJson({'label': 'Groupe'});
      expect(dto.id, isNull);
      expect(dto.label, 'Groupe');
    });

    test('fromJson renvoie label vide si absent', () {
      final dto = HistoryPartyTypeDto.fromJson({});
      expect(dto.label, '');
    });

    test('const constructor fonctionne', () {
      const dto = HistoryPartyTypeDto(id: 2, label: 'Duel');
      expect(dto.id, 2);
      expect(dto.label, 'Duel');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryDifficultyDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryDifficultyDto', () {
    test('fromJson parse id et label', () {
      final dto = HistoryDifficultyDto.fromJson({'id': 2, 'label': 'Moyen'});
      expect(dto.id, 2);
      expect(dto.label, 'Moyen');
    });

    test('fromJson gère données manquantes', () {
      final dto = HistoryDifficultyDto.fromJson({});
      expect(dto.id, isNull);
      expect(dto.label, '');
    });

    test('const constructor fonctionne', () {
      const dto = HistoryDifficultyDto(id: 1, label: 'Facile');
      expect(dto.id, 1);
      expect(dto.label, 'Facile');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryPartyDifficultyDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryPartyDifficultyDto', () {
    test('fromJson avec difficulté imbriquée', () {
      final dto = HistoryPartyDifficultyDto.fromJson({
        'id': 10,
        'difficulty': {'id': 1, 'label': 'Facile'},
      });
      expect(dto.id, 10);
      expect(dto.difficulty?.id, 1);
      expect(dto.difficulty?.label, 'Facile');
    });

    test('fromJson sans difficulté', () {
      final dto = HistoryPartyDifficultyDto.fromJson({'id': 5});
      expect(dto.id, 5);
      expect(dto.difficulty, isNull);
    });

    test('fromJson données vides', () {
      final dto = HistoryPartyDifficultyDto.fromJson({});
      expect(dto.id, isNull);
      expect(dto.difficulty, isNull);
    });

    test('const constructor avec difficulty', () {
      const dto = HistoryPartyDifficultyDto(
        id: 1,
        difficulty: HistoryDifficultyDto(id: 2, label: 'Difficile'),
      );
      expect(dto.difficulty?.label, 'Difficile');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryThemeDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryThemeDto', () {
    test('fromJson parse tous les champs', () {
      final dto = HistoryThemeDto.fromJson({
        'id': 3,
        'label': 'Science',
        'icon': 'flask',
      });
      expect(dto.id, 3);
      expect(dto.label, 'Science');
      expect(dto.icon, 'flask');
    });

    test('fromJson sans icon', () {
      final dto = HistoryThemeDto.fromJson({'id': 1, 'label': 'Sport'});
      expect(dto.icon, isNull);
    });

    test('fromJson données vides', () {
      final dto = HistoryThemeDto.fromJson({});
      expect(dto.label, '');
      expect(dto.id, isNull);
    });

    test('const constructor fonctionne', () {
      const dto = HistoryThemeDto(id: 5, label: 'Musique', icon: 'music');
      expect(dto.icon, 'music');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryPartyThemeDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryPartyThemeDto', () {
    test('fromJson avec thème imbriqué', () {
      final dto = HistoryPartyThemeDto.fromJson({
        'id': 7,
        'theme': {'id': 2, 'label': 'Histoire', 'icon': 'building-columns'},
      });
      expect(dto.id, 7);
      expect(dto.theme?.label, 'Histoire');
      expect(dto.theme?.icon, 'building-columns');
    });

    test('fromJson sans thème', () {
      final dto = HistoryPartyThemeDto.fromJson({'id': 3});
      expect(dto.theme, isNull);
    });

    test('fromJson données vides', () {
      final dto = HistoryPartyThemeDto.fromJson({});
      expect(dto.id, isNull);
      expect(dto.theme, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryMatchDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryMatchDto', () {
    Map<String, dynamic> _fullJson() => {
      'id': 'match-abc',
      'dt': '2024-01-15T10:00:00',
      'finish': true,
      'nbQuestions': 10,
      'score': 8,
      'time': 120,
      'percent': 80,
      'partyType': {'id': 1, 'label': 'Solo'},
      'partyDifficulty': [
        {
          'id': 1,
          'difficulty': {'id': 1, 'label': 'Facile'},
        },
        {
          'id': 2,
          'difficulty': {'id': 2, 'label': 'Moyen'},
        },
      ],
      'partyTheme': [
        {
          'id': 1,
          'theme': {'id': 3, 'label': 'Sport', 'icon': 'medal'},
        },
      ],
    };

    test('fromJson parse tous les champs complets', () {
      final dto = HistoryMatchDto.fromJson(_fullJson());
      expect(dto.id, 'match-abc');
      expect(dto.finish, isTrue);
      expect(dto.nbQuestions, 10);
      expect(dto.score, 8);
      expect(dto.time, 120);
      expect(dto.percent, 80);
      expect(dto.partyType?.label, 'Solo');
      expect(dto.partyDifficulty.length, 2);
      expect(dto.partyTheme.length, 1);
      expect(dto.dt, isNotNull);
    });

    test('fromJson avec date dans le champ "date" (fallback)', () {
      final j = _fullJson()
        ..remove('dt')
        ..['date'] = '2024-06-01T08:00:00';
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.dt, isNotNull);
    });

    test('fromJson avec finish via champ "finished"', () {
      final j = _fullJson()
        ..remove('finish')
        ..['finished'] = true;
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.finish, isTrue);
    });

    test('fromJson avec finish via champ "isFinished"', () {
      final j = _fullJson()
        ..remove('finish')
        ..['isFinished'] = false;
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.finish, isFalse);
    });

    test('fromJson avec time via champ "duration"', () {
      final j = _fullJson()
        ..remove('time')
        ..['duration'] = 90;
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.time, 90);
    });

    test('fromJson avec time via champ "elapsedSeconds"', () {
      final j = _fullJson()
        ..remove('time')
        ..['elapsedSeconds'] = 75;
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.time, 75);
    });

    test('fromJson avec percent via champ "successPercent"', () {
      final j = _fullJson()
        ..remove('percent')
        ..['successPercent'] = 65;
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.percent, 65);
    });

    test('fromJson sans partyType', () {
      final j = _fullJson()..remove('partyType');
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.partyType, isNull);
    });

    test('fromJson partyDifficulty vide', () {
      final j = _fullJson()..['partyDifficulty'] = <dynamic>[];
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.partyDifficulty, isEmpty);
    });

    test('fromJson partyTheme vide', () {
      final j = _fullJson()..['partyTheme'] = <dynamic>[];
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.partyTheme, isEmpty);
    });

    test('fromJson partyDifficulty avec entrées non-map ignorées', () {
      final j = _fullJson()..['partyDifficulty'] = ['invalid', 42, null];
      final dto = HistoryMatchDto.fromJson(j);
      expect(dto.partyDifficulty, isEmpty);
    });

    test('const constructor minimal fonctionne', () {
      const dto = HistoryMatchDto(
        id: 'x',
        finish: false,
        partyDifficulty: [],
        partyTheme: [],
      );
      expect(dto.id, 'x');
      expect(dto.finish, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryPageDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryPageDto', () {
    test('fromJson avec champ "history"', () {
      final dto = HistoryPageDto.fromJson({
        'history': [
          {'id': 'm1', 'finish': true, 'partyDifficulty': [], 'partyTheme': []},
        ],
        'page': 1,
        'totalPages': 2,
        'totalParties': 15,
      });
      expect(dto.items.length, 1);
      expect(dto.items.first.id, 'm1');
      expect(dto.currentPage, 1);
      expect(dto.totalPages, 2);
      expect(dto.totalCount, 15);
    });

    test('fromJson avec champ "items" (fallback)', () {
      final dto = HistoryPageDto.fromJson({
        'items': [
          {
            'id': 'm2',
            'finish': false,
            'partyDifficulty': [],
            'partyTheme': [],
          },
        ],
        'currentPage': 2,
        'totalPages': 5,
        'parties': 50,
      });
      expect(dto.items.length, 1);
      expect(dto.currentPage, 2);
      expect(dto.totalCount, 50);
    });

    test('fromJson avec champ "data" (fallback)', () {
      final dto = HistoryPageDto.fromJson({
        'data': [
          {'id': 'm3', 'finish': true, 'partyDifficulty': [], 'partyTheme': []},
        ],
      });
      expect(dto.items.length, 1);
    });

    test('fromJson avec wrapper "data" imbriqué', () {
      final dto = HistoryPageDto.fromJson({
        'data': {
          'history': [
            {
              'id': 'm4',
              'finish': true,
              'partyDifficulty': [],
              'partyTheme': [],
            },
          ],
          'page': 3,
          'totalPages': 10,
        },
      });
      expect(dto.items.length, 1);
      expect(dto.currentPage, 3);
      expect(dto.totalPages, 10);
    });

    test('fromJson liste vide', () {
      final dto = HistoryPageDto.fromJson({
        'history': <dynamic>[],
        'page': 1,
        'totalPages': 0,
        'totalParties': 0,
      });
      expect(dto.items, isEmpty);
      expect(dto.totalCount, 0);
    });

    test('fromJson données absentes', () {
      final dto = HistoryPageDto.fromJson({});
      expect(dto.items, isEmpty);
      expect(dto.currentPage, isNull);
      expect(dto.totalPages, isNull);
    });

    test('const constructor fonctionne', () {
      const dto = HistoryPageDto(
        items: [],
        totalCount: 0,
        currentPage: 1,
        totalPages: 1,
      );
      expect(dto.items, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryAnswerDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryAnswerDto', () {
    test('fromJson parse tous les champs', () {
      final dto = HistoryAnswerDto.fromJson({
        'id': 10,
        'idQuestion': 5,
        'value': 'Paris',
        'valid': true,
      });
      expect(dto.id, 10);
      expect(dto.idQuestion, 5);
      expect(dto.value, 'Paris');
      expect(dto.valid, isTrue);
    });

    test('fromJson valid false', () {
      final dto = HistoryAnswerDto.fromJson({'value': 'Lyon', 'valid': false});
      expect(dto.valid, isFalse);
      expect(dto.value, 'Lyon');
    });

    test('fromJson données vides', () {
      final dto = HistoryAnswerDto.fromJson({});
      expect(dto.value, '');
      expect(dto.valid, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryQuestionDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryQuestionDto', () {
    test('fromJson parse label, difficulty et answers', () {
      final dto = HistoryQuestionDto.fromJson({
        'id': 1,
        'label': 'Capitale de France?',
        'idDifficulty': 2,
        'difficulty': {'id': 2, 'label': 'Moyen'},
        'answer': [
          {'id': 11, 'idQuestion': 1, 'value': 'Paris', 'valid': true},
          {'id': 12, 'idQuestion': 1, 'value': 'Lyon', 'valid': false},
        ],
      });
      expect(dto.label, 'Capitale de France?');
      expect(dto.difficulty?.label, 'Moyen');
      expect(dto.answer.length, 2);
      expect(dto.answer.first.value, 'Paris');
      expect(dto.answer.first.valid, isTrue);
    });

    test('fromJson sans difficulty ni answers', () {
      final dto = HistoryQuestionDto.fromJson({'label': 'Q?'});
      expect(dto.difficulty, isNull);
      expect(dto.answer, isEmpty);
    });

    test('fromJson answer avec entrées non-map ignorées', () {
      final dto = HistoryQuestionDto.fromJson({
        'label': 'Q?',
        'answer': ['invalid', null, 42],
      });
      expect(dto.answer, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // UserPartyQuestionDto
  // ─────────────────────────────────────────────────────────────────────────
  group('UserPartyQuestionDto', () {
    test('fromJson parse tous les champs', () {
      final dto = UserPartyQuestionDto.fromJson({
        'id': 1,
        'idPartyQuestion': 2,
        'idUser': 3,
        'dtPresentedAt': '2024-01-01T10:00:00',
        'dtAnsweredAt': '2024-01-01T10:00:05',
        'idAnswer': 11,
        'correct': true,
        'score': 15,
        'answer': {'id': 11, 'idQuestion': 1, 'value': 'Paris', 'valid': true},
      });
      expect(dto.correct, isTrue);
      expect(dto.score, 15);
      expect(dto.idAnswer, 11);
      expect(dto.answer?.value, 'Paris');
      expect(dto.dtPresentedAt, isNotNull);
      expect(dto.dtAnsweredAt, isNotNull);
    });

    test('fromJson correct false et score 0', () {
      final dto = UserPartyQuestionDto.fromJson({'correct': false});
      expect(dto.correct, isFalse);
      expect(dto.score, 0);
    });

    test('fromJson données vides', () {
      final dto = UserPartyQuestionDto.fromJson({});
      expect(dto.correct, isFalse);
      expect(dto.score, 0);
      expect(dto.answer, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryPartyQuestionDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryPartyQuestionDto', () {
    test('fromJson avec question et userPartyQuestion', () {
      final dto = HistoryPartyQuestionDto.fromJson({
        'id': 1,
        'idQuestion': 5,
        'idParty': 'party-abc',
        'order': 3,
        'question': {'id': 5, 'label': 'Capitale?', 'answer': []},
        'userPartyQuestion': {'correct': true, 'score': 20},
      });
      expect(dto.order, 3);
      expect(dto.idParty, 'party-abc');
      expect(dto.question?.label, 'Capitale?');
      expect(dto.userPartyQuestion?.correct, isTrue);
      expect(dto.userPartyQuestion?.score, 20);
    });

    test('fromJson sans question ni userPartyQuestion', () {
      final dto = HistoryPartyQuestionDto.fromJson({'order': 0});
      expect(dto.question, isNull);
      expect(dto.userPartyQuestion, isNull);
    });

    test('fromJson données vides → order vaut 0', () {
      final dto = HistoryPartyQuestionDto.fromJson({});
      expect(dto.order, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HistoryUserDto
  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryUserDto', () {
    test('fromJson parse tous les champs', () {
      final dto = HistoryUserDto.fromJson({
        'id': 42,
        'nickName': 'PlayerXYZ',
        'email': 'x@y.com',
        'avatar': 'base64data',
        'isAdmin': false,
        'isNew': true,
      });
      expect(dto.id, 42);
      expect(dto.nickName, 'PlayerXYZ');
      expect(dto.email, 'x@y.com');
      expect(dto.avatar, 'base64data');
      expect(dto.isAdmin, isFalse);
      expect(dto.isNew, isTrue);
    });

    test('fromJson isAdmin et isNew par défaut false', () {
      final dto = HistoryUserDto.fromJson({'nickName': 'Alice'});
      expect(dto.isAdmin, isFalse);
      expect(dto.isNew, isFalse);
    });

    test('fromJson données vides → nickName vide', () {
      final dto = HistoryUserDto.fromJson({});
      expect(dto.nickName, '');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PartyDetailDto
  // ─────────────────────────────────────────────────────────────────────────
  group('PartyDetailDto', () {
    Map<String, dynamic> _fullDetailJson() => {
      'id': 'party-detail-1',
      'dt': '2024-03-10T15:00:00',
      'idPartyType': 1,
      'idUserHost': 99,
      'active': true,
      'finish': false,
      'inProgress': true,
      'nbQuestions': 15,
      'percent': 60,
      'score': 9,
      'time': 200,
      'partyType': {'id': 1, 'label': 'Solo'},
      'user': {'id': 99, 'nickName': 'Host', 'isAdmin': false, 'isNew': false},
      'partyDifficulty': [
        {
          'id': 1,
          'difficulty': {'id': 1, 'label': 'Facile'},
        },
      ],
      'partyTheme': [
        {
          'id': 1,
          'theme': {'id': 2, 'label': 'Sport', 'icon': 'medal'},
        },
      ],
      'partyQuestions': [
        {
          'id': 1,
          'idQuestion': 10,
          'idParty': 'party-detail-1',
          'order': 1,
          'question': {'id': 10, 'label': 'Q1?', 'answer': []},
          'userPartyQuestion': {'correct': true, 'score': 10},
        },
      ],
    };

    test('fromJson parse tous les champs', () {
      final dto = PartyDetailDto.fromJson(_fullDetailJson());
      expect(dto.id, 'party-detail-1');
      expect(dto.active, isTrue);
      expect(dto.finish, isFalse);
      expect(dto.inProgress, isTrue);
      expect(dto.nbQuestions, 15);
      expect(dto.percent, 60);
      expect(dto.score, 9);
      expect(dto.time, 200);
      expect(dto.partyType?.label, 'Solo');
      expect(dto.user?.nickName, 'Host');
      expect(dto.partyDifficulty.length, 1);
      expect(dto.partyTheme.length, 1);
      expect(dto.partyQuestions.length, 1);
    });

    test('fromJson finish via "finished"', () {
      final j = _fullDetailJson()
        ..remove('finish')
        ..['finished'] = true;
      final dto = PartyDetailDto.fromJson(j);
      expect(dto.finish, isTrue);
    });

    test('fromJson finish via "isFinished"', () {
      final j = _fullDetailJson()
        ..remove('finish')
        ..['isFinished'] = true;
      final dto = PartyDetailDto.fromJson(j);
      expect(dto.finish, isTrue);
    });

    test('fromJson active fallback sur inProgress', () {
      final j = _fullDetailJson()
        ..remove('active')
        ..['inProgress'] = true;
      final dto = PartyDetailDto.fromJson(j);
      expect(dto.active, isTrue);
    });

    test('fromJson sans partyType, user, listes vides', () {
      final dto = PartyDetailDto.fromJson({
        'id': 'p2',
        'active': false,
        'finish': false,
        'partyDifficulty': <dynamic>[],
        'partyTheme': <dynamic>[],
        'partyQuestions': <dynamic>[],
      });
      expect(dto.partyType, isNull);
      expect(dto.user, isNull);
      expect(dto.partyDifficulty, isEmpty);
      expect(dto.partyTheme, isEmpty);
      expect(dto.partyQuestions, isEmpty);
    });

    test('fromJson données vides → active et finish false', () {
      final dto = PartyDetailDto.fromJson({});
      expect(dto.active, isFalse);
      expect(dto.finish, isFalse);
      expect(dto.id, '');
    });

    test('fromJson partyQuestions avec entrées non-map ignorées', () {
      final j = _fullDetailJson()..['partyQuestions'] = ['bad', null, 123];
      final dto = PartyDetailDto.fromJson(j);
      expect(dto.partyQuestions, isEmpty);
    });
  });
}
