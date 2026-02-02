import '../api_helpers.dart';

/// History DTOs (match data from backend)

class HistoryPartyTypeDto {
  final int? id;
  final String label;

  const HistoryPartyTypeDto({
    this.id,
    required this.label,
  });

  factory HistoryPartyTypeDto.fromJson(Map<String, dynamic> j) {
    return HistoryPartyTypeDto(
      id: asInt(get(j, 'id')),
      label: asString(get(j, 'label')) ?? '',
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
      id: asInt(get(j, 'id')),
      label: asString(get(j, 'label')) ?? '',
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
    final diffJson = get(j, 'difficulty');
    return HistoryPartyDifficultyDto(
      id: asInt(get(j, 'id')),
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
      id: asInt(get(j, 'id')),
      label: asString(get(j, 'label')) ?? '',
      icon: asString(get(j, 'icon')),
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
    final themeJson = get(j, 'theme');
    return HistoryPartyThemeDto(
      id: asInt(get(j, 'id')),
      theme: themeJson is Map<String, dynamic>
          ? HistoryThemeDto.fromJson(themeJson)
          : null,
    );
  }
}

/// History match data
class HistoryMatchDto {
  final String id;
  final DateTime? dt;
  final bool finish;
  final int? nbQuestions;
  final int? score;
  final int? time;
  final int? percent;
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
    final ptJson = get(j, 'partyType');
    final pdJson = get(j, 'partyDifficulty');
    final ptmJson = get(j, 'partyTheme');

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
      id: asString(get(j, 'id')) ?? '',
      dt: asDateTime(get(j, 'dt') ?? get(j, 'date')),
      finish: asBool(get(j, 'finish') ?? get(j, 'finished') ?? get(j, 'isFinished')) ?? false,
      nbQuestions: asInt(get(j, 'nbQuestions')),
      score: asInt(get(j, 'score')),
      time: asInt(get(j, 'time') ?? get(j, 'duration') ?? get(j, 'elapsedSeconds')),
      percent: asInt(get(j, 'percent') ?? get(j, 'successPercent')),
      partyType: ptJson is Map<String, dynamic>
          ? HistoryPartyTypeDto.fromJson(ptJson)
          : null,
      partyDifficulty: pds,
      partyTheme: themes,
    );
  }
}

/// History page with pagination metadata
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
    // Handle potential data wrapper
    final inner = get(j, 'data');
    final root = inner is Map<String, dynamic> ? inner : j;

    // Primary field from backend
    dynamic list = get(root, 'history');

    // Fallback fields
    if (list is! List) {
      list = get(root, 'data');
    }
    if (list is! List) {
      list = get(root, 'items');
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

    final page = asInt(get(root, 'page') ?? get(root, 'currentPage'));
    final pages = asInt(get(root, 'totalPages') ?? get(root, 'pages'));
    final parties = asInt(get(root, 'totalParties') ?? get(root, 'parties'));

    return HistoryPageDto(
      items: items,
      totalCount: parties,
      currentPage: page,
      totalPages: pages,
    );
  }
}

/// User model for party detail
class HistoryUserDto {
  final int? id;
  final String nickName;
  final String? email;
  final String? avatar;
  final bool isAdmin;
  final bool isNew;

  const HistoryUserDto({
    this.id,
    required this.nickName,
    this.email,
    this.avatar,
    required this.isAdmin,
    required this.isNew,
  });

  factory HistoryUserDto.fromJson(Map<String, dynamic> j) {
    return HistoryUserDto(
      id: asInt(get(j, 'id')),
      nickName: asString(get(j, 'nickName')) ?? '',
      email: asString(get(j, 'email')),
      avatar: asString(get(j, 'avatar')),
      isAdmin: asBool(get(j, 'isAdmin')) ?? false,
      isNew: asBool(get(j, 'isNew')) ?? false,
    );
  }
}

/// Answer model
class HistoryAnswerDto {
  final int? id;
  final int? idQuestion;
  final String value;
  final bool valid;

  const HistoryAnswerDto({
    this.id,
    this.idQuestion,
    required this.value,
    required this.valid,
  });

  factory HistoryAnswerDto.fromJson(Map<String, dynamic> j) {
    return HistoryAnswerDto(
      id: asInt(get(j, 'id')),
      idQuestion: asInt(get(j, 'idQuestion')),
      value: asString(get(j, 'value')) ?? '',
      valid: asBool(get(j, 'valid')) ?? false,
    );
  }
}

/// Question model
class HistoryQuestionDto {
  final int? id;
  final String label;
  final int? idDifficulty;
  final HistoryDifficultyDto? difficulty;
  final List<HistoryAnswerDto> answer;

  const HistoryQuestionDto({
    this.id,
    required this.label,
    this.idDifficulty,
    this.difficulty,
    required this.answer,
  });

  factory HistoryQuestionDto.fromJson(Map<String, dynamic> j) {
    final diffJson = get(j, 'difficulty');
    final answerJson = get(j, 'answer');

    final answers = <HistoryAnswerDto>[];
    if (answerJson is List) {
      for (final e in answerJson) {
        if (e is Map<String, dynamic>) {
          answers.add(HistoryAnswerDto.fromJson(e));
        }
      }
    }

    return HistoryQuestionDto(
      id: asInt(get(j, 'id')),
      label: asString(get(j, 'label')) ?? '',
      idDifficulty: asInt(get(j, 'idDifficulty')),
      difficulty: diffJson is Map<String, dynamic>
          ? HistoryDifficultyDto.fromJson(diffJson)
          : null,
      answer: answers,
    );
  }
}

