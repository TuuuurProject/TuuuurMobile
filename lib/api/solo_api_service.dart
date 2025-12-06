import 'auth_api_service.dart';

/// ----------------------------
/// Helpers locaux de parsing
/// ----------------------------

dynamic _get(Map<String, dynamic>? j, String key) => j == null ? null : j[key];

String? _asString(dynamic v) => v == null ? null : v.toString();

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool? _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  if (v is num) return v != 0;
  return null;
}

DateTime? _asDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// ----------------------------
/// DTOs Solo
/// ----------------------------

/// Résultat de la création d’une partie solo.
/// L’API renvoie un simple UUID, que notre ApiClient met dans data['data'].
class SoloCreateResult {
  final String partyId;

  const SoloCreateResult({required this.partyId});
}

/// Une réponse possible pour une question.
class SoloAnswerDto {
  final int? id;
  final int? questionId;
  final String value;
  final bool? valid;

  const SoloAnswerDto({
    this.id,
    this.questionId,
    required this.value,
    this.valid,
  });

  factory SoloAnswerDto.fromJson(Map<String, dynamic> j) {
    return SoloAnswerDto(
      id: _asInt(_get(j, 'id')),
      questionId: _asInt(_get(j, 'idQuestion')),
      value: _asString(_get(j, 'value')) ?? '',
      valid: _asBool(_get(j, 'valid')),
    );
  }
}

/// Une question de la partie (sans se préoccuper ici des thèmes).
class SoloQuestionDto {
  final int? id;
  final String label;
  final int? difficultyId;
  final String? difficultyLabel;
  final List<SoloAnswerDto> answers;

  const SoloQuestionDto({
    this.id,
    required this.label,
    this.difficultyId,
    this.difficultyLabel,
    required this.answers,
  });

  factory SoloQuestionDto.fromJson(Map<String, dynamic> j) {
    final answersJson = _get(j, 'answer');
    final answers = <SoloAnswerDto>[];
    if (answersJson is List) {
      for (final e in answersJson) {
        if (e is Map<String, dynamic>) {
          answers.add(SoloAnswerDto.fromJson(e));
        }
      }
    }

    // Difficulté possible dans la question ou dans un sous-objet difficulty
    final diffJson = _get(j, 'difficulty');
    int? diffId = _asInt(_get(j, 'idDifficulty'));
    String? diffLabel;

    if (diffJson is Map<String, dynamic>) {
      diffId ??= _asInt(_get(diffJson, 'id'));
      diffLabel = _asString(_get(diffJson, 'label'));
    }

    return SoloQuestionDto(
      id: _asInt(_get(j, 'id')),
      label: _asString(_get(j, 'label')) ?? '',
      difficultyId: diffId,
      difficultyLabel: diffLabel,
      answers: answers,
    );
  }
}

/// Réponse de l’utilisateur pour une question donnée (userPartyQuestion).
class SoloUserPartyQuestionDto {
  final int? id;
  final int? partyQuestionId;
  final int? userId;
  final DateTime? dtPresentedAt;
  final DateTime? dtAnsweredAt;
  final int? answerId;
  final bool? correct;
  final int? score;
  final String? answersOrderRaw; // uuid ou autre format renvoyé par l’API

  const SoloUserPartyQuestionDto({
    this.id,
    this.partyQuestionId,
    this.userId,
    this.dtPresentedAt,
    this.dtAnsweredAt,
    this.answerId,
    this.correct,
    this.score,
    this.answersOrderRaw,
  });

  bool get isAnswered => dtAnsweredAt != null || answerId != null;

  factory SoloUserPartyQuestionDto.fromJson(Map<String, dynamic> j) {
    return SoloUserPartyQuestionDto(
      id: _asInt(_get(j, 'id')),
      partyQuestionId: _asInt(_get(j, 'idPartyQuestion')),
      userId: _asInt(_get(j, 'idUser')),
      dtPresentedAt: _asDateTime(_get(j, 'dtPresentedAt')),
      dtAnsweredAt: _asDateTime(_get(j, 'dtAnsweredAt')),
      answerId: _asInt(_get(j, 'idAnswer')),
      correct: _asBool(_get(j, 'correct')),
      score: _asInt(_get(j, 'score')),
      answersOrderRaw: _asString(_get(j, 'answersOrder')),
    );
  }
}

/// Une entrée de PartyQuestions : question + éventuelle réponse utilisateur.
class SoloPartyQuestionDto {
  final int? id;
  final int? questionId;
  final String? partyId;
  final int? order;
  final SoloQuestionDto? question;
  final SoloUserPartyQuestionDto? userAnswer;

  const SoloPartyQuestionDto({
    this.id,
    this.questionId,
    this.partyId,
    this.order,
    this.question,
    this.userAnswer,
  });

  bool get isAnswered => userAnswer?.isAnswered ?? false;

  factory SoloPartyQuestionDto.fromJson(Map<String, dynamic> j) {
    final qJson = _get(j, 'question');
    final upqJson = _get(j, 'userPartyQuestion');

    return SoloPartyQuestionDto(
      id: _asInt(_get(j, 'id')),
      questionId: _asInt(_get(j, 'idQuestion')),
      partyId: _asString(_get(j, 'idParty')),
      order: _asInt(_get(j, 'order')),
      question:
          qJson is Map<String, dynamic> ? SoloQuestionDto.fromJson(qJson) : null,
      userAnswer: upqJson is Map<String, dynamic>
          ? SoloUserPartyQuestionDto.fromJson(upqJson)
          : null,
    );
  }
}

