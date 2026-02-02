import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl est une String', () {

      expect(ApiConfig.baseUrl, isA<String>());
    });

    test('googleWebClientId est une String', () {

      expect(ApiConfig.googleWebClientId, isA<String>());
    });
  });
}
