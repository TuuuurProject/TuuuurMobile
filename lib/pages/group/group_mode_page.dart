import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/group_api_service.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/navigation_header.dart';

import '../../navigation/app_router.dart';
import 'group_create_page.dart';
import 'group_join_page.dart';
import 'group_lobby_page.dart';

enum GroupStep { mode, create, join, lobby }

class GroupLobbyData {
  /// "code" qu’on affiche et partage.
  /// Vu ton Swagger, on utilise l’UUID renvoyé par l’API comme code.
  String code;

  /// Identifiant de party côté backend (souvent identique au code ici).
  String partyId;

  bool isHost;

  /// Affichage seulement (noms)
  List<String> categories;

  /// Pour l’API (ids)
  List<int> themeIds;
  List<int> difficultyIds;

  int questions;
  bool shuffle;
  String specifics;

  /// Sans websocket : liste locale (démo)
  List<GroupPlayer> players;

  GroupLobbyData({
    this.code = '',
    this.partyId = '',
    this.isHost = false,
    this.categories = const [],
    this.themeIds = const [],
    this.difficultyIds = const [],
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
  /// Injection test / override
  final GroupApi? groupApiOverride;

  const GroupModePage({super.key, this.groupApiOverride});

  @override
  State<GroupModePage> createState() => _GroupModePageState();
}

class _GroupModePageState extends State<GroupModePage> {
  GroupApi get _api => widget.groupApiOverride ?? groupApi;

  GroupStep step = GroupStep.mode;
  GroupLobbyData lobby = GroupLobbyData();

  void goLobbyFromCreate({
    required String partyId,
    required String code,
    required List<String> categories,
    required List<int> themeIds,
    required List<int> difficultyIds,
    required int questions,
    required bool shuffle,
    String? specifics,
  }) {
    setState(() {
      lobby = GroupLobbyData(
        partyId: partyId,
        code: code,
        isHost: true,
        categories: categories,
        themeIds: themeIds,
        difficultyIds: difficultyIds,
        questions: questions,
        shuffle: shuffle,
        specifics: specifics ?? '',
        players: const [], // websocket plus tard
      );
      step = GroupStep.lobby;
    });
  }

  void goLobbyFromJoin({
    required String partyId,
    required String code,
  }) {
    setState(() {
      lobby = GroupLobbyData(
        partyId: partyId,
        code: code,
        isHost: false,
        categories: const [],
        themeIds: const [],
        difficultyIds: const [],
        questions: 10,
        shuffle: true,
        specifics: '',
        players: const [],
      );
      step = GroupStep.lobby;
    });
  }

  void resetToMode() {
    setState(() {
      lobby = GroupLobbyData();
      step = GroupStep.mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goBack();
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: const NavigationHeader(),
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (step) {
      case GroupStep.mode:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildModeSelection(),
        );

      case GroupStep.create:
        return GroupCreatePage(
          groupApiOverride: _api,
          onBack: resetToMode,
          onCreated: goLobbyFromCreate,
        );

      case GroupStep.join:
        return GroupJoinPage(
          groupApiOverride: _api,
          onBack: resetToMode,
          onJoined: goLobbyFromJoin,
        );

      case GroupStep.lobby:
        return GroupLobbyPage(
          groupApiOverride: _api,
          lobby: lobby,
          onBack: resetToMode,
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
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Mode Groupe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
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
                    FontAwesomeIcons.plug,
                    color: TuuurTheme.brandOrange,
                    size: 12,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'API (sans websocket)',
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
                children: [
                  _buildModeCard(
                    icon: FontAwesomeIcons.gamepad,
                    title: 'Créer une partie',
                    description:
                        'Créez un lobby (API) puis partagez le code (UUID) / QR.',
                    color: TuuurTheme.brandPurple,
                    onTap: () => setState(() => step = GroupStep.create),
                    delay: 0,
                  ),
                  _buildModeCard(
                    icon: FontAwesomeIcons.rocket,
                    title: 'Rejoindre une partie',
                    description:
                        'Entrez un code (UUID ou TUR-xxxx si ton backend en génère un).',
                    color: TuuurTheme.brandOrange,
                    onTap: () => setState(() => step = GroupStep.join),
                    delay: 180,
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildModeCard(
                  icon: FontAwesomeIcons.gamepad,
                  title: 'Créer une partie',
                  description:
                      'Créez un lobby (API) puis partagez le code (UUID) / QR.',
                  color: TuuurTheme.brandPurple,
                  onTap: () => setState(() => step = GroupStep.create),
                  delay: 0,
                ),
                const SizedBox(height: 16),
                _buildModeCard(
                  icon: FontAwesomeIcons.rocket,
                  title: 'Rejoindre une partie',
                  description:
                      'Entrez un code (UUID ou TUR-xxxx si ton backend en génère un).',
                  color: TuuurTheme.brandOrange,
                  onTap: () => setState(() => step = GroupStep.join),
                  delay: 160,
                ),
              ],
            );
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
            padding: const EdgeInsets.all(18),
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
