import 'dart:developer' as dev;

import '../api_client.dart';
import 'history_models.dart';

/// History API client
class HistoryApi {
  final ApiClient _api;

  HistoryApi(this._api);

  /// Fetches authenticated user's history
  /// GET /api/v1/history?page=1&size=10
  Future<ApiResponse<HistoryPageDto>> getHistory({
    int page = 1,
    int size = 10,
  }) async {
    final path = '/api/v1/history?page=$page&size=$size';

    final res = await _api.getJson(path, auth: true);

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};
    final pageDto = HistoryPageDto.fromJson(root);
    return ApiResponse.ok(pageDto, statusCode: res.statusCode);
  }

  /// Fetches party detail by ID
  /// GET /api/v1/group/{partyId}
  Future<ApiResponse<PartyDetailDto>> getPartyDetail(String partyId) async {
    final path = '/api/v1/group/$partyId';

    final res = await _api.getJson(path, auth: true);

    if (!res.ok) {
      dev.log(
        'GET $path → échec (status ${res.statusCode}): ${res.message}',
        name: 'HistoryApi.group',
      );
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};
    // Log de debug visible dans l'onglet "Logging" de Flutter DevTools.
    dev.log(
      'GET $path → réponse API: $root',
      name: 'HistoryApi.group',
    );
    final detail = PartyDetailDto.fromJson(root);
    return ApiResponse.ok(detail, statusCode: res.statusCode);
  }

  /// Fetches ranked party detail by ID
  /// GET /api/v1/ranked/{partyId}
  Future<ApiResponse<PartyDetailDto>> getRankedPartyDetail(
    String partyId,
  ) async {
    final path = '/api/v1/ranked/$partyId';

    final res = await _api.getJson(path, auth: true);

    if (!res.ok) {
      dev.log(
        'GET $path → échec (status ${res.statusCode}): ${res.message}',
        name: 'HistoryApi.ranked',
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
      name: 'HistoryApi.ranked',
    );
    final detail = PartyDetailDto.fromJson(root);
    return ApiResponse.ok(detail, statusCode: res.statusCode);
  }

  /// Fetches solo party detail by ID
  /// GET /api/v1/solo/{partyId}
  Future<ApiResponse<PartyDetailDto>> getSoloPartyDetail(String partyId) async {
    final path = '/api/v1/solo/$partyId';

    final res = await _api.getJson(path, auth: true);

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};
    final detail = PartyDetailDto.fromJson(root);
    return ApiResponse.ok(detail, statusCode: res.statusCode);
  }
}
