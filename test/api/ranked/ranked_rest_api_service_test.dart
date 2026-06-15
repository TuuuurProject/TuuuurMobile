import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_rest_api_service.dart';

// Réutilise le mock ApiClient déjà généré pour les tests Solo.
import '../solo/solo_api_service_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late RankedRestApiService service;

  setUp(() {
    mockApiClient = MockApiClient();
    service = RankedRestApiService(apiClient: mockApiClient);
  });

  group('RankedRestApiService.getRanking', () {
    test('retourne le classement en cas de succès', () async {
      when(mockApiClient.getJson(any, auth: anyNamed('auth'))).thenAnswer(
        (_) async => ApiResponse.ok({
          'users': [
            {'id': '1', 'nickName': 'Ava', 'globalElo': 1639, 'userRanking': 1},
          ],
          'userRanking': 5,
          'userElo': 1500,
          'currentPage': 1,
          'totalPages': 2,
          'totalUsers': 60,
        }, statusCode: 200),
      );

      final res = await service.getRanking(page: 1, size: 50);

      expect(res.ok, isTrue);
      expect(res.data?.users.length, 1);
      expect(res.data?.users.first.nickName, 'Ava');
      expect(res.data?.userRanking, 5);
      expect(res.data?.totalPages, 2);
    });

    test('construit le bon endpoint avec Page et Size', () async {
      when(
        mockApiClient.getJson(any, auth: anyNamed('auth')),
      ).thenAnswer((_) async => ApiResponse.ok(<String, dynamic>{}, statusCode: 200));

      await service.getRanking(page: 3, size: 25);

      final captured = verify(
        mockApiClient.getJson(captureAny, auth: captureAnyNamed('auth')),
      ).captured;

      expect(captured[0], equals('/api/v1/ranked/ranking?Page=3&Size=25'));
      expect(captured[1], isTrue); // auth
    });

    test('retourne une erreur en cas d\'échec', () async {
      when(mockApiClient.getJson(any, auth: anyNamed('auth'))).thenAnswer(
        (_) async => ApiResponse.err(message: 'Server error', statusCode: 500),
      );

      final res = await service.getRanking();

      expect(res.ok, isFalse);
      expect(res.statusCode, equals(500));
      expect(res.message, equals('Server error'));
    });
  });
}
