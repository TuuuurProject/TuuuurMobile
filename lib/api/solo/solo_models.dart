import '../api_helpers.dart';

/// Solo party creation result containing the party UUID.
class SoloCreateResult {
  final String partyId;

  const SoloCreateResult({required this.partyId});
}

/// Answer option for a question.
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
      id: asInt(get(j, 'id')),
      questionId: asInt(get(j, 'idQuestion')),
      value: asString(get(j, 'value')) ?? '',
      valid: asBool(get(j, 'valid')),
    );
  }
}

/// Question-theme relation
class SoloQuestionThemeDto {
  final int? id;
  final SoloThemeDto? theme;

  const SoloQuestionThemeDto({
    this.id,
    this.theme,
  });

  factory SoloQuestionThemeDto.fromJson(Map<String, dynamic> j) {
    final themeJson = get(j, 'theme');
    return SoloQuestionThemeDto(
      id: asInt(get(j, 'id')),
      theme: themeJson is Map<String, dynamic>
          ? SoloThemeDto.fromJson(themeJson)
          : null,
    );
  }
}

/// Question with answers and difficulty.
class SoloQuestionDto {
  final int? id;
  final String label;
  final int? difficultyId;
  final String? difficultyLabel;
  final List<SoloAnswerDto> answers;
  final List<SoloQuestionThemeDto> questionTheme;

  const SoloQuestionDto({
    this.id,
    required this.label,
    this.difficultyId,
    this.difficultyLabel,
    required this.answers,
    this.questionTheme = const [],
  });

  factory SoloQuestionDto.fromJson(Map<String, dynamic> j) {
    final answersJson = get(j, 'answer');
    final answers = <SoloAnswerDto>[];
    if (answersJson is List) {
      for (final e in answersJson) {
        if (e is Map<String, dynamic>) {
          answers.add(SoloAnswerDto.fromJson(e));
        }
      }
    }

    // Difficulty can be in question or in difficulty sub-object
    final diffJson = get(j, 'difficulty');
    int? diffId = asInt(get(j, 'idDifficulty'));
    String? diffLabel;

    if (diffJson is Map<String, dynamic>) {
      diffId ??= asInt(get(diffJson, 'id'));
      diffLabel = asString(get(diffJson, 'label'));
    }

    final qtJson = get(j, 'questionTheme');
    final qts = <SoloQuestionThemeDto>[];
    if (qtJson is List) {
      for (final e in qtJson) {
        if (e is Map<String, dynamic>) {
          qts.add(SoloQuestionThemeDto.fromJson(e));
        }
      }
    }

    return SoloQuestionDto(
      id: asInt(get(j, 'id')),
      label: asString(get(j, 'label')) ?? '',
      difficultyId: diffId,
      difficultyLabel: diffLabel,
      answers: answers,
      questionTheme: qts,
    );
  }
}

/// User's answer to a party question.
class SoloUserPartyQuestionDto {
  final int? id;
  final int? partyQuestionId;
  final int? userId;
  final DateTime? dtPresentedAt;
  final DateTime? dtAnsweredAt;
  final int? answerId;
  final bool? correct;
  final int? score;
  final String? answersOrderRaw; // UUID or other format from API

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
      id: asInt(get(j, 'id')),
      partyQuestionId: asInt(get(j, 'idPartyQuestion')),
      userId: asInt(get(j, 'idUser')),
      dtPresentedAt: asDateTime(get(j, 'dtPresentedAt')),
      dtAnsweredAt: asDateTime(get(j, 'dtAnsweredAt')),
      answerId: asInt(get(j, 'idAnswer')),
      correct: asBool(get(j, 'correct')),
      score: asInt(get(j, 'score')),
      answersOrderRaw: asString(get(j, 'answersOrder')),
    );
  }
}

/// Party question with optional user answer.
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
    final qJson = get(j, 'question');
    final upqJson = get(j, 'userPartyQuestion');

    return SoloPartyQuestionDto(
      id: asInt(get(j, 'id')),
      questionId: asInt(get(j, 'idQuestion')),
      partyId: asString(get(j, 'idParty')),
      order: asInt(get(j, 'order')),
      question:
          qJson is Map<String, dynamic> ? SoloQuestionDto.fromJson(qJson) : null,
      userAnswer: upqJson is Map<String, dynamic>
          ? SoloUserPartyQuestionDto.fromJson(upqJson)
          : null,
    );
  }
}

/// Theme information
class SoloThemeDto {
  final int? id;
  final String label;
  final String? icon;

  const SoloThemeDto({
    this.id,
    required this.label,
    this.icon,
  });

  factory SoloThemeDto.fromJson(Map<String, dynamic> j) {
    return SoloThemeDto(
      id: asInt(get(j, 'id')),
      label: asString(get(j, 'label')) ?? '',
      icon: asString(get(j, 'icon')),
    );
  }
}

/// Party-theme relation
class SoloPartyThemeDto {
  final int? id;
  final SoloThemeDto? theme;

  const SoloPartyThemeDto({
    this.id,
    this.theme,
  });

  factory SoloPartyThemeDto.fromJson(Map<String, dynamic> j) {
    final themeJson = get(j, 'theme');
    return SoloPartyThemeDto(
      id: asInt(get(j, 'id')),
      theme: themeJson is Map<String, dynamic>
          ? SoloThemeDto.fromJson(themeJson)
          : null,
    );
  }
}

/// Complete solo party state.
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
  final List<SoloPartyThemeDto> partyTheme;

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
    this.partyTheme = const [],
  });

  bool get isFinished => finish ?? false;

  /// Returns first unanswered question or last if all answered.
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
    final pqJson = get(j, 'partyQuestions');
    final pqs = <SoloPartyQuestionDto>[];
    if (pqJson is List) {
      for (final e in pqJson) {
        if (e is Map<String, dynamic>) {
          pqs.add(SoloPartyQuestionDto.fromJson(e));
        }
      }
    }

    final ptJson = get(j, 'partyTheme');
    final pts = <SoloPartyThemeDto>[];
    if (ptJson is List) {
      for (final e in ptJson) {
        if (e is Map<String, dynamic>) {
          pts.add(SoloPartyThemeDto.fromJson(e));
        }
      }
    }

    return SoloPartyDto(
      id: asString(get(j, 'id')) ?? '',
      dt: asDateTime(get(j, 'dt')),
      code: asString(get(j, 'code')),
      idPartyType: asInt(get(j, 'idPartyType')),
      idUserHost: asInt(get(j, 'idUserHost')),
      active: asBool(get(j, 'active')),
      finish: asBool(get(j, 'finish')),
      score: asInt(get(j, 'score')),
      nbQuestions: asInt(get(j, 'nbQuestions')),
      partyQuestions: pqs,
      partyTheme: pts,
    );
  }
}
