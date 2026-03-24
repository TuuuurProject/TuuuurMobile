import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/api_module.dart';
import '../../api/group/group_api_service.dart';
import '../../stores/group_coordinator.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/navigation_header.dart';

import '../../navigation/app_router.dart';
import '../../stores/auth_store.dart';
import 'group_join_page.dart';
import 'group_lobby_page.dart';

enum GroupStep { mode, join, lobby }

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
  bool scoreEachRound;
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
    this.scoreEachRound = false,
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
  final GroupCoordinator? groupCoordinatorOverride;

  const GroupModePage({
    super.key,
    this.groupApiOverride,
    this.groupCoordinatorOverride,
  });

  @override
  State<GroupModePage> createState() => _GroupModePageState();
}

class _GroupModePageState extends State<GroupModePage> {
  GroupApi get _api => widget.groupApiOverride ?? ApiModule.instance.groupApi;
  GroupCoordinator get _coordinator =>
      widget.groupCoordinatorOverride ?? ApiModule.instance.groupCoordinator;

  GroupStep step = GroupStep.mode;
  bool _creatingParty = false;

  /// Crée directement une partie avec des paramètres par défaut
  Future<void> _createPartyDirectly() async {
    if (_creatingParty) return;

    setState(() {
      _creatingParty = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final authStore = MyAuthStore.of(context);
      final currentUserId = authStore.user?.id;

      // Créer et rejoindre la partie via le coordinateur
      final lobbyCode = await _coordinator.createAndJoinParty(
        currentUserId: currentUserId,
      );

      if (!mounted) return;

      if (lobbyCode == null) {
        setState(() => _creatingParty = false);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Impossible de créer la partie.'),
            backgroundColor: TuuurTheme.brandOrange,
          ),
        );
        return;
      }

      // Paramètres par défaut
      const defaultThemeIds = [1]; // Thème "Général" par défaut
      const defaultDifficultyIds = [2]; // Difficulté "Moyen" par défaut
      const defaultQuestions = 10;
      const defaultScoreEachRound = false;

      // Mettre à jour les paramètres de la partie
      final settingsUpdated = await _coordinator.updatePartySettings(
        themes: defaultThemeIds,
        difficulties: defaultDifficultyIds,
        nbQuestions: defaultQuestions,
        scoreEachRound: defaultScoreEachRound,
      );

      if (!mounted) return;

      if (!settingsUpdated) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Partie créée mais erreur lors de la mise à jour des paramètres.',
            ),
            backgroundColor: TuuurTheme.brandOrange,
          ),
        );
      }

      final party = _coordinator.store.currentParty;
      final partyId = party?.id ?? '';

      setState(() => _creatingParty = false);

      // Passer au lobby
      goLobbyFromCreate(
        partyId: partyId,
        code: lobbyCode,
        categories: const ['Général'],
        themeIds: defaultThemeIds,
        difficultyIds: defaultDifficultyIds,
        questions: defaultQuestions,
        shuffle: true,
        scoreEachRound: defaultScoreEachRound,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingParty = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: TuuurTheme.brandOrange,
        ),
      );
    }
  }

  void goLobbyFromCreate({
    required String partyId,
    required String code,
    required List<String> categories,
    required List<int> themeIds,
    required List<int> difficultyIds,
    required int questions,
    required bool shuffle,
    required bool scoreEachRound,
    String? specifics,
  }) {
    // Préparer les données du lobby
    final lobbyData = GroupLobbyData(
      partyId: partyId,
      code: code,
      isHost: true,
      categories: categories,
      themeIds: themeIds,
      difficultyIds: difficultyIds,
      questions: questions,
      shuffle: shuffle,
      scoreEachRound: scoreEachRound,
      specifics: specifics ?? '',
    );

    // Navigation vers GroupLobbyPage
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => GroupLobbyPage(
              lobby: lobbyData,
              onBack: () {
                Navigator.of(context).pop();
              },
              groupCoordinatorOverride: widget.groupCoordinatorOverride,
            ),
          ),
        )
        .then((_) {
          if (AuthStore.instance.isGuest) AuthStore.instance.signOut();
        });
  }

  void goLobbyFromJoin({required String partyId, required String code}) {
    // Préparer les données du lobby
    final lobbyData = GroupLobbyData(
      partyId: partyId,
      code: code,
      isHost: false,
    );

    // Navigation vers GroupLobbyPage
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => GroupLobbyPage(
              lobby: lobbyData,
              onBack: () {
                Navigator.of(context).pop();
              },
              groupCoordinatorOverride: widget.groupCoordinatorOverride,
            ),
          ),
        )
        .then((_) {
          if (AuthStore.instance.isGuest) AuthStore.instance.signOut();
        });
  }

  Future<void> resetToMode() async {
    // Ne pas appeler leaveParty() ici car la page enfant l'a déjà fait
    // Appeler leaveParty() ici causerait des appels multiples et des erreurs

    setState(() {
      step = GroupStep.mode;
    });
  }

  @override
  void dispose() {
    if (AuthStore.instance.isGuest) {
      AuthStore.instance.signOut();
    }
    super.dispose();
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
        resizeToAvoidBottomInset: true,
        backgroundColor: TuuurTheme.brandDark,
        appBar: const NavigationHeader(showBack: true),
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

      case GroupStep.join:
        return GroupJoinPage(
          groupApiOverride: _api,
          groupCoordinatorOverride: widget.groupCoordinatorOverride,
          onBack: resetToMode,
          onJoined: goLobbyFromJoin,
        );

      case GroupStep.lobby:
        // Ne devrait plus arriver ici car on fait une vraie navigation
        return const Center(
          child: CircularProgressIndicator(color: TuuurTheme.brandPurple),
        );
    }
  }

  Widget _buildModeSelection() {
    final isAuthenticated = MyAuthStore.of(context).isAuthenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (responsive)
        Row(
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
                    description: isAuthenticated
                        ? 'Définissez les paramètres et partagez le code/QR avec vos amis.'
                        : 'Connectez-vous pour créer une partie.',
                    color: isAuthenticated
                        ? TuuurTheme.brandPurple
                        : TuuurTheme.brandGray,
                    onTap: (!isAuthenticated || _creatingParty)
                        ? null
                        : _createPartyDirectly,
                    delay: 0,
                    isLoading: _creatingParty,
                  ),
                  _buildModeCard(
                    icon: FontAwesomeIcons.rocket,
                    title: 'Rejoindre une partie',
                    description:
                        "Entrez un code pour rejoindre le lobby et commencer l'aventure.",
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
                  description: isAuthenticated
                      ? 'Créez instantanément un lobby et partagez le code.'
                      : 'Connectez-vous pour créer une partie.',
                  color: isAuthenticated
                      ? TuuurTheme.brandPurple
                      : TuuurTheme.brandGray,
                  onTap: (!isAuthenticated || _creatingParty)
                      ? null
                      : _createPartyDirectly,
                  delay: 0,
                  isLoading: _creatingParty,
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
    required VoidCallback? onTap,
    required int delay,
    bool isLoading = false,
  }) {
    return GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.6 : 1.0,
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
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: color,
                                  ),
                                )
                              : FaIcon(icon, color: color, size: 18),
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
          ),
        )
        .animate()
        .fadeIn(delay: delay.ms, duration: 500.ms)
        .slideY(begin: 0.25, end: 0)
        .then()
        .shimmer(delay: (delay + 900).ms, duration: 1400.ms);
  }
}