/// User party question (user's answer to a question)
class UserPartyQuestionDto {
  final int? id;
  final int? idPartyQuestion;
  final int? idUser;
  final DateTime? dtPresentedAt;
  final DateTime? dtAnsweredAt;
  final int? idAnswer;
  final bool correct;
  final int score;
  final HistoryAnswerDto? answer;

  const UserPartyQuestionDto({
    this.id,
    this.idPartyQuestion,
    this.idUser,
    this.dtPresentedAt,
    this.dtAnsweredAt,
    this.idAnswer,
    required this.correct,
    required this.score,
    this.answer,
  });

  factory UserPartyQuestionDto.fromJson(Map<String, dynamic> j) {
    final answerJson = get(j, 'answer');

    return UserPartyQuestionDto(
      id: asInt(get(j, 'id')),
      idPartyQuestion: asInt(get(j, 'idPartyQuestion')),
      idUser: asInt(get(j, 'idUser')),
      dtPresentedAt: asDateTime(get(j, 'dtPresentedAt')),
      dtAnsweredAt: asDateTime(get(j, 'dtAnsweredAt')),
      idAnswer: asInt(get(j, 'idAnswer')),
      correct: asBool(get(j, 'correct')) ?? false,
      score: asInt(get(j, 'score')) ?? 0,
      answer: answerJson is Map<String, dynamic>
          ? HistoryAnswerDto.fromJson(answerJson)
          : null,
    );
  }
}

/// Party question
class HistoryPartyQuestionDto {
  final int? id;
  final int? idQuestion;
  final String? idParty;
  final int order;
  final HistoryQuestionDto? question;
  final UserPartyQuestionDto? userPartyQuestion;

  const HistoryPartyQuestionDto({
    this.id,
    this.idQuestion,
    this.idParty,
    required this.order,
    this.question,
    this.userPartyQuestion,
  });

  factory HistoryPartyQuestionDto.fromJson(Map<String, dynamic> j) {
    final questionJson = get(j, 'question');
    final upqJson = get(j, 'userPartyQuestion');

    return HistoryPartyQuestionDto(
      id: asInt(get(j, 'id')),
      idQuestion: asInt(get(j, 'idQuestion')),
      idParty: asString(get(j, 'idParty')),
      order: asInt(get(j, 'order')) ?? 0,
      question: questionJson is Map<String, dynamic>
          ? HistoryQuestionDto.fromJson(questionJson)
          : null,
      userPartyQuestion: upqJson is Map<String, dynamic>
          ? UserPartyQuestionDto.fromJson(upqJson)
          : null,
    );
  }
}

/// Party detail (full party with questions)
class PartyDetailDto {
  final String id;
  final DateTime? dt;
  final int? idPartyType;
  final int? idUserHost;

  final bool active;
  final bool finish;

  final bool? inProgress;   // <-- NEW (optionnel)
  final int? nbQuestions;   // <-- NEW (optionnel)

  final int? percent;
  final int? score;
  final int? time;
  final HistoryPartyTypeDto? partyType;
  final HistoryUserDto? user;
  final List<HistoryPartyDifficultyDto> partyDifficulty;
  final List<HistoryPartyThemeDto> partyTheme;
  final List<HistoryPartyQuestionDto> partyQuestions;

  const PartyDetailDto({
    required this.id,
    this.dt,
    this.idPartyType,
    this.idUserHost,
    required this.active,
    required this.finish,
    this.inProgress,
    this.nbQuestions,
    this.percent,
    this.score,
    this.time,
    this.partyType,
    this.user,
    required this.partyDifficulty,
    required this.partyTheme,
    required this.partyQuestions,
  });

  factory PartyDetailDto.fromJson(Map<String, dynamic> j) {
    final ptJson = get(j, 'partyType');
    final userJson = get(j, 'user');
    final pdJson = get(j, 'partyDifficulty');
    final ptmJson = get(j, 'partyTheme');
    final pqJson = get(j, 'partyQuestions');

    final inProg = asBool(get(j, 'inProgress'));

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

    final questions = <HistoryPartyQuestionDto>[];
    if (pqJson is List) {
      for (final e in pqJson) {
        if (e is Map<String, dynamic>) {
          questions.add(HistoryPartyQuestionDto.fromJson(e));
        }
      }
    }

    // Fallbacks:
    final active = asBool(get(j, 'active')) ?? (inProg ?? false);
    final finish = asBool(get(j, 'finish') ?? get(j, 'finished') ?? get(j, 'isFinished'))
        ?? ((inProg == true) ? false : false);

    return PartyDetailDto(
      id: asString(get(j, 'id')) ?? '',
      dt: asDateTime(get(j, 'dt')),
      idPartyType: asInt(get(j, 'idPartyType')),
      idUserHost: asInt(get(j, 'idUserHost')),
      active: active,
      finish: finish,
      inProgress: inProg,
      nbQuestions: asInt(get(j, 'nbQuestions')),
      percent: asInt(get(j, 'percent')),
      score: asInt(get(j, 'score')),
      time: asInt(get(j, 'time')),
      partyType: ptJson is Map<String, dynamic>
          ? HistoryPartyTypeDto.fromJson(ptJson)
          : null,
      user: userJson is Map<String, dynamic>
          ? HistoryUserDto.fromJson(userJson)
          : null,
      partyDifficulty: pds,
      partyTheme: themes,
      partyQuestions: questions,
    );
  }
}