/// État complet d’une partie solo tel que renvoyé par GET /api/v1/solo/{id}
/// ou POST /api/v1/solo/{id} (après réponse).
class SoloPartyDto {
  final String id;
  final DateTime? dt;
  final String? code;
  final int? idPartyType;
  final int? idUserHost;
  final bool? active;
  final bool? finish;
  final int? score;
  final int? nbQuestions;
  final List<SoloPartyQuestionDto> partyQuestions;

  const SoloPartyDto({
    required this.id,
    this.dt,
    this.code,
    this.idPartyType,
    this.idUserHost,
    this.active,
    this.finish,
    this.score,
    this.nbQuestions,
    required this.partyQuestions,
  });

  bool get isFinished => finish ?? false;

  /// On suppose que l’API renvoie les questions progressivement :
  /// - on prend la première question non répondue
  /// - sinon la dernière (toutes répondues).
  SoloPartyQuestionDto? get currentEntry {
    if (partyQuestions.isEmpty) return null;

    final pending = partyQuestions.where((q) => !q.isAnswered).toList();
    if (pending.isNotEmpty) return pending.first;

    return partyQuestions.last;
  }

  SoloQuestionDto? get currentQuestion => currentEntry?.question;

  int get answeredCount =>
      partyQuestions.where((q) => q.isAnswered).length;

  factory SoloPartyDto.fromJson(Map<String, dynamic> j) {
    final pqJson = _get(j, 'partyQuestions');
    final pqs = <SoloPartyQuestionDto>[];
    if (pqJson is List) {
      for (final e in pqJson) {
        if (e is Map<String, dynamic>) {
          pqs.add(SoloPartyQuestionDto.fromJson(e));
        }
      }
    }

    return SoloPartyDto(
      id: _asString(_get(j, 'id')) ?? '',
      dt: _asDateTime(_get(j, 'dt')),
      code: _asString(_get(j, 'code')),
      idPartyType: _asInt(_get(j, 'idPartyType')),
      idUserHost: _asInt(_get(j, 'idUserHost')),
      active: _asBool(_get(j, 'active')),
      finish: _asBool(_get(j, 'finish')),
      score: _asInt(_get(j, 'score')),
      nbQuestions: _asInt(_get(j, 'nbQuestions')),
      partyQuestions: pqs,
    );
  }
}

/// ----------------------------
/// Client API Solo
/// ----------------------------

class SoloApi {
  final ApiClient _api;

  SoloApi(this._api);

  /// Crée une nouvelle partie solo.
  ///
  /// Swagger : POST /api/v1/solo
  ///
  /// Body attendu :
  /// {
  ///   "themes": [ 1, 2, 3 ],
  ///   "difficulties": [ 2 ],
  ///   "nbQuestions": 10
  /// }
  ///
  /// Réponse : une string UUID, que l’ApiClient met dans data['data'].
  Future<ApiResponse<SoloCreateResult>> createSolo({
    required List<int> themeIds,
    required List<int> difficultyIds,
    required int nbQuestions,
    Map<String, String>? headers,
  }) async {
    final res = await _api.postJson(
      '/api/v1/solo',
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

    final root = res.data ?? <String, dynamic>{};
    // L’UUID peut se trouver dans id / partyId / data selon l’implémentation
    final rawId = root['id'] ?? root['partyId'] ?? root['data'];
    final id = _asString(rawId) ?? '';

    if (id.isEmpty) {
      return ApiResponse.err(
        message: 'Réponse inattendue du serveur (id de partie manquant).',
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    return ApiResponse.ok(
      SoloCreateResult(partyId: id),
      statusCode: res.statusCode,
    );
  }

  /// Récupère l’état d’une partie solo.
  ///
  /// Swagger : GET /api/v1/solo/{p_PartyId}
  Future<ApiResponse<SoloPartyDto>> getSolo({
    required String partyId,
    Map<String, String>? headers,
  }) async {
    final res = await _api.getJson(
      '/api/v1/solo/$partyId',
      headers: headers,
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

  /// Envoie la réponse de l’utilisateur pour la question en cours
  /// et récupère le nouvel état de la partie.
  ///
  /// Swagger : POST /api/v1/solo/{p_PartyId}
  ///
  /// Body :
  /// {
  ///   "answerId": 123
  /// }
  ///
  /// Réponse : même modèle que GET /api/v1/solo/{id}
  Future<ApiResponse<SoloPartyDto>> answerSolo({
    required String partyId,
    required int answerId,
    Map<String, String>? headers,
  }) async {
    final res = await _api.postJson(
      '/api/v1/solo/$partyId',
      headers: headers,
      body: {
        'answerId': answerId,
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
    return ApiResponse.ok(
      SoloPartyDto.fromJson(root),
      statusCode: res.statusCode,
    );
  }

  /// (Optionnel) Récupérer l’historique des parties solo.
  ///
  /// Swagger : GET /api/v1/solo/history
  /// L’API renvoie un tableau de parties ; notre ApiClient le met dans data['data'].
  ///
  /// Attention : l’ApiClient ne gère pas encore les query params,
  /// donc on laisse le backend appliquer ses valeurs par défaut pour Page/Size.
  Future<ApiResponse<List<SoloPartyDto>>> getHistory({
    Map<String, String>? headers,
  }) async {
    final res = await _api.getJson(
      '/api/v1/solo/history',
      headers: headers,
    );

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
    for (final e in list as List) {
      if (e is Map<String, dynamic>) {
        items.add(SoloPartyDto.fromJson(e));
      }
    }

    return ApiResponse.ok(
      items,
      statusCode: res.statusCode,
    );
  }
}

/// Instance prête à l’emploi, comme pour authApi / themeApi / difficultyApi.
final soloApi = SoloApi(ApiClient());
