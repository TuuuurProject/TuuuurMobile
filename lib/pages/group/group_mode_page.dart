import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/navigation_header.dart';
import '../../navigation/app_router.dart';
import 'group_create_page.dart';
import 'group_join_page.dart';
import 'group_lobby_page.dart';

enum GroupStep { mode, create, join, lobby }

class GroupLobbyData {
  String code;
  List<String> categories;
  int questions;
  bool shuffle;
  String specifics;
  List<GroupPlayer> players;

  GroupLobbyData({
    this.code = 'TUR-0000',
    this.categories = const ['Général'],
    this.questions = 10,
    this.shuffle = true,
    this.specifics = '',
    this.players = const [],
  });
}

class GroupPlayer {
  final int id;
  final String name;
  final String emoji;
  final String status;

  const GroupPlayer({
    required this.id,
    required this.name,
    required this.emoji,
    this.status = 'Prêt',
  });
}

class GroupModePage extends StatefulWidget {
  const GroupModePage({super.key});

  @override
  State<GroupModePage> createState() => _GroupModePageState();
}

class _GroupModePageState extends State<GroupModePage> {
  GroupStep step = GroupStep.mode;
  GroupLobbyData lobby = GroupLobbyData(
    players: [
      const GroupPlayer(id: 1, name: 'Alice', emoji: '🦊'),
      const GroupPlayer(id: 2, name: 'Ben', emoji: '🐼'),
    ],
  );

  void goLobbyFromCreate({
    required List<String> categories,
    required int questions,
    required bool shuffle,
    String? specifics,
  }) {
    setState(() {
      lobby.categories = categories;
      lobby.questions = questions;
      lobby.shuffle = shuffle;
      lobby.specifics = specifics ?? '';
      lobby.code = 'TUR-${1000 + (DateTime.now().millisecond % 9000)}';
      step = GroupStep.lobby;
    });
  }

  void goLobbyFromJoin({required String code}) {
    setState(() {
      lobby.code = code;
      step = GroupStep.lobby;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // le système a déjà géré le pop
        context.goBack();
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: const NavigationHeader(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (step) {
      case GroupStep.mode:
        return _buildModeSelection();
      case GroupStep.create:
        return GroupCreatePage(
          onBack: () => setState(() => step = GroupStep.mode),
          onCreated: goLobbyFromCreate,
        );
      case GroupStep.join:
        return GroupJoinPage(
          onBack: () => setState(() => step = GroupStep.mode),
          onJoined: goLobbyFromJoin,
        );
      case GroupStep.lobby:
        return GroupLobbyPage(
          lobby: lobby,
          onBack: () => setState(() => step = GroupStep.mode),
        );
    }
  }

  Widget _buildModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (responsive)
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 420;

            final left = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.users,
                  color: TuuurTheme.brandPurple,
                  size: 28, // légèrement plus compact
                ),
                const SizedBox(width: 10),
                const Text(
                  'Mode Groupe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26, // compact
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ].animate().fadeIn(duration: 500.ms).slideX(begin: -0.25),
            );

            final right = Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: TuuurStyles.pill.copyWith(
                color: TuuurTheme.brandDarkGray.withOpacity(0.8),
                border: Border.all(
                  color: TuuurTheme.brandOrange.withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.house,
                    color: TuuurTheme.brandOrange,
                    size: 12,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Local / Affichage uniquement',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: TuuurTheme.brandOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms);

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [left, const SizedBox(height: 10), right],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: left),
                const SizedBox(width: 12),
                right,
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Interactive Cards (responsive, 1 colonne mobile / 2 colonnes desktop)
        LayoutBuilder(
          builder: (context, constraints) {
            final twoCols = constraints.maxWidth >= 680;
            if (twoCols) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                // pas de childAspectRatio rigide → la hauteur s’adapte au contenu
                children: [
                  _buildModeCard(
                    icon: FontAwesomeIcons.gamepad,
                    title: 'Créer une partie',
                    description:
                        'Définissez les paramètres et partagez le code/QR avec vos amis.',
                    color: TuuurTheme.brandPurple,
                    onTap: () => setState(() => step = GroupStep.create),
                    delay: 0,
                  ),
                  _buildModeCard(
                    icon: FontAwesomeIcons.rocket,
                    title: 'Rejoindre une partie',
                    description:
                        'Entrez un code pour rejoindre le lobby et commencer l\'aventure.',
                    color: TuuurTheme.brandOrange,
                    onTap: () => setState(() => step = GroupStep.join),
                    delay: 180,
                  ),
                ],
              );
            }

            // Mobile : une seule colonne, cartes pleine largeur
            return Column(
              children: [
                _buildModeCard(
                  icon: FontAwesomeIcons.gamepad,
                  title: 'Créer une partie',
                  description:
                      'Définissez les paramètres et partagez le code/QR avec vos amis.',
                  color: TuuurTheme.brandPurple,
                  onTap: () => setState(() => step = GroupStep.create),
                  delay: 0,
                ),
                const SizedBox(height: 16),
                _buildModeCard(
                  icon: FontAwesomeIcons.rocket,
                  title: 'Rejoindre une partie',
                  description:
                      'Entrez un code pour rejoindre le lobby et commencer l\'aventure.',
                  color: TuuurTheme.brandOrange,
                  onTap: () => setState(() => step = GroupStep.join),
                  delay: 160,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Tips Section (responsive)
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 420;
            final icon = Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: TuuurTheme.brandGreen.withOpacity(0.2),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.lightbulb,
                  color: TuuurTheme.brandGreen,
                  size: 14,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1800.ms);

            final textBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.bullseye,
                      color: TuuurTheme.brandPurple,
                      size: 12,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Conseils pour une partie réussie',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: TuuurTheme.brandLightGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...[
                  '• Choisissez des catégories que tous les joueurs apprécient',
                  '• Utilisez le mélange de questions pour plus de surprise',
                  '• Partagez le QR code pour un accès rapide',
                ].map(
                  (tip) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: TuuurTheme.brandGray,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            );

            return Container(
              padding: const EdgeInsets.all(18), // compact
              decoration: TuuurStyles.gamingCard,
              child: narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [icon, const SizedBox(height: 10), textBlock],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        icon,
                        const SizedBox(width: 14),
                        Expanded(child: textBlock),
                      ],
                    ),
            ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.25);
          },
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18), // compact
            decoration: TuuurStyles.gamingCard.copyWith(
              border: Border.all(color: color.withOpacity(0.28), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: color.withOpacity(0.2),
                      ),
                      child: Center(
                        child: FaIcon(icon, color: color, size: 18),
                      ),
                    ),
                    const Spacer(),
                    // petit accent animé discret
                    Container(
                      width: 0,
                      height: 2,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ).animate().scaleX(
                      duration: 450.ms,
                      delay: (delay + 700).ms,
                      curve: Curves.easeOutBack,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: TuuurTheme.brandGray,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: delay.ms, duration: 500.ms)
        .slideY(begin: 0.25, end: 0)
        .then()
        .shimmer(delay: (delay + 900).ms, duration: 1400.ms);
  }
}
