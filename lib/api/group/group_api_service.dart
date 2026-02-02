import '../api_client.dart';
import '../api_helpers.dart';
import 'group_models.dart' as models;

/// Unwrap if backend returns { data: ... }
dynamic _unwrap(dynamic data) {
  final m = asMap(data);
  if (m != null && m.containsKey('data')) return m['data'];
  return data;
}

/// DTOs using models from group_models.dart

/// Main result for group endpoints (create/join/settings/leave)
class GroupResult {
  /// Party UUID (response field: "id")
  final String partyId;

  /// Short code (response field: "code")
  final String code;

  final int? nbQuestions;
  final bool? inProgress;
  final bool? scoreEachRound;
  final int? hostUserId;
  final bool? active;
  final bool? finish;
  final String? dt;
  final int? percent;
  final int? score;
  final int? time;

  final List<models.PartyUser> partyUsers;
  final List<int> themeIds;
  final List<int> difficultyIds;

  const GroupResult({
    required this.partyId,
    required this.code,
    this.nbQuestions,
    this.inProgress,
    this.scoreEachRound,
    this.hostUserId,
    this.active,
    this.finish,
    this.dt,
    this.percent,
    this.score,
    this.time,
    this.partyUsers = const [],
    this.themeIds = const [],
    this.difficultyIds = const [],
  });

  factory GroupResult.fromJson(Map<String, dynamic> j) {
    final partyId = asString(j['id'] ?? j['partyId']) ?? '';
    final code = asString(j['code']) ?? '';

    final pu = <models.PartyUser>[];
    for (final e in asList(j['partyUsers'])) {
      final m = asMap(e);
      if (m != null) pu.add(models.PartyUser.fromJson(m));
    }

    final themes = <int>[];
    for (final e in asList(j['partyTheme'])) {
      final m = asMap(e);
      final idTheme = m == null ? null : asInt(m['idTheme']);
      if (idTheme != null) themes.add(idTheme);
    }

    final diffs = <int>[];
    for (final e in asList(j['partyDifficulty'])) {
      final m = asMap(e);
      final idDifficulty = m == null ? null : asInt(m['idDifficulty']);
      if (idDifficulty != null) diffs.add(idDifficulty);
    }

    return GroupResult(
      partyId: partyId,
      code: code,
      nbQuestions: asInt(j['nbQuestions']),
      inProgress: asBool(j['inProgress']),
      scoreEachRound: asBool(j['scoreEachRound']),
      hostUserId: asInt(j['idUserHost']),
      active: asBool(j['active']),
      finish: asBool(j['finish']),
      dt: asString(j['dt']),
      percent: asInt(j['percent']),
      score: asInt(j['score']),
      time: asInt(j['time']),
      partyUsers: pu,
      themeIds: themes,
      difficultyIds: diffs,
    );
  }

  static const empty = GroupResult(partyId: '', code: '');
}

GroupResult? _parseGroupResult(dynamic data) {
  final unwrapped = _unwrap(data);

  if (unwrapped is String) {
    return GroupResult(partyId: unwrapped, code: '');
  }

  final m = asMap(unwrapped);
  if (m == null) return null;

  final maybeData = _unwrap(m);
  if (maybeData is String) {
    return GroupResult(partyId: maybeData, code: '');
  }

  final mm = asMap(maybeData);
  if (mm == null) return null;

  return GroupResult.fromJson(mm);
}

/// API
class GroupApi {
  final ApiClient _api;
  GroupApi(this._api);

  /// POST /api/v1/group/create
  /// Response: party object (id, code, partyUsers, etc.)
  Future<ApiResponse<GroupResult>> createGroup({
    Map<String, String>? headers,
  }) async {
    final res = await _api.postJson(
      '/api/v1/group/create',
      headers: headers,
      body: <String, dynamic>{},
    );

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final parsed = _parseGroupResult(res.data);
    if (parsed == null || parsed.partyId.isEmpty || parsed.code.isEmpty) {
      return ApiResponse.err(
        message: 'Réponse inattendue (id/code manquant).',
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    return ApiResponse.ok(parsed, statusCode: res.statusCode);
  }

  /// POST /api/v1/group/join
  /// Body: { "code": "string" }
  /// Response: party object
  Future<ApiResponse<GroupResult>> joinGroup({
    required String code,
    Map<String, String>? headers,
  }) async {
    final res = await _api.postJson(
      '/api/v1/group/join',
      headers: headers,
      body: {'code': code},
    );

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final parsed = _parseGroupResult(res.data);
    if (parsed == null || parsed.partyId.isEmpty || parsed.code.isEmpty) {
      return ApiResponse.err(
        message: 'Réponse inattendue (id/code manquant).',
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    return ApiResponse.ok(parsed, statusCode: res.statusCode);
  }

  /// POST /api/v1/group/settings
  /// Body: { themes: [int], difficulties: [int], nbQuestions: int, scoreEachRound: bool }
  /// Response: may be empty (204), only check status
  Future<ApiResponse<void>> updateSettings({
    required List<int> themeIds,
    required List<int> difficultyIds,
    required int nbQuestions,
    required bool scoreEachRound,
    Map<String, String>? headers,
  }) async {
    final res = await _api.postJson(
      '/api/v1/group/settings',
      headers: headers,
      body: {
        'themes': themeIds,
        'difficulties': difficultyIds,
        'nbQuestions': nbQuestions,
        'scoreEachRound': scoreEachRound,
      },
    );

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    return ApiResponse.ok(null, statusCode: res.statusCode);
  }

  /// POST /api/v1/group/leave
  /// Response: variable, considered ok if HTTP ok
  Future<ApiResponse<GroupResult>> leaveGroup({
    Map<String, String>? headers,
  }) async {
    final res = await _api.postJson(
      '/api/v1/group/leave',
      headers: headers,
      body: <String, dynamic>{},
    );

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final parsed = _parseGroupResult(res.data) ?? GroupResult.empty;

    return ApiResponse.ok(parsed, statusCode: res.statusCode);
  }
}
