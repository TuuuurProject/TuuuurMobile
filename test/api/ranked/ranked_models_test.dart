import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_models.dart';

void main() {
  group('Ranked Models Tests', () {
    test('RankedUser parsing from JSON', () {
      final json = {
        'id': '123',
        'nickName': 'TestPlayer',
        'email': 'test@test.com',
        'isAdmin': true,
        'globalElo': 1200,
      };

      final user = RankedUser.fromJson(json);

      expect(user.id, '123');
      expect(user.nickName, 'TestPlayer');
      expect(user.email, 'test@test.com');
      expect(user.isAdmin, true);
      expect(user.globalElo, 1200);
      expect(user.isNew, false); // default value
    });

    test('RankedDifficulty parsing from JSON', () {
      final json = {
        'id': 1,
        'label': 'Facile',
      };

      final difficulty = RankedDifficulty.fromJson(json);

      expect(difficulty.id, 1);
      expect(difficulty.label, 'Facile');
    });

    test('RankedAnswerOption parsing from JSON (with valid)', () {
      final json = {
        'id': 10,
        'value': 'Option A',
        'valid': true,
      };

      final option = RankedAnswerOption.fromJson(json);

      expect(option.id, 10);
      expect(option.label, 'Option A');
      expect(option.valid, true);
    });

    test('RankedQuestionBase parsing from JSON', () {
      final json = {
        'id': 50,
        'label': 'Question test ?',
        'idDifficulty': 2,
        'answer': [
          {'id': 1, 'label': 'A', 'valid': true},
          {'id': 2, 'label': 'B', 'valid': false},
        ],
        'difficulty': {
          'id': 2,
          'label': 'Moyen',
        }
      };

      final questionBase = RankedQuestionBase.fromJson(json);

      expect(questionBase.id, 50);
      expect(questionBase.label, 'Question test ?');
      expect(questionBase.idDifficulty, 2);
      expect(questionBase.answer.length, 2);
      expect(questionBase.answer[0].label, 'A');
      expect(questionBase.difficulty?.label, 'Moyen');
    });

    test('RankedQuestion parsing from JSON', () {
      final json = {
        'question': {
          'id': 100,
          'label': 'Test Ranked ?',
          'idDifficulty': 1,
          'answer': [],
        },
        'currentIndex': 2,
        'score': 500,
        'multiplier': 1.5,
      };

      final q = RankedQuestion.fromJson(json);

      expect(q.currentIndex, 2);
      expect(q.score, 500);
      expect(q.multiplier, 1.5);
      expect(q.question.id, 100);
    });

    test('RankedUserScore parsing from JSON', () {
      final json = {
        'score': 150,
        'user': {
          'id': '999',
          'nickName': 'Winner',
          'globalElo': 1800,
        }
      };

      final us = RankedUserScore.fromJson(json);

      expect(us.score, 150);
      expect(us.user.id, '999');
      expect(us.user.nickName, 'Winner');
      expect(us.user.globalElo, 1800);
    });
  });
}
