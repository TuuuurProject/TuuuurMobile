import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  group('HomePage', () {
    test('HomePage peut être instanciée', () {
      const page = HomePage();
      expect(page, isA<HomePage>());
      expect(page, isA<StatefulWidget>());
    });

    test('HomePage a une clé nullable', () {
      const page = HomePage();
      expect(page.key, isNull);
      
      const pageWithKey = HomePage(key: ValueKey('test'));
      expect(pageWithKey.key, isNotNull);
    });

    test('HomePage crée un state correct', () {
      const page = HomePage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}
