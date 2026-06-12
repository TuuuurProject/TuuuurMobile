import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/ranked/ranked_ranking_models.dart';

void main() {
  group('RankingUser', () {
    test('fromJson complet', () {
      final u = RankingUser.fromJson({
        'id': 'abc',
        'nickName': 'Alice',
        'email': 'a@b.com',
        'avatar': 'data:image/png;base64,xxx',
        'globalElo': 1640,
        'userRanking': 1,
      });

      expect(u.id, 'abc');
      expect(u.nickName, 'Alice');
      expect(u.email, 'a@b.com');
      expect(u.avatar, 'data:image/png;base64,xxx');
      expect(u.globalElo, 1640);
      expect(u.userRanking, 1);
      expect(u.displayName, 'Alice');
    });

    test('fromJson applique les valeurs par défaut', () {
      final u = RankingUser.fromJson({});

      expect(u.id, '');
      expect(u.nickName, '');
      expect(u.avatar, isNull);
      expect(u.globalElo, 0);
      expect(u.userRanking, 0);
      expect(u.displayName, 'Joueur'); // nickName vide → fallback
    });
  });

  group('RankingPageDto', () {
    test('fromJson complet avec liste de joueurs', () {
      final dto = RankingPageDto.fromJson({
        'users': [
          {'id': '1', 'nickName': 'Ava', 'globalElo': 1639, 'userRanking': 1},
          {'id': '2', 'nickName': 'Liam', 'globalElo': 1627, 'userRanking': 2},
        ],
        'userRanking': 42,
        'userElo': 1500,
        'currentPage': 1,
        'totalPages': 3,
        'totalUsers': 150,
        'userTier': 2,
        'userDivision': 1,
      });

      expect(dto.users.length, 2);
      expect(dto.users[0].nickName, 'Ava');
      expect(dto.users[1].userRanking, 2);
      expect(dto.userRanking, 42);
      expect(dto.userElo, 1500);
      expect(dto.currentPage, 1);
      expect(dto.totalPages, 3);
      expect(dto.totalUsers, 150);
      expect(dto.userTier, 2);
      expect(dto.userDivision, 1);
    });

    test('fromJson tolère users absent / non-liste', () {
      final dto = RankingPageDto.fromJson({'users': 'pas une liste'});

      expect(dto.users, isEmpty);
      expect(dto.currentPage, 1);
      expect(dto.totalPages, 1);
      expect(dto.totalUsers, 0);
    });

    test('fromJson ignore les entrées non-map dans users', () {
      final dto = RankingPageDto.fromJson({
        'users': [
          {'id': '1', 'nickName': 'Ava', 'globalElo': 1639, 'userRanking': 1},
          'invalide',
          42,
        ],
      });

      expect(dto.users.length, 1);
      expect(dto.users[0].nickName, 'Ava');
    });
  });
}
