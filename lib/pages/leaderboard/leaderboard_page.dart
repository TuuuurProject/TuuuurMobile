import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';
import '../../navigation/route_history.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // Données identiques à Vue.js
  final List<Map<String, dynamic>> players = [
    {'rank': 1, 'name': 'Ava', 'elo': 1639},
    {'rank': 2, 'name': 'Liam', 'elo': 1627},
    {'rank': 3, 'name': 'Emma', 'elo': 1615},
    {'rank': 4, 'name': 'Noah', 'elo': 1603},
    {'rank': 5, 'name': 'Mia', 'elo': 1591},
    {'rank': 6, 'name': 'Lucas', 'elo': 1579},
    {'rank': 7, 'name': 'Zoé', 'elo': 1567},
    {'rank': 8, 'name': 'Leo', 'elo': 1555},
    {'rank': 9, 'name': 'Luna', 'elo': 1543},
    {'rank': 10, 'name': 'Hugo', 'elo': 1531},
    {'rank': 11, 'name': 'Chloé', 'elo': 1519},
    {'rank': 12, 'name': 'Nina', 'elo': 1507},
    {'rank': 13, 'name': 'Evan', 'elo': 1495},
    {'rank': 14, 'name': 'Jade', 'elo': 1483},
    {'rank': 15, 'name': 'Axel', 'elo': 1471},
    {'rank': 16, 'name': 'Léa', 'elo': 1459},
    {'rank': 17, 'name': 'Sacha', 'elo': 1447},
    {'rank': 18, 'name': 'Maël', 'elo': 1435},
    {'rank': 19, 'name': 'Eva', 'elo': 1423},
    {'rank': 20, 'name': 'Yanis', 'elo': 1411},
  ];

  List<Map<String, dynamic>> get top => players.take(3).toList();
  List<Map<String, dynamic>> get rest => players.skip(3).toList();

  String avatarUrl(String name) {
    final seed = Uri.encodeComponent(name);
    return 'https://api.dicebear.com/9.x/adventurer-neutral/svg?seed=$seed';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // le système a déjà géré le pop
        RouteHistory.instance.navigateBack(context);
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: const NavigationHeader(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header identique à Vue.js mais responsive
              _buildHeader(),
              const SizedBox(height: 32),

              // Podium top 3
              _buildPodium(),
              const SizedBox(height: 32),

              // Liste du classement
              _buildLeaderboardList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;

        final badge =
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: TuuurTheme.brandOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TuuurTheme.brandOrange.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Top 20 Légendes',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: TuuurTheme.brandOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .fade(duration: 2000.ms, curve: Curves.easeInOut);

        if (narrow) {
          // Empile pour éviter l’overflow
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏆 Classement Gaming',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
              const SizedBox(height: 12),
              badge,
            ],
          );
        }

        // Largeur suffisante : aligné sur une ligne
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                '🏆 Classement Gaming',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ),
            const SizedBox(width: 12),
            badge,
          ],
        );
      },
    );
  }

  Widget _buildPodium() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2ème place
              Expanded(child: _buildPodiumCard(top[1], 2)),
              const SizedBox(width: 16),
              // 1ère place (plus grande)
              Expanded(child: _buildPodiumCard(top[0], 1)),
              const SizedBox(width: 16),
              // 3ème place
              Expanded(child: _buildPodiumCard(top[2], 3)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildPodiumCard(top[0], 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildPodiumCard(top[1], 2)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPodiumCard(top[2], 3)),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> player, int rank) {
    final isFirst = rank == 1;
    final isSecond = rank == 2;

    Color borderColor = isFirst
        ? TuuurTheme.brandYellow
        : isSecond
        ? TuuurTheme.brandOrange
        : TuuurTheme.brandGray;

    String medal = isFirst
        ? '⭐'
        : isSecond
        ? '🔥'
        : '🥉';

    double avatarSize = isFirst
        ? 80
        : isSecond
        ? 64
        : 56;
    double titleSize = isFirst
        ? 24
        : isSecond
        ? 20
        : 18;

    return GamingCard(
      child: Column(
        children: [
          // Médaille/Icône
          Container(
                width: isFirst ? 48 : (isSecond ? 32 : 28),
                height: isFirst ? 48 : (isSecond ? 32 : 28),
                margin: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Icon(
                    FontAwesomeIcons.trophy,
                    color: borderColor,
                    size: isFirst ? 32 : (isSecond ? 24 : 20),
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 4000.ms),

          // Avatar avec badge de rang
          Stack(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isFirst ? 4 : 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    avatarUrl(player['name']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: TuuurTheme.brandDarkGray,
                      child: Icon(
                        Icons.person,
                        color: borderColor,
                        size: avatarSize * 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: isFirst ? 32 : 24,
                  height: isFirst ? 32 : 24,
                  decoration: BoxDecoration(
                    color: borderColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: TuuurTheme.brandDark, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: isFirst ? TuuurTheme.brandDark : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isFirst ? 16 : 12,
                      ),
                    ),
                  ),
                ),
              ),
              if (isFirst)
                Positioned(
                  bottom: -4,
                  left: avatarSize / 2 - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: TuuurTheme.brandGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: TuuurTheme.brandDark, width: 2),
                    ),
                    child: const Center(
                      child: Text('👑', style: TextStyle(fontSize: 8)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Nom du joueur
          Text(
            '#$rank ${player['name']}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ),
          const SizedBox(height: 8),

          // Badge Élo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor.withOpacity(0.4), width: 1),
            ),
            child: Text(
              '$medal ${player['elo']} Élo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: borderColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la liste — responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;

              final title = Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: TuuurTheme.brandPurple.withOpacity(0.2),
                    ),
                    child: const Center(
                      child: Text('📊', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Classement Complet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: TuuurTheme.brandLightGray,
                      ),
                    ),
                  ),
                ],
              );

              final chip = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TuuurTheme.brandCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TuuurTheme.brandCyan.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Mise à jour en temps réel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TuuurTheme.brandCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 8), chip],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  chip,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: TuuurTheme.brandPurple.withOpacity(0.2)),
          const SizedBox(height: 16),

          // Liste des joueurs 4-20
          ...rest.map((player) => _buildPlayerRow(player)).toList(),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player) {
    final rank = player['rank'];
    final isTopTen = rank <= 10;
    final isTopFive = rank <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Numéro de rang
              SizedBox(
                width: 48,
                height: 32,
                child: Center(
                  child: Text(
                    '#$rank',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isTopTen
                          ? TuuurTheme.brandPurple
                          : TuuurTheme.brandGray,
                    ),
                  ),
                ),
              ),

              // Avatar
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TuuurTheme.brandPurple.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        avatarUrl(player['name']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: TuuurTheme.brandDarkGray,
                          child: const Icon(
                            Icons.person,
                            color: TuuurTheme.brandPurple,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isTopFive)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: TuuurTheme.brandGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🔥', style: TextStyle(fontSize: 8)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Informations du joueur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: TuuurTheme.brandLightGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTopFive
                          ? 'Champion actuel'
                          : isTopTen
                          ? 'Challenger'
                          : 'Joueur confirmé',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isTopFive
                            ? TuuurTheme.brandGreen
                            : isTopTen
                            ? TuuurTheme.brandOrange
                            : TuuurTheme.brandGray,
                      ),
                    ),
                  ],
                ),
              ),

              // Score Élo (compact, non expansif)
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (isTopFive
                              ? TuuurTheme.brandGreen
                              : isTopTen
                              ? TuuurTheme.brandOrange
                              : TuuurTheme.brandPurple)
                          .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (isTopFive
                                ? TuuurTheme.brandGreen
                                : isTopTen
                                ? TuuurTheme.brandOrange
                                : TuuurTheme.brandPurple)
                            .withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  '⚡ ${player['elo']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isTopFive
                        ? TuuurTheme.brandGreen
                        : isTopTen
                        ? TuuurTheme.brandOrange
                        : TuuurTheme.brandPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
