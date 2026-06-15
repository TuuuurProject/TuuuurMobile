import '../api_helpers.dart';

/// Un joueur dans le classement Ranked (/api/v1/ranked/ranking).
class RankingUser {
  final String id;
  final String nickName;
  final String? email;
  final String? avatar;
  final int globalElo;
  final int userRanking;

  const RankingUser({
    required this.id,
    required this.nickName,
    this.email,
    this.avatar,
    required this.globalElo,
    required this.userRanking,
  });

  String get displayName => nickName.isNotEmpty ? nickName : 'Joueur';

  factory RankingUser.fromJson(Map<String, dynamic> j) {
    return RankingUser(
      id: asString(get(j, 'id')) ?? '',
      nickName: asString(get(j, 'nickName')) ?? '',
      email: asString(get(j, 'email')),
      avatar: asString(get(j, 'avatar')),
      globalElo: asInt(get(j, 'globalElo')) ?? 0,
      userRanking: asInt(get(j, 'userRanking')) ?? 0,
    );
  }
}

/// Réponse paginée du classement Ranked.
class RankingPageDto {
  final List<RankingUser> users;

  /// Rang global de l'utilisateur courant.
  final int userRanking;

  /// ELO global de l'utilisateur courant.
  final int userElo;

  final int currentPage;
  final int totalPages;
  final int totalUsers;
  final int userTier;
  final int userDivision;

  const RankingPageDto({
    required this.users,
    required this.userRanking,
    required this.userElo,
    required this.currentPage,
    required this.totalPages,
    required this.totalUsers,
    required this.userTier,
    required this.userDivision,
  });

  factory RankingPageDto.fromJson(Map<String, dynamic> j) {
    final usersJson = get(j, 'users');
    final users = <RankingUser>[];
    if (usersJson is List) {
      for (final e in usersJson) {
        if (e is Map<String, dynamic>) {
          users.add(RankingUser.fromJson(e));
        }
      }
    }

    return RankingPageDto(
      users: users,
      userRanking: asInt(get(j, 'userRanking')) ?? 0,
      userElo: asInt(get(j, 'userElo')) ?? 0,
      currentPage: asInt(get(j, 'currentPage')) ?? 1,
      totalPages: asInt(get(j, 'totalPages')) ?? 1,
      totalUsers: asInt(get(j, 'totalUsers')) ?? users.length,
      userTier: asInt(get(j, 'userTier')) ?? 0,
      userDivision: asInt(get(j, 'userDivision')) ?? 0,
    );
  }
}
