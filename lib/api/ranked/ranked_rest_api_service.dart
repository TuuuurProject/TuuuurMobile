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
  }) {
    return _api.getParsed(
      '/api/v1/ranked/ranking?Page=$page&Size=$size',
      RankingPageDto.fromJson,
      logName: 'RankedApi.ranking',
    );
  }
}
