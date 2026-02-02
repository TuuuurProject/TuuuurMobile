import '../api_client.dart'; 
import 'difficulty_models.dart';

/// API client for /api/v1/difficulty
class DifficultyApi {
  final ApiClient _api;

  DifficultyApi(this._api);

  /// GET /api/v1/difficulty - Requires authentication
  Future<ApiResponse<List<DifficultyDto>>> getDifficulties() async {
    final res = await _api.getJson(
      '/api/v1/difficulty',
      auth: true,
    );

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};

    // Check multiple possible keys for the list
    dynamic list =
        root['data'] ?? root['items'] ?? root['value'] ?? root['difficulties'];

    if (list is! List) {
      list = const <dynamic>[];
    }

    final difficulties = <DifficultyDto>[];
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        difficulties.add(DifficultyDto.fromJson(e));
      }
    }

    // Sort by ID
    difficulties.sort((a, b) {
      final ai = a.id ?? 999999;
      final bi = b.id ?? 999999;
      return ai.compareTo(bi);
    });

    return ApiResponse.ok(
      difficulties,
      statusCode: res.statusCode,
    );
  }
}
