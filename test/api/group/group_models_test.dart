import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/group/group_models.dart' hide Theme;
import 'package:tuuuur_flutter/api/group/group_models.dart'
    show
        Theme,
        Answer,
        Difficulty,
        GroupParty,
        GroupQuestion,
        GroupUser,
        JoinGroupRequest,
        GroupSettingsRequest,
        PartyDifficulty,
        PartyTheme,
        PartyUser,
        Question,
        QuestionHistory,
        UserAnswered,
        UserScore;

void main() {
  // ─────────────────────────────────── GroupUser ────────────────────────────
  group('GroupUser', () {
    test('fromJson construit l\'objet avec toutes les propriétés', () {
      final json = {
        'id': 'u-1',
        'nickName': 'Alice',
        'email': 'alice@test.com',
        'avatar': 'https://avatar/alice.png',
        'isAdmin': true,
        'isNew': false,
      };
      final user = GroupUser.fromJson(json);
      expect(user.id, 'u-1');
      expect(user.nickName, 'Alice');
      expect(user.email, 'alice@test.com');
      expect(user.avatar, 'https://avatar/alice.png');
      expect(user.isAdmin, isTrue);
      expect(user.isNew, isFalse);
    });

    test(
      'fromJson utilise les valeurs par défaut pour les champs nullables',
      () {
        final json = {'id': 'u-2', 'nickName': 'Bob'};
        final user = GroupUser.fromJson(json);
        expect(user.id, 'u-2');
        expect(user.email, isNull);
        expect(user.avatar, isNull);
        expect(user.isAdmin, isFalse);
        expect(user.isNew, isFalse);
      },
    );

    test('toJson produit le bon Map', () {
      const user = GroupUser(
        id: 'u-3',
        nickName: 'Carol',
        email: 'carol@test.com',
        isAdmin: true,
        isNew: true,
      );
      final json = user.toJson();
      expect(json['id'], 'u-3');
      expect(json['nickName'], 'Carol');
      expect(json['email'], 'carol@test.com');
      expect(json['isAdmin'], isTrue);
      expect(json['isNew'], isTrue);
    });

    test('toString donne une représentation lisible', () {
      const user = GroupUser(id: 'u-4', nickName: 'Dave');
      expect(user.toString(), contains('Dave'));
      expect(user.toString(), contains('u-4'));
    });

    test('round-trip fromJson→toJson preserve les données', () {
      final json = {
        'id': 'u-rt',
        'nickName': 'RoundTrip',
        'email': 'rt@test.com',
        'avatar': null,
        'isAdmin': false,
        'isNew': true,
      };
      final user = GroupUser.fromJson(json);
      final back = user.toJson();
      expect(back['id'], json['id']);
      expect(back['nickName'], json['nickName']);
      expect(back['isNew'], json['isNew']);
    });
  });

  // ─────────────────────────────────── Difficulty ───────────────────────────
  group('Difficulty', () {
    test('fromJson construit avec id et label', () {
      final d = Difficulty.fromJson({'id': 1, 'label': 'Facile'});
      expect(d.id, 1);
      expect(d.label, 'Facile');
    });

    test('toJson produit le bon Map', () {
      const d = Difficulty(id: 2, label: 'Moyen');
      final json = d.toJson();
      expect(json['id'], 2);
      expect(json['label'], 'Moyen');
    });
  });

  // ─────────────────────────────────── Theme ────────────────────────────────
  group('Theme', () {
    test('fromJson construit avec id et label', () {
      final t = Theme.fromJson({'id': 5, 'label': 'Géographie'});
      expect(t.id, 5);
      expect(t.label, 'Géographie');
    });

    test('toJson produit le bon Map', () {
      const t = Theme(id: 3, label: 'Histoire');
      final json = t.toJson();
      expect(json['id'], 3);
      expect(json['label'], 'Histoire');
    });
  });

  // ─────────────────────────────────── PartyUser ────────────────────────────
  group('PartyUser', () {
    test('fromJson avec user imbriqué', () {
      final json = {
        'idUser': 'u-1',
        'idParty': 'p-1',
        'user': {
          'id': 'u-1',
          'nickName': 'Alice',
          'isAdmin': false,
          'isNew': false,
        },
      };
      final pu = PartyUser.fromJson(json);
      expect(pu.idUser, 'u-1');
      expect(pu.idParty, 'p-1');
      expect(pu.user?.nickName, 'Alice');
    });

    test('fromJson sans user renvoie null pour user', () {
      final json = {'idUser': 'u-2', 'idParty': 'p-2'};
      final pu = PartyUser.fromJson(json);
      expect(pu.user, isNull);
    });

    test('toJson produit le bon Map', () {
      final pu = PartyUser(
        idUser: 'u-3',
        idParty: 'p-3',
        user: const GroupUser(id: 'u-3', nickName: 'Eve'),
      );
      final json = pu.toJson();
      expect(json['idUser'], 'u-3');
      expect(json['idParty'], 'p-3');
      expect(json['user'], isNotNull);
    });
  });

  // ─────────────────────────────────── PartyTheme ───────────────────────────
  group('PartyTheme', () {
    test('fromJson construit correctement', () {
      final json = {
        'idTheme': 7,
        'theme': {'id': 7, 'label': 'Science'},
      };
      final pt = PartyTheme.fromJson(json);
      expect(pt.idTheme, 7);
      expect(pt.theme.label, 'Science');
    });

    test('toJson produit le bon Map', () {
      final pt = PartyTheme(
        idTheme: 1,
        theme: const Theme(id: 1, label: 'Général'),
      );
      final json = pt.toJson();
      expect(json['idTheme'], 1);
      expect((json['theme'] as Map)['label'], 'Général');
    });
  });

  // ─────────────────────────────────── PartyDifficulty ─────────────────────
  group('PartyDifficulty', () {
    test('fromJson construit correctement', () {
      final json = {
        'idDifficulty': 3,
        'difficulty': {'id': 3, 'label': 'Difficile'},
      };
      final pd = PartyDifficulty.fromJson(json);
      expect(pd.idDifficulty, 3);
      expect(pd.difficulty.label, 'Difficile');
    });

    test('toJson produit le bon Map', () {
      final pd = PartyDifficulty(
        idDifficulty: 2,
        difficulty: const Difficulty(id: 2, label: 'Moyen'),
      );
      final json = pd.toJson();
      expect(json['idDifficulty'], 2);
      expect((json['difficulty'] as Map)['id'], 2);
    });
  });

  // ─────────────────────────────────── Answer ───────────────────────────────
  group('Answer', () {
    test('fromJson avec valid=true', () {
      final a = Answer.fromJson({
        'id': 11,
        'idQuestion': 1,
        'value': 'Paris',
        'valid': true,
      });
      expect(a.id, 11);
      expect(a.value, 'Paris');
      expect(a.valid, isTrue);
    });

    test('fromJson avec valid=null (pas encore révélé)', () {
      final a = Answer.fromJson({
        'id': 12,
        'idQuestion': 1,
        'value': 'Lyon',
        'valid': null,
      });
      expect(a.valid, isNull);
    });

    test('toJson produit le bon Map', () {
      const a = Answer(id: 13, idQuestion: 2, value: 'Berlin', valid: false);
      final json = a.toJson();
      expect(json['id'], 13);
      expect(json['value'], 'Berlin');
      expect(json['valid'], isFalse);
    });
  });

  // ─────────────────────────────────── Question ─────────────────────────────
  group('Question', () {
    test('fromJson construit avec réponses imbriquées', () {
      final json = {
        'id': 1,
        'label': 'Capitale de France ?',
        'idDifficulty': 2,
        'difficulty': {'id': 2, 'label': 'Moyen'},
        'answer': [
          {'id': 11, 'idQuestion': 1, 'value': 'Paris', 'valid': true},
          {'id': 12, 'idQuestion': 1, 'value': 'Lyon', 'valid': false},
        ],
      };
      final q = Question.fromJson(json);
      expect(q.id, 1);
      expect(q.label, 'Capitale de France ?');
      expect(q.answer.length, 2);
      expect(q.answer.first.value, 'Paris');
    });

    test('fromJson avec liste de réponses vide', () {
      final json = {
        'id': 2,
        'label': 'Question sans réponses ?',
        'idDifficulty': 1,
        'difficulty': {'id': 1, 'label': 'Facile'},
        'answer': <dynamic>[],
      };
      final q = Question.fromJson(json);
      expect(q.answer, isEmpty);
    });

    test('toJson inclut la liste des réponses', () {
      final q = Question(
        id: 1,
        label: 'Test ?',
        idDifficulty: 1,
        difficulty: const Difficulty(id: 1, label: 'Facile'),
        answer: [const Answer(id: 1, idQuestion: 1, value: 'A', valid: true)],
      );
      final json = q.toJson();
      expect(json['id'], 1);
      final answers = json['answer'] as List;
      expect(answers.length, 1);
    });
  });

  // ─────────────────────────────────── GroupQuestion ────────────────────────
  group('GroupQuestion', () {
    test('fromJson construit correctement', () {
      final json = {
        'currentIndex': 3,
        'score': 15,
        'question': {
          'id': 5,
          'label': 'Question 5 ?',
          'idDifficulty': 2,
          'difficulty': {'id': 2, 'label': 'Moyen'},
          'answer': <dynamic>[],
        },
      };
      final gq = GroupQuestion.fromJson(json);
      expect(gq.currentIndex, 3);
      expect(gq.score, 15);
      expect(gq.question.id, 5);
    });

    test('toJson produit le bon Map', () {
      final gq = GroupQuestion(
        currentIndex: 1,
        score: 10,
        question: Question(
          id: 1,
          label: 'Q1 ?',
          idDifficulty: 1,
          difficulty: const Difficulty(id: 1, label: 'Facile'),
          answer: const [],
        ),
      );
      final json = gq.toJson();
      expect(json['currentIndex'], 1);
      expect(json['score'], 10);
      expect((json['question'] as Map)['id'], 1);
    });
  });

  // ─────────────────────────────────── UserScore ────────────────────────────
  group('UserScore', () {
    test('fromJson construit correctement', () {
      final json = {
        'score': 250,
        'user': {
          'id': 'u-5',
          'nickName': 'Champion',
          'isAdmin': false,
          'isNew': false,
        },
      };
      final us = UserScore.fromJson(json);
      expect(us.score, 250);
      expect(us.user.nickName, 'Champion');
    });

    test('toJson produit le bon Map', () {
      final us = UserScore(
        score: 100,
        user: const GroupUser(id: 'u-6', nickName: 'Player'),
      );
      final json = us.toJson();
      expect(json['score'], 100);
      expect((json['user'] as Map)['nickName'], 'Player');
    });

    test('toString contient le nom et le score', () {
      final us = UserScore(
        score: 42,
        user: const GroupUser(id: 'u-7', nickName: 'Tester'),
      );
      expect(us.toString(), contains('Tester'));
      expect(us.toString(), contains('42'));
    });
  });

  // ─────────────────────────────────── QuestionHistory ─────────────────────
  group('QuestionHistory', () {
    Question _makeQuestion({int correctId = 11, int wrongId = 12}) => Question(
      id: 1,
      label: 'Capitale de France ?',
      idDifficulty: 2,
      difficulty: const Difficulty(id: 2, label: 'Moyen'),
      answer: [
        Answer(id: correctId, idQuestion: 1, value: 'Paris', valid: true),
        Answer(id: wrongId, idQuestion: 1, value: 'Lyon', valid: false),
      ],
    );

    GroupQuestion _makeGroupQuestion({int correctId = 11, int wrongId = 12}) =>
        GroupQuestion(
          currentIndex: 1,
          score: 10,
          question: _makeQuestion(correctId: correctId, wrongId: wrongId),
        );

    test(
      'userAnswer retourne la bonne réponse quand userAnswerId est fourni',
      () {
        final qh = QuestionHistory(
          groupQuestion: _makeGroupQuestion(),
          userAnswerId: 11,
          wasCorrect: true,
          scoreGained: 10,
        );
        expect(qh.userAnswer?.value, 'Paris');
      },
    );

    test('userAnswer retourne null quand userAnswerId est null', () {
      final qh = QuestionHistory(
        groupQuestion: _makeGroupQuestion(),
        userAnswerId: null,
        wasCorrect: false,
        scoreGained: 0,
      );
      expect(qh.userAnswer, isNull);
    });

    test('userAnswer retourne null quand userAnswerId est introuvable', () {
      final qh = QuestionHistory(
        groupQuestion: _makeGroupQuestion(),
        userAnswerId: 999,
        wasCorrect: false,
        scoreGained: 0,
      );
      expect(qh.userAnswer, isNull);
    });

    test('correctAnswer retourne la bonne réponse', () {
      final qh = QuestionHistory(
        groupQuestion: _makeGroupQuestion(correctId: 11),
        userAnswerId: 12,
        wasCorrect: false,
        scoreGained: 0,
      );
      expect(qh.correctAnswer?.id, 11);
    });

    test('correctAnswer retourne null quand aucune réponse valid=true', () {
      final gq = GroupQuestion(
        currentIndex: 1,
        score: 10,
        question: Question(
          id: 2,
          label: 'Sans bonne réponse ?',
          idDifficulty: 1,
          difficulty: const Difficulty(id: 1, label: 'Facile'),
          answer: [
            const Answer(id: 21, idQuestion: 2, value: 'A', valid: null),
            const Answer(id: 22, idQuestion: 2, value: 'B', valid: null),
          ],
        ),
      );
      final qh = QuestionHistory(
        groupQuestion: gq,
        userAnswerId: null,
        wasCorrect: false,
        scoreGained: 0,
      );
      expect(qh.correctAnswer, isNull);
    });
  });

  // ─────────────────────────────────── GroupSettingsRequest ─────────────────
  group('GroupSettingsRequest', () {
    test('toJson produit le bon Map', () {
      const req = GroupSettingsRequest(
        themes: [1, 3],
        difficulties: [2],
        nbQuestions: 15,
        scoreEachRound: true,
      );
      final json = req.toJson();
      expect(json['themes'], [1, 3]);
      expect(json['difficulties'], [2]);
      expect(json['nbQuestions'], 15);
      expect(json['scoreEachRound'], isTrue);
    });
  });

  // ─────────────────────────────────── JoinGroupRequest ─────────────────────
  group('JoinGroupRequest', () {
    test('toJson produit le bon Map', () {
      const req = JoinGroupRequest(code: 'ABC123');
      final json = req.toJson();
      expect(json['code'], 'ABC123');
    });
  });

  // ─────────────────────────────────── UserAnswered ─────────────────────────
  group('UserAnswered', () {
    test('fromJson construit correctement', () {
      final json = {
        'correct': true,
        'user': {
          'id': 'u-8',
          'nickName': 'FastPlayer',
          'isAdmin': false,
          'isNew': false,
        },
      };
      final ua = UserAnswered.fromJson(json);
      expect(ua.correct, isTrue);
      expect(ua.user.nickName, 'FastPlayer');
    });

    test('fromJson avec correct=false', () {
      final json = {
        'correct': false,
        'user': {
          'id': 'u-9',
          'nickName': 'SlowPlayer',
          'isAdmin': false,
          'isNew': false,
        },
      };
      final ua = UserAnswered.fromJson(json);
      expect(ua.correct, isFalse);
    });

    test('toJson produit le bon Map', () {
      final ua = UserAnswered(
        correct: true,
        user: const GroupUser(id: 'u-10', nickName: 'Fast'),
      );
      final json = ua.toJson();
      expect(json['correct'], isTrue);
      expect((json['user'] as Map)['id'], 'u-10');
    });

    test('toString contient le nom et le statut', () {
      final ua = UserAnswered(
        correct: false,
        user: const GroupUser(id: 'u-11', nickName: 'Slow'),
      );
      expect(ua.toString(), contains('Slow'));
    });
  });

  // ─────────────────────────────────── GroupParty ────────────────────────────
  group('GroupParty', () {
    Map<String, dynamic> _makePartyJson({
      String id = 'p-1',
      String code = '123456',
      bool inProgress = false,
      bool finish = false,
      bool active = true,
    }) => {
      'id': id,
      'code': code,
      'nbQuestions': 10,
      'inProgress': inProgress,
      'scoreEachRound': false,
      'idPartyType': 2,
      'idUserHost': 'host-1',
      'active': active,
      'finish': finish,
      'dt': '2024-06-01T10:00:00Z',
      'partyUsers': [
        {
          'idUser': 'host-1',
          'idParty': id,
          'user': {
            'id': 'host-1',
            'nickName': 'Host',
            'isAdmin': true,
            'isNew': false,
          },
        },
      ],
      'partyTheme': [
        {
          'idTheme': 1,
          'theme': {'id': 1, 'label': 'Général'},
        },
      ],
      'partyDifficulty': [
        {
          'idDifficulty': 2,
          'difficulty': {'id': 2, 'label': 'Moyen'},
        },
      ],
      'percent': 75.0,
      'score': 120,
      'time': 300,
    };

    test('fromJson construit l\'objet complet', () {
      final party = GroupParty.fromJson(_makePartyJson());
      expect(party.id, 'p-1');
      expect(party.code, '123456');
      expect(party.nbQuestions, 10);
      expect(party.inProgress, isFalse);
      expect(party.finish, isFalse);
      expect(party.partyUsers.length, 1);
      expect(party.partyTheme.length, 1);
      expect(party.partyDifficulty.length, 1);
      expect(party.percent, 75.0);
      expect(party.score, 120);
      expect(party.time, 300);
    });

    test('fromJson avec listes vides', () {
      final json = {
        'id': 'p-min',
        'code': 'MIN',
        'nbQuestions': 5,
        'inProgress': false,
        'scoreEachRound': false,
        'idPartyType': 2,
        'idUserHost': 'host-1',
        'active': true,
        'finish': false,
        'dt': '2024-01-01T00:00:00Z',
      };
      final party = GroupParty.fromJson(json);
      expect(party.partyUsers, isEmpty);
      expect(party.partyTheme, isEmpty);
      expect(party.partyDifficulty, isEmpty);
      expect(party.percent, 0.0);
      expect(party.score, 0);
    });

    test('toJson produit le bon Map', () {
      final party = GroupParty.fromJson(_makePartyJson());
      final json = party.toJson();
      expect(json['id'], 'p-1');
      expect(json['code'], '123456');
      expect((json['partyUsers'] as List).length, 1);
      expect((json['partyTheme'] as List).length, 1);
    });

    test('copyWith remplace seulement les champs spécifiés', () {
      final party = GroupParty.fromJson(_makePartyJson());
      final updated = party.copyWith(code: 'NEW123', finish: true);
      expect(updated.id, party.id);
      expect(updated.code, 'NEW123');
      expect(updated.finish, isTrue);
      expect(updated.inProgress, party.inProgress);
    });

    test('copyWith sans argument retourne un objet identique', () {
      final party = GroupParty.fromJson(_makePartyJson());
      final copy = party.copyWith();
      expect(copy.id, party.id);
      expect(copy.code, party.code);
      expect(copy.nbQuestions, party.nbQuestions);
    });

    test('toString contient les informations clés', () {
      final party = GroupParty.fromJson(_makePartyJson());
      final str = party.toString();
      expect(str, contains('p-1'));
      expect(str, contains('123456'));
    });
  });
}
