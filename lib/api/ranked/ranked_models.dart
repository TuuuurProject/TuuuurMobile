import '../../utils/encoding_utils.dart';

/// Data models for Ranked WebSocket system

class RankedUser {
  final String id;
  final String nickName;
  final String? email;
  final String? avatar;
  final bool isAdmin;
  final bool isNew;
  final bool isGoogleUser;
  final bool isInvitedUser;
  final int globalElo;

  const RankedUser({
    required this.id,
    required this.nickName,
    this.email,
    this.avatar,
    this.isAdmin = false,
    this.isNew = false,
    this.isGoogleUser = false,
    this.isInvitedUser = false,
    required this.globalElo,
  });

  factory RankedUser.fromJson(Map<String, dynamic> json) {
    return RankedUser(
      id: json['id']?.toString() ?? '',
      nickName: fixUtf8Mojibake(json['nickName']?.toString() ?? 'Player'),
      email: fixUtf8MojibakeNullable(json['email']?.toString()),
      avatar: fixUtf8MojibakeNullable(json['avatar']?.toString()),
      isAdmin: json['isAdmin'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
      isGoogleUser: json['isGoogleUser'] as bool? ?? false,
      isInvitedUser: json['isInvitedUser'] as bool? ?? false,
      globalElo: (json['globalElo'] as num?)?.toInt() ?? 1500,
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
      'isGoogleUser': isGoogleUser,
      'isInvitedUser': isInvitedUser,
      'globalElo': globalElo,
    };
  }
}

class RankedDifficulty {
  final int id;
  final String label;

  const RankedDifficulty({required this.id, required this.label});

  factory RankedDifficulty.fromJson(Map<String, dynamic> json) {
    return RankedDifficulty(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: fixUtf8Mojibake(json['label']?.toString() ?? 'Unknown'),
    );
  }
}

class RankedAnswerOption {
  final int id;
  final String label;
  final bool? valid;

  const RankedAnswerOption({
    required this.id,
    required this.label,
    this.valid,
  });

  factory RankedAnswerOption.fromJson(Map<String, dynamic> json) {
    final text = json['value']?.toString() ?? json['label']?.toString() ?? '';
    return RankedAnswerOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: fixUtf8Mojibake(text),
      valid: json['valid'] as bool?,
    );
  }
}

class RankedQuestionBase {
  final int id;
  final String label;
  final int idDifficulty;
  final List<RankedAnswerOption> answer;
  final RankedDifficulty? difficulty;

  const RankedQuestionBase({
    required this.id,
    required this.label,
    required this.idDifficulty,
    required this.answer,
    this.difficulty,
  });

  factory RankedQuestionBase.fromJson(Map<String, dynamic> json) {
    return RankedQuestionBase(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: fixUtf8Mojibake(json['label']?.toString() ?? 'Question'),
      idDifficulty: (json['idDifficulty'] as num?)?.toInt() ?? 0,
      answer:
          (json['answer'] as List<dynamic>?)
              ?.map(
                (e) => RankedAnswerOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      difficulty: json['difficulty'] != null
          ? RankedDifficulty.fromJson(
              json['difficulty'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class RankedQuestion {
  final RankedQuestionBase question;
  final int currentIndex;
  final int score;
  final double multiplier;

  const RankedQuestion({
    required this.question,
    required this.currentIndex,
    required this.score,
    required this.multiplier,
  });

  factory RankedQuestion.fromJson(Map<String, dynamic> json) {
    return RankedQuestion(
      question: json['question'] != null
          ? RankedQuestionBase.fromJson(
              json['question'] as Map<String, dynamic>,
            )
          : const RankedQuestionBase(
              id: 0,
              label: "Erreur de question",
              idDifficulty: 0,
              answer: [],
            ),
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class RankedUserScore {
  final int score;
  final RankedUser user;

  const RankedUserScore({required this.score, required this.user});

  factory RankedUserScore.fromJson(Map<String, dynamic> json) {
    return RankedUserScore(
      score: (json['score'] as num?)?.toInt() ?? 0,
      user: json['user'] != null
          ? RankedUser.fromJson(json['user'] as Map<String, dynamic>)
          : const RankedUser(id: "0", nickName: "Player", globalElo: 1500),
    );
  }
}

class RankedUserAnswered {
  final bool correct;
  final RankedUser user;

  const RankedUserAnswered({required this.correct, required this.user});

  factory RankedUserAnswered.fromJson(Map<String, dynamic> json) {
    return RankedUserAnswered(
      correct: json['correct'] as bool? ?? false,
      user: json['user'] != null
          ? RankedUser.fromJson(json['user'] as Map<String, dynamic>)
          : const RankedUser(id: "0", nickName: "Player", globalElo: 1500),
    );
  }
}
