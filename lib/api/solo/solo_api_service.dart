import '../api_client.dart';
import 'solo_models.dart';
import '../api_helpers.dart';

class SoloApi {
  final ApiClient _api;

  SoloApi(this._api);

  /// POST /api/v1/solo - Creates a new solo party. Requires authentication.
  Future<ApiResponse<SoloCreateResult>> createSolo({
    required List<int> themeIds,
    required List<int> difficultyIds,
    required int nbQuestions,
  }) async {
    final res = await _api.postJson(
      '/api/v1/solo',
      auth: true,
      body: {
        'themes': themeIds,
        'difficulties': difficultyIds,
        'nbQuestions': nbQuestions,
      },
    );

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};
    // UUID can be in id, partyId, or data field
    final rawId = root['id'] ?? root['partyId'] ?? root['data'];
    final id = asString(rawId) ?? '';

    if (id.isEmpty) {
      return ApiResponse.err(
        message: 'Unexpected server response (missing party id).',
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    return ApiResponse.ok(
      SoloCreateResult(partyId: id),
      statusCode: res.statusCode,
    );
  }

  /// GET /api/v1/solo/{partyId} - Fetches solo party state. Requires authentication.
  Future<ApiResponse<SoloPartyDto>> getSolo({required String partyId}) async {
    final res = await _api.getJson('/api/v1/solo/$partyId', auth: true);

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};
    return ApiResponse.ok(
      SoloPartyDto.fromJson(root),
      statusCode: res.statusCode,
    );
  }

  /// POST /api/v1/solo/{partyId} - Submits answer and returns updated party state. Requires authentication.
  Future<ApiResponse<SoloPartyDto>> answerSolo({
    required String partyId,
    required int answerId,
  }) async {
    final res = await _api.postJson(
      '/api/v1/solo/$partyId',
      auth: true,
      body: {'answerId': answerId},
    );

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};
    return ApiResponse.ok(
      SoloPartyDto.fromJson(root),
      statusCode: res.statusCode,
    );
  }

  /// GET /api/v1/solo/history - Fetches solo party history. Requires authentication.
  Future<ApiResponse<List<SoloPartyDto>>> getHistory() async {
    final res = await _api.getJson('/api/v1/solo/history', auth: true);

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};
    dynamic list = root['data'];

    if (list is! List) {
      list = const <dynamic>[];
    }

    final items = <SoloPartyDto>[];
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        items.add(SoloPartyDto.fromJson(e));
      }
    }

    return ApiResponse.ok(items, statusCode: res.statusCode);
  }
}
