import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/api/api_helpers.dart';

void main() {
  group('get', () {
    test('retourne la valeur si la clé existe', () {
      final json = {'key': 'value'};
      expect(get(json, 'key'), equals('value'));
    });

    test('retourne null si json est null', () {
      expect(get(null, 'key'), isNull);
    });

    test('retourne null si la clé n\'existe pas', () {
      final json = {'other': 'value'};
      expect(get(json, 'key'), isNull);
    });
  });

  group('asString', () {
    test('retourne null pour null', () {
      expect(asString(null), isNull);
    });

    test('convertit un int en String', () {
      expect(asString(42), equals('42'));
    });

    test('retourne une String telle quelle', () {
      expect(asString('test'), equals('test'));
    });

    test('convertit un bool en String', () {
      expect(asString(true), equals('true'));
    });
  });

  group('asInt', () {
    test('retourne null pour null', () {
      expect(asInt(null), isNull);
    });

    test('retourne un int tel quel', () {
      expect(asInt(42), equals(42));
    });

    test('convertit un double en int', () {
      expect(asInt(42.7), equals(42));
    });

    test('parse une String numérique', () {
      expect(asInt('123'), equals(123));
    });

    test('retourne null pour une String non numérique', () {
      expect(asInt('abc'), isNull);
    });

    test('retourne null pour un type non supporté', () {
      expect(asInt(true), isNull);
    });
  });

  group('asBool', () {
    test('retourne null pour null', () {
      expect(asBool(null), isNull);
    });

    test('retourne un bool tel quel', () {
      expect(asBool(true), isTrue);
      expect(asBool(false), isFalse);
    });

    test('convertit "true" en true', () {
      expect(asBool('true'), isTrue);
      expect(asBool('True'), isTrue);
      expect(asBool('TRUE'), isTrue);
    });

    test('convertit toute autre String en false', () {
      expect(asBool('false'), isFalse);
      expect(asBool('anything'), isFalse);
    });

    test('convertit un nombre non-zéro en true', () {
      expect(asBool(1), isTrue);
      expect(asBool(-1), isTrue);
      expect(asBool(42), isTrue);
    });

    test('convertit zéro en false', () {
      expect(asBool(0), isFalse);
      expect(asBool(0.0), isFalse);
    });
  });

  group('asDateTime', () {
    test('retourne null pour null', () {
      expect(asDateTime(null), isNull);
    });

    test('retourne un DateTime tel quel', () {
      final dt = DateTime(2024, 1, 1);
      expect(asDateTime(dt), equals(dt));
    });

    test('parse une String ISO8601 avec timezone Z', () {
      final result = asDateTime('2024-01-01T10:30:00Z');
      expect(result, isNotNull);
      expect(result!.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(1));
    });

    test('parse une String ISO8601 avec timezone offset', () {
      final result = asDateTime('2024-01-01T10:30:00+02:00');
      expect(result, isNotNull);
      expect(result!.year, equals(2024));
    });

    test('parse une String ISO8601 sans timezone (traite comme UTC)', () {
      final result = asDateTime('2024-01-01T10:30:00');
      expect(result, isNotNull);
      expect(result!.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(1));
    });

    test('retourne null pour une String invalide', () {
      expect(asDateTime('not-a-date'), isNull);
    });

    test('retourne null pour un type non supporté', () {
      expect(asDateTime(12345), isNull);
    });
  });

  group('asMap', () {
    test('retourne null pour null', () {
      expect(asMap(null), isNull);
    });

    test('retourne une Map<String, dynamic> telle quelle', () {
      final map = {'key': 'value'};
      expect(asMap(map), equals(map));
    });

    test('convertit une Map générique', () {
      final map = <dynamic, dynamic>{'key': 'value', 1: 'test'};
      final result = asMap(map);
      expect(result, isNotNull);
      expect(result!['key'], equals('value'));
    });

    test('retourne null pour un type non Map', () {
      expect(asMap('not a map'), isNull);
      expect(asMap(123), isNull);
      expect(asMap([1, 2, 3]), isNull);
    });
  });

  group('asList', () {
    test('retourne une liste vide pour null', () {
      expect(asList(null), isEmpty);
    });

    test('retourne une List telle quelle', () {
      final list = [1, 2, 3];
      expect(asList(list), equals(list));
    });

    test('retourne une liste vide pour un type non List', () {
      expect(asList('not a list'), isEmpty);
      expect(asList(123), isEmpty);
      expect(asList({'key': 'value'}), isEmpty);
    });
  });
}
