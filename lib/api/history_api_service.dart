import 'api_client.dart';
import 'api_helpers.dart';

dynamic _get(Map<String, dynamic>? j, String key) => get(j, key);
String? _asString(dynamic v) => asString(v);
int? _asInt(dynamic v) => asInt(v);
bool? _asBool(dynamic v) => asBool(v);
DateTime? _asDateTime(dynamic v) => asDateTime(v);


/// ----------------------------
/// DTO History (equivalent Match côté web)
/// ----------------------------

class HistoryPartyTypeDto {
  final int? id;
  final String label;

  const HistoryPartyTypeDto({
    this.id,
    required this.label,
  });

  factory HistoryPartyTypeDto.fromJson(Map<String, dynamic> j) {
    return HistoryPartyTypeDto(
      id: _asInt(_get(j, 'id')),
      label: _asString(_get(j, 'label')) ?? '',
    );
  }
}

class HistoryDifficultyDto {
  final int? id;
  final String label;

  const HistoryDifficultyDto({
    this.id,
    required this.label,
  });

  factory HistoryDifficultyDto.fromJson(Map<String, dynamic> j) {
    return HistoryDifficultyDto(
      id: _asInt(_get(j, 'id')),
      label: _asString(_get(j, 'label')) ?? '',
    );
  }
}

class HistoryPartyDifficultyDto {
  final int? id;
  final HistoryDifficultyDto? difficulty;

  const HistoryPartyDifficultyDto({
    this.id,
    this.difficulty,
  });

  factory HistoryPartyDifficultyDto.fromJson(Map<String, dynamic> j) {
    final diffJson = _get(j, 'difficulty');
    return HistoryPartyDifficultyDto(
      id: _asInt(_get(j, 'id')),
      difficulty: diffJson is Map<String, dynamic>
          ? HistoryDifficultyDto.fromJson(diffJson)
          : null,
    );
  }
}

class HistoryThemeDto {
  final int? id;
  final String label;
  final String? icon;

  const HistoryThemeDto({
    this.id,
    required this.label,
    this.icon,
  });

  factory HistoryThemeDto.fromJson(Map<String, dynamic> j) {
    return HistoryThemeDto(
      id: _asInt(_get(j, 'id')),
      label: _asString(_get(j, 'label')) ?? '',
      icon: _asString(_get(j, 'icon')),
    );
  }
}

class HistoryPartyThemeDto {
  final int? id;
  final HistoryThemeDto? theme;

  const HistoryPartyThemeDto({
    this.id,
    this.theme,
  });

  factory HistoryPartyThemeDto.fromJson(Map<String, dynamic> j) {
    final themeJson = _get(j, 'theme');
    return HistoryPartyThemeDto(
      id: _asInt(_get(j, 'id')),
      theme: themeJson is Map<String, dynamic>
          ? HistoryThemeDto.fromJson(themeJson)
          : null,
    );
  }
}

/// Un "Match" dans l’historique (équiv. type Match du front web)
class HistoryMatchDto {
  final String id;
  final DateTime? dt;
  final bool finish;
  final int? nbQuestions;
  final int? score;
  final int? time;    // en secondes
  final int? percent; // pourcentage de réussite
  final HistoryPartyTypeDto? partyType;
  final List<HistoryPartyDifficultyDto> partyDifficulty;
  final List<HistoryPartyThemeDto> partyTheme;

  const HistoryMatchDto({
    required this.id,
    this.dt,
    required this.finish,
    this.nbQuestions,
    this.score,
    this.time,
    this.percent,
    this.partyType,
    required this.partyDifficulty,
    required this.partyTheme,
  });

  factory HistoryMatchDto.fromJson(Map<String, dynamic> j) {
    final ptJson = _get(j, 'partyType');
    final pdJson = _get(j, 'partyDifficulty');
    final ptmJson = _get(j, 'partyTheme');

    final pds = <HistoryPartyDifficultyDto>[];
    if (pdJson is List) {
      for (final e in pdJson) {
        if (e is Map<String, dynamic>) {
          pds.add(HistoryPartyDifficultyDto.fromJson(e));
        }
      }
    }

    final themes = <HistoryPartyThemeDto>[];
    if (ptmJson is List) {
      for (final e in ptmJson) {
        if (e is Map<String, dynamic>) {
          themes.add(HistoryPartyThemeDto.fromJson(e));
        }
      }
    }

    return HistoryMatchDto(
      id: _asString(_get(j, 'id')) ?? '',
      dt: _asDateTime(_get(j, 'dt') ?? _get(j, 'date')),
      finish: _asBool(_get(j, 'finish') ?? _get(j, 'finished') ?? _get(j, 'isFinished')) ?? false,
      nbQuestions: _asInt(_get(j, 'nbQuestions')),
      score: _asInt(_get(j, 'score')),
      time: _asInt(_get(j, 'time') ?? _get(j, 'duration') ?? _get(j, 'elapsedSeconds')),
      percent: _asInt(_get(j, 'percent') ?? _get(j, 'successPercent')),
      partyType: ptJson is Map<String, dynamic>
          ? HistoryPartyTypeDto.fromJson(ptJson)
          : null,
      partyDifficulty: pds,
      partyTheme: themes,
    );
  }
}


/// Page d’historique (liste + meta pagination si le backend en renvoie)
class HistoryPageDto {
  final List<HistoryMatchDto> items;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  const HistoryPageDto({
    required this.items,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory HistoryPageDto.fromJson(Map<String, dynamic> j) {
    // Au cas où il y ait un wrapper { "data": { ... } }
    final inner = _get(j, 'data');
    final root = inner is Map<String, dynamic> ? inner : j;

    // 👇 PRIO : ce que le back renvoie réellement
    dynamic list = _get(root, 'history');

    // fallback génériques si jamais ça évolue
    if (list is! List) {
      list = _get(root, 'data');
    }
    if (list is! List) {
      list = _get(root, 'items');
    }
    if (list is! List) {
      list = const <dynamic>[];
    }

    final items = <HistoryMatchDto>[];
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        items.add(HistoryMatchDto.fromJson(e));
      }
    }

    final page = _asInt(_get(root, 'page') ?? _get(root, 'currentPage'));
    final pages = _asInt(_get(root, 'totalPages') ?? _get(root, 'pages'));
    final parties = _asInt(_get(root, 'totalParties') ?? _get(root, 'parties'));

    return HistoryPageDto(
      items: items,
      totalCount: parties,
      currentPage: page,
      totalPages: pages,
    );
  }
}


/// ----------------------------
/// Client API History
/// --------------------  --------

class HistoryApi {
  final ApiClient _api;

  HistoryApi(this._api);

  /// Récupère l'historique du joueur connecté.
  ///
  /// Swagger : GET /api/v1/history?page=1&size=10
  /// ATTENTION: cette méthode nécessite l'authentification automatique via ApiClient.
  Future<ApiResponse<HistoryPageDto>> getHistory({
    int page = 1,
    int size = 10,
  }) async {
    final path = '/api/v1/history?page=$page&size=$size';

    final res = await _api.getJson(
      path,
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
    final pageDto = HistoryPageDto.fromJson(root);
    return ApiResponse.ok(pageDto, statusCode: res.statusCode);
  }
}
