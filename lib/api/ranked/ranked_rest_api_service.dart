import 'dart:developer' as dev;

import '../api_client.dart';
import 'ranked_ranking_models.dart';

/// Client REST pour les endpoints Ranked (hors WebSocket).
class RankedRestApiService {
  final ApiClient _api;

  RankedRestApiService({required ApiClient apiClient}) : _api = apiClient;

  /// Récupère le classement paginé.
  /// GET /api/v1/ranked/ranking?Page={page}&Size={size}
  Future<ApiResponse<RankingPageDto>> getRanking({
    int page = 1,
    int size = 50,
  }) async {
    final path = '/api/v1/ranked/ranking?Page=$page&Size=$size';

    final res = await _api.getJson(path, auth: true);

    if (!res.ok) {
      dev.log(
        'GET $path → échec (status ${res.statusCode}): ${res.message}',
        name: 'RankedApi.ranking',
      );
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};
    dev.log(
      'GET $path → réponse API: $root',
      name: 'RankedApi.ranking',
    );
    return ApiResponse.ok(
      RankingPageDto.fromJson(root),
      statusCode: res.statusCode,
    );
  }
}
