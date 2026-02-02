import '../../utils/encoding_utils.dart';

/// Data models for group/WebSocket system

/// User in a group party
class GroupUser {
  final int id;
  final String nickName;
  final String? email;
  final String? avatar;
  final bool isAdmin;
  final bool isNew;

  const GroupUser({
    required this.id,
    required this.nickName,
    this.email,
    this.avatar,
    this.isAdmin = false,
    this.isNew = false,
  });

  factory GroupUser.fromJson(Map<String, dynamic> json) {
    return GroupUser(
      id: json['id'] as int,
      nickName: fixUtf8Mojibake(json['nickName'] as String),
      email: fixUtf8MojibakeNullable(json['email'] as String?),
      avatar: fixUtf8MojibakeNullable(json['avatar'] as String?),
      isAdmin: json['isAdmin'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickName': nickName,
      'email': email,
      'avatar': avatar,
      'isAdmin': isAdmin,
      'isNew': isNew,
    };
  }

  @override
  String toString() => 'GroupUser(id: $id, nickName: $nickName)';
}

/// Question difficulty
class Difficulty {
  final int id;
  final String label;

  const Difficulty({required this.id, required this.label});

  factory Difficulty.fromJson(Map<String, dynamic> json) {
    return Difficulty(
      id: json['id'] as int,
      label: fixUtf8Mojibake(json['label'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label};
  }
}

/// Party theme
class Theme {
  final int id;
  final String label;

  const Theme({required this.id, required this.label});

  factory Theme.fromJson(Map<String, dynamic> json) {
    return Theme(
      id: json['id'] as int,
      label: fixUtf8Mojibake(json['label'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label};
  }
}

/// Party-user relation
class PartyUser {
  final int? idUser;
  final String? idParty;
  final GroupUser? user;

  const PartyUser({this.idUser, this.idParty, this.user});

  factory PartyUser.fromJson(Map<String, dynamic> json) {
    return PartyUser(
      idUser: json['idUser'] as int?,
      idParty: json['idParty'] as String?,
      user: json['user'] != null ? GroupUser.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'idUser': idUser, 'idParty': idParty, 'user': user?.toJson()};
  }
}

/// Party-theme relation
class PartyTheme {
  final int idTheme;
  final Theme theme;

  const PartyTheme({required this.idTheme, required this.theme});

  factory PartyTheme.fromJson(Map<String, dynamic> json) {
    return PartyTheme(
      idTheme: json['idTheme'] as int,
      theme: Theme.fromJson(json['theme']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'idTheme': idTheme, 'theme': theme.toJson()};
  }
}

/// Party-difficulty relation
class PartyDifficulty {
  final int idDifficulty;
  final Difficulty difficulty;

  const PartyDifficulty({required this.idDifficulty, required this.difficulty});

  factory PartyDifficulty.fromJson(Map<String, dynamic> json) {
    return PartyDifficulty(
      idDifficulty: json['idDifficulty'] as int,
      difficulty: Difficulty.fromJson(json['difficulty']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'idDifficulty': idDifficulty, 'difficulty': difficulty.toJson()};
  }
}

/// Group party
class GroupParty {
  final String id; // GUID
  final String code;
  final int nbQuestions;
  final bool inProgress;
  final bool scoreEachRound;
  final int idPartyType;
  final int idUserHost;
  final bool active;
  final bool finish;
  final String dt; // ISO 8601 date
  final List<PartyUser> partyUsers;
  final List<PartyTheme> partyTheme;
  final List<PartyDifficulty> partyDifficulty;
  final double percent;
  final int score;
  final int time;

  const GroupParty({
    required this.id,
    required this.code,
    required this.nbQuestions,
    required this.inProgress,
    required this.scoreEachRound,
    required this.idPartyType,
    required this.idUserHost,
    required this.active,
    required this.finish,
    required this.dt,
    required this.partyUsers,
    required this.partyTheme,
    required this.partyDifficulty,
    required this.percent,
    required this.score,
    required this.time,
  });

  factory GroupParty.fromJson(Map<String, dynamic> json) {
    return GroupParty(
      id: fixUtf8Mojibake(json['id'] as String),
      code: fixUtf8Mojibake(json['code'] as String),
      nbQuestions: json['nbQuestions'] as int,
      inProgress: json['inProgress'] as bool,
      scoreEachRound: json['scoreEachRound'] as bool,
      idPartyType: json['idPartyType'] as int,
      idUserHost: json['idUserHost'] as int,
      active: json['active'] as bool,
      finish: json['finish'] as bool,
      dt: fixUtf8Mojibake(json['dt'] as String),
      partyUsers:
          (json['partyUsers'] as List?)
              ?.map((e) => PartyUser.fromJson(e))
              .toList() ??
          [],
      partyTheme:
          (json['partyTheme'] as List?)
              ?.map((e) => PartyTheme.fromJson(e))
              .toList() ??
          [],
      partyDifficulty:
          (json['partyDifficulty'] as List?)
              ?.map((e) => PartyDifficulty.fromJson(e))
              .toList() ??
          [],
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
      score: json['score'] as int? ?? 0,
      time: json['time'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'nbQuestions': nbQuestions,
      'inProgress': inProgress,
      'scoreEachRound': scoreEachRound,
      'idPartyType': idPartyType,
      'idUserHost': idUserHost,
      'active': active,
      'finish': finish,
      'dt': dt,
      'partyUsers': partyUsers.map((e) => e.toJson()).toList(),
      'partyTheme': partyTheme.map((e) => e.toJson()).toList(),
      'partyDifficulty': partyDifficulty.map((e) => e.toJson()).toList(),
      'percent': percent,
      'score': score,
      'time': time,
    };
  }

  GroupParty copyWith({
    String? id,
    String? code,
    int? nbQuestions,
    bool? inProgress,
    bool? scoreEachRound,
    int? idPartyType,
    int? idUserHost,
    bool? active,
    bool? finish,
    String? dt,
    List<PartyUser>? partyUsers,
    List<PartyTheme>? partyTheme,
    List<PartyDifficulty>? partyDifficulty,
    double? percent,
    int? score,
    int? time,
  }) {
    return GroupParty(
      id: id ?? this.id,
      code: code ?? this.code,
      nbQuestions: nbQuestions ?? this.nbQuestions,
      inProgress: inProgress ?? this.inProgress,
      scoreEachRound: scoreEachRound ?? this.scoreEachRound,
      idPartyType: idPartyType ?? this.idPartyType,
      idUserHost: idUserHost ?? this.idUserHost,
      active: active ?? this.active,
      finish: finish ?? this.finish,
      dt: dt ?? this.dt,
      partyUsers: partyUsers ?? this.partyUsers,
      partyTheme: partyTheme ?? this.partyTheme,
      partyDifficulty: partyDifficulty ?? this.partyDifficulty,
      percent: percent ?? this.percent,
      score: score ?? this.score,
      time: time ?? this.time,
    );
  }

  @override
  String toString() =>
      'GroupParty(id: $id, code: $code, inProgress: $inProgress)';
}

/// Answer to a question
class Answer {
  final int id;
  final int idQuestion;
  final String value;
  final bool? valid; // null if not revealed yet, true/false if revealed

  const Answer({
    required this.id,
    required this.idQuestion,
    required this.value,
    this.valid,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as int,
      idQuestion: json['idQuestion'] as int,
      value: fixUtf8Mojibake(json['value'] as String),
      valid: json['valid'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'idQuestion': idQuestion, 'value': value, 'valid': valid};
  }
}

class Question {
  final int id;
  final String label;
  final int idDifficulty;
  final Difficulty difficulty;
  final List<Answer> answer;

  const Question({
    required this.id,
    required this.label,
    required this.idDifficulty,
    required this.difficulty,
    required this.answer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      label: fixUtf8Mojibake(json['label'] as String),
      idDifficulty: json['idDifficulty'] as int,
      difficulty: Difficulty.fromJson(json['difficulty']),
      answer:
          (json['answer'] as List?)?.map((e) => Answer.fromJson(e)).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'idDifficulty': idDifficulty,
      'difficulty': difficulty.toJson(),
      'answer': answer.map((e) => e.toJson()).toList(),
    };
  }
}

/// Group question with context
class GroupQuestion {
  final Question question;
  final int currentIndex; // Question index (starts at 1)
  final int score; // Potential score for this question

  const GroupQuestion({
    required this.question,
    required this.currentIndex,
    required this.score,
  });

  factory GroupQuestion.fromJson(Map<String, dynamic> json) {
    return GroupQuestion(
      question: Question.fromJson(json['question']),
      currentIndex: json['currentIndex'] as int,
      score: json['score'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question.toJson(),
      'currentIndex': currentIndex,
      'score': score,
    };
  }
}

/// User score
class UserScore {
  final int score;
  final GroupUser user;

  const UserScore({required this.score, required this.user});

  factory UserScore.fromJson(Map<String, dynamic> json) {
    return UserScore(
      score: json['score'] as int,
      user: GroupUser.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'score': score, 'user': user.toJson()};
  }

  @override
  String toString() => 'UserScore(user: ${user.nickName}, score: $score)';
}

/// Question history with user's answer
class QuestionHistory {
  final GroupQuestion groupQuestion;
  final int? userAnswerId; // ID of user's selected answer
  final bool wasCorrect; // Whether user answered correctly
  final int scoreGained; // Points gained for this question

  const QuestionHistory({
    required this.groupQuestion,
    this.userAnswerId,
    required this.wasCorrect,
    required this.scoreGained,
  });

  /// Returns the Answer corresponding to userAnswerId
  Answer? get userAnswer {
    if (userAnswerId == null) return null;
    try {
      return groupQuestion.question.answer.firstWhere(
        (a) => a.id == userAnswerId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns the correct answer
  Answer? get correctAnswer {
    try {
      return groupQuestion.question.answer.firstWhere((a) => a.valid == true);
    } catch (e) {
      return null;
    }
  }
}

/// Parameters for updating a party
class GroupSettingsRequest {
  final List<int> themes;
  final List<int> difficulties;
  final int nbQuestions;
  final bool scoreEachRound;

  const GroupSettingsRequest({
    required this.themes,
    required this.difficulties,
    required this.nbQuestions,
    required this.scoreEachRound,
  });

  Map<String, dynamic> toJson() {
    return {
      'themes': themes,
      'difficulties': difficulties,
      'nbQuestions': nbQuestions,
      'scoreEachRound': scoreEachRound,
    };
  }
}

/// Request to join a party
class JoinGroupRequest {
  final String code;

  const JoinGroupRequest({required this.code});

  Map<String, dynamic> toJson() {
    return {'code': code};
  }
}
