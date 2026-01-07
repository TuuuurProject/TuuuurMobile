import 'api_client.dart';

/// ----------------------------
/// Helpers locaux
/// ----------------------------
String? _asString(dynamic v) => v == null ? null : v.toString();

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool? _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  if (v is num) return v != 0;
  return null;
}

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return null;
}

List<dynamic> _asList(dynamic v) => v is List ? v : const [];

/// Unwrap si backend renvoie { data: ... }
dynamic _unwrap(dynamic data) {
  final m = _asMap(data);
  if (m != null && m.containsKey('data')) return m['data'];
  return data;
}

/// ----------------------------
/// DTOs (minimaux mais utiles)
/// ----------------------------
class GroupUser {
  final int? id;
  final String nickName;
  final String? email;
  final String? avatar;

  const GroupUser({
    this.id,
    required this.nickName,
    this.email,
    this.avatar,
  });

  factory GroupUser.fromJson(Map<String, dynamic> j) => GroupUser(
        id: _asInt(j['id']),
        nickName: _asString(j['nickName']) ?? _asString(j['nickname']) ?? '',
        email: _asString(j['email']),
        avatar: _asString(j['avatar']),
      );
}

class GroupPartyUser {
  final int? idUser;
  final GroupUser? user;

  const GroupPartyUser({this.idUser, this.user});

  factory GroupPartyUser.fromJson(Map<String, dynamic> j) => GroupPartyUser(
        idUser: _asInt(j['idUser']),
        user: _asMap(j['user']) == null ? null : GroupUser.fromJson(_asMap(j['user'])!),
      );
}

/// Résultat principal des endpoints group (create/join/settings/leave)
class GroupResult {
  /// UUID de party (dans ta réponse: "id")
  final String partyId;

  /// Code court (dans ta réponse: "code" ex "547246")
  /// Peut être vide sur certains endpoints (au pire on ne casse pas).
  final String code;

  final int? nbQuestions;
  final bool? inProgress;
  final int? hostUserId;

  final List<GroupPartyUser> partyUsers;
  final List<int> themeIds;
  final List<int> difficultyIds;

  const GroupResult({
    required this.partyId,
    required this.code,
    this.nbQuestions,
    this.inProgress,
    this.hostUserId,
    this.partyUsers = const [],
    this.themeIds = const [],
    this.difficultyIds = const [],
  });

  factory GroupResult.fromJson(Map<String, dynamic> j) {
    final partyId = _asString(j['id'] ?? j['partyId']) ?? '';
    final code = _asString(j['code']) ?? '';

    // partyUsers
    final pu = <GroupPartyUser>[];
    for (final e in _asList(j['partyUsers'])) {
      final m = _asMap(e);
      if (m != null) pu.add(GroupPartyUser.fromJson(m));
    }

    // partyTheme -> idTheme
    final themes = <int>[];
    for (final e in _asList(j['partyTheme'])) {
      final m = _asMap(e);
      final idTheme = m == null ? null : _asInt(m['idTheme']);
      if (idTheme != null) themes.add(idTheme);
    }

    // partyDifficulty -> idDifficulty
    final diffs = <int>[];
    for (final e in _asList(j['partyDifficulty'])) {
      final m = _asMap(e);
      final idDifficulty = m == null ? null : _asInt(m['idDifficulty']);
      if (idDifficulty != null) diffs.add(idDifficulty);
    }

    return GroupResult(
      partyId: partyId,
      code: code,
      nbQuestions: _asInt(j['nbQuestions']),
      inProgress: _asBool(j['inProgress']),
      hostUserId: _asInt(j['idUserHost']),
      partyUsers: pu,
      themeIds: themes,
      difficultyIds: diffs,
    );
  }

  static const empty = GroupResult(partyId: '', code: '');
}

GroupResult? _parseGroupResult(dynamic data) {
  final unwrapped = _unwrap(data);

  // Ancien backend: "uuid" direct
  if (unwrapped is String) {
    return GroupResult(partyId: unwrapped, code: '');
  }

  final m = _asMap(unwrapped);
  if (m == null) return null;

  // Parfois encore un niveau de data
  final maybeData = _unwrap(m);
  if (maybeData is String) {
    return GroupResult(partyId: maybeData, code: '');
  }

  final mm = _asMap(maybeData);
  if (mm == null) return null;

  return GroupResult.fromJson(mm);
}

/// ----------------------------
/// API
/// ----------------------------
class GroupApi {
  final ApiClient _api;
  GroupApi(this._api);

  /// POST /api/v1/group/create
  /// Réponse: objet party (id, code, partyUsers, etc.)
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
  /// Réponse: objet party
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
  /// Body: { themes: [int], difficulties: [int], nbQuestions: int }
  /// Réponse: parfois vide (204) -> on ne parse rien, on check juste le statut.
  Future<ApiResponse<void>> updateSettings({
    required List<int> themeIds,
    required List<int> difficultyIds,
    required int nbQuestions,
    Map<String, String>? headers,
  }) async {
    final res = await _api.postJson(
      '/api/v1/group/settings',
      headers: headers,
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

    return ApiResponse.ok(null, statusCode: res.statusCode);
  }

  /// POST /api/v1/group/leave
  /// Réponse: variable selon backend. Ici: on considère ok si HTTP ok.
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

    // Si on arrive à parser, tant mieux, sinon on renvoie un empty.
    final parsed = _parseGroupResult(res.data) ?? GroupResult.empty;

    return ApiResponse.ok(parsed, statusCode: res.statusCode);
  }
}

/// Instance prête à l’emploi (comme soloApi)
final groupApi = GroupApi(apiClient);
