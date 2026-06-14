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
  }) {
    return _api.getParsed(
      '/api/v1/history?page=$page&size=$size',
      HistoryPageDto.fromJson,
    );
  }

  /// Fetches group party detail by ID
  /// GET /api/v1/group/{partyId}
  Future<ApiResponse<PartyDetailDto>> getPartyDetail(String partyId) {
    return _api.getParsed(
      '/api/v1/group/$partyId',
      PartyDetailDto.fromJson,
      logName: 'HistoryApi.group',
    );
  }

  /// Fetches solo party detail by ID
  /// GET /api/v1/solo/{partyId}
  Future<ApiResponse<PartyDetailDto>> getSoloPartyDetail(String partyId) {
    return _api.getParsed(
      '/api/v1/solo/$partyId',
      PartyDetailDto.fromJson,
    );
  }

  /// Fetches ranked party detail by ID
  /// GET /api/v1/ranked/{partyId}
  Future<ApiResponse<PartyDetailDto>> getRankedPartyDetail(String partyId) {
    return _api.getParsed(
      '/api/v1/ranked/$partyId',
      PartyDetailDto.fromJson,
      logName: 'HistoryApi.ranked',
    );
  }
}
