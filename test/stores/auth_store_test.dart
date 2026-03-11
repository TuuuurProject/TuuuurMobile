import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/auth/auth_api_service.dart';
import 'package:tuuuur_flutter/api/auth/auth_models.dart';




void main() {




  group('UserDto', () {
    test('fromJson crée une instance correcte', () {
      final json = {
        'id': '42',
        'nickName': 'johndoe',
        'email': 'john@example.com',
        'avatar': 'avatar.png',
        'isAdmin': true,
        'isNew': false,
      };

      final user = UserDto.fromJson(json);

      expect(user.id, equals('42'));
      expect(user.nickName, equals('johndoe'));
      expect(user.email, equals('john@example.com'));
      expect(user.avatar, equals('avatar.png'));
      expect(user.isAdmin, isTrue);
      expect(user.isNew, isFalse);
    });

    test('fromJson gère les champs manquants', () {
      final user = UserDto.fromJson({});

      expect(user.id, isNull);
      expect(user.nickName, isNull);
      expect(user.email, isNull);
      expect(user.avatar, isNull);
      expect(user.isAdmin, isNull);
      expect(user.isNew, isNull);
    });

    test('toJson sérialise correctement', () {
      final user = UserDto(
        id: '1',
        nickName: 'test',
        email: 'test@example.com',
        avatar: 'avatar.jpg',
        isAdmin: false,
        isNew: true,
      );

      final json = user.toJson();

      expect(json['id'], equals('1'));
      expect(json['nickName'], equals('test'));
      expect(json['email'], equals('test@example.com'));
      expect(json['avatar'], equals('avatar.jpg'));
      expect(json['isAdmin'], isFalse);
      expect(json['isNew'], isTrue);
    });
  });

  group('AuthTokenDto', () {
    test('fromJson crée une instance correcte', () {
      final json = {
        'token': 'abc123',
        'validFrom': '2024-01-01T00:00:00.000Z',
        'validTo': '2024-12-31T23:59:59.999Z',
      };

      final token = AuthTokenDto.fromJson(json);

      expect(token.token, equals('abc123'));
      expect(token.validFrom, isNotNull);
      expect(token.validTo, isNotNull);
    });

    test('fromJson gère les dates nulles', () {
      final json = {'token': 'abc123'};

      final token = AuthTokenDto.fromJson(json);

      expect(token.token, equals('abc123'));
      expect(token.validFrom, isNull);
      expect(token.validTo, isNull);
    });
  });
}
