import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl est une String', () {
      // baseUrl peut être vide si pas de variable d'environnement
      expect(ApiConfig.baseUrl, isA<String>());
    });

    test('googleWebClientId est une String', () {
      // googleWebClientId peut être vide si pas de variable d'environnement
      expect(ApiConfig.googleWebClientId, isA<String>());
    });
  });
}
