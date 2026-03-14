import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/api_module.dart';
import '../../api/group/group_api_service.dart';
import '../../api/group/group_models.dart';
import '../../stores/auth_store.dart';
import '../../stores/group_coordinator.dart';
import '../../stores/group_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../utils/clipboard_utils.dart';
import '../../widgets/tuuur_pills.dart';
import '../../widgets/gaming_icon_button.dart';
import '../../widgets/sticky_bottom_bar.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';
import '../../navigation/app_router.dart';
import '../../navigation/navigation_utils.dart';
import 'group_mode_page.dart';
import 'group_settings_page.dart';
import 'group_quiz_page.dart';
import 'group_results_page.dart';
import 'qr_preview_widget.dart';

class GroupLobbyPage extends StatefulWidget {
  final GroupLobbyData lobby;
  final VoidCallback onBack;
  final GroupApi? groupApiOverride;
  final GroupCoordinator? groupCoordinatorOverride;

  const GroupLobbyPage({
    super.key,
    required this.lobby,
    required this.onBack,
    this.groupApiOverride,
    this.groupCoordinatorOverride,
  });

  @override
  State<GroupLobbyPage> createState() => _GroupLobbyPageState();
}

class _GroupLobbyPageState extends State<GroupLobbyPage> {
  GroupCoordinator get _coordinator =>
      widget.groupCoordinatorOverride ?? ApiModule.instance.groupCoordinator;

  bool _leaving = false;
  GroupPartyState? _lastLoggedState;
  bool _hasNavigatedToQuiz = false;

  static const double _bottomBarSpace = 120;
  static const double _diffPillWidth = 90;
  static const double _diffPillHeight = 28;

  GroupStore get _store => _coordinator.store;
  String get _currentUserId {
    final authStore = MyAuthStore.of(context);
    return authStore.user?.id ?? '';
  }

  @override
  void initState() {
    super.initState();
    _listenToStore();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _listenToStore() {
    _store.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (!mounted) {
      return;
    }

    final state = _store.state;

    if (state != _lastLoggedState) {
      _lastLoggedState = state;
    }

    // Reset navigation flag when returning to lobby
    if (state == GroupPartyState.lobby && _hasNavigatedToQuiz) {
      _hasNavigatedToQuiz = false;
    }

    // Navigate to quiz only if we haven't already
    if ((state == GroupPartyState.countdown ||
        state == GroupPartyState.questionActive) && !_hasNavigatedToQuiz) {
      _hasNavigatedToQuiz = true;
      _navigateToQuiz();
      return;
    }

    if (state == GroupPartyState.error && !_leaving) {
      final error = _store.errorMessage;
      if (error != null && error.contains('supprimée')) {
        _store.removeListener(_onStoreChanged);
        _snack('L\'hôte a quitté la partie', color: TuuurTheme.brandOrange);
        _leave();
        return;
      }
    }

    setState(() {});
  }

  void _navigateToQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupQuizPage(
          groupStore: _store,
          currentUserId: _currentUserId,
          onFinished: _navigateToResults,
          onLeave: _handleLeaveFromQuiz,
        ),
      ),
    );
  }

  void _navigateToResults() {
    final finalScores = _store.finalScores;
    final party = _store.currentParty;
    final questionsHistory = _store.questionsHistory;

    if (party == null) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupResultsPage(
          finalScores: finalScores,
          currentUserId: _currentUserId,
          partyCode: party.code,
          questionsHistory: questionsHistory,
        ),
      ),
    );
  }

  void _handleLeaveFromQuiz() {
    Navigator.of(context).popUntil((route) => route.isFirst);

    _coordinator.leaveParty().catchError((_) {});
  }

  void _showErrorAndLeave(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: TuuurTheme.brandDarkGray,
        title: const Text(
          'Partie terminée',
          style: TextStyle(color: TuuurTheme.brandLightGray),
        ),
        content: Text(
          message,
          style: const TextStyle(color: TuuurTheme.brandGray),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(color: TuuurTheme.brandPurple),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? TuuurTheme.brandOrange,
      ),
    );
  }

  Future<void> _leave() async {
    if (_leaving) return;

    setState(() => _leaving = true);

    try {
      _store.removeListener(_onStoreChanged);

      await _coordinator.leaveParty();

      if (mounted) {
        final authStore = MyAuthStore.of(context);
        if (authStore.isGuest) {
          await authStore.signOut();
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      _store.addListener(_onStoreChanged);
      setState(() => _leaving = false);
      _snack('Erreur: $e');
    }
  }

  Future<void> _leaveWithConfirmation() async {
    if (_leaving) return;
    
    await runWithConfirmIfNeeded(
      context,
      confirm: true,
      message: 'Voulez-vous vraiment quitter le lobby ?',
      action: _leave,
    );
  }

  Future<void> _startParty() async {
    final party = _store.currentParty;
    if (party == null) {
      _snack('Aucune partie en cours', color: TuuurTheme.brandOrange);
      return;
    }

    if (!_isHost) {
      _snack(
        'Seul l\'hôte peut démarrer la partie',
        color: TuuurTheme.brandOrange,
      );
      return;
    }

    try {
      await _coordinator.startParty();
    } catch (e) {
      _snack('Erreur lors du démarrage: $e', color: TuuurTheme.brandOrange);
    }
  }

  void _openSettings() {
    final party = _store.currentParty;
    if (party == null) {
      _snack('Aucune partie en cours', color: TuuurTheme.brandOrange);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupSettingsPage(
          party: party,
          currentUserId: _currentUserId,
          onSettingsSaved: () {
            Navigator.of(context).pop();
          },
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _copyCode() {
    final party = _store.currentParty;
    if (party != null) {
      Clipboard.setData(ClipboardData(text: party.code));
      _snack('Code copié : ${party.code}', color: TuuurTheme.brandGreen);
    }
  }

  bool get _isHost {
    final party = _store.currentParty;
    return party?.idUserHost == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final party = _store.currentParty;
    final players = _store.players;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _leaving) return;
        if (party == null) {
          Navigator.of(context).pop();
          return;
        }
        runWithConfirmIfNeeded(
          context,
          confirm: true,
          message: 'Voulez-vous vraiment quitter le lobby ?',
          action: () async {
            await _leave();
          },
        );
      },
      child: Scaffold(
        appBar: NavigationHeader(
          showBack: !_leaving,
          confirmOnBack: !_leaving && party != null,
          confirmOnHome: !_leaving && party != null,
          backConfirmMessage: 'Voulez-vous vraiment quitter le lobby ?',
          homeConfirmMessage:
              'Voulez-vous vraiment quitter le lobby et retourner à l\'accueil ?',
          onBackPressed: party != null ? _leave : null,
          onHomePressed: party != null ? _leave : null,
        ),
        body: _leaving
            ? const Center(
                child: CircularProgressIndicator(color: TuuurTheme.brandPurple),
              )
            : party == null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const GamingCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Erreur : Aucune partie en cours',
                            style: TextStyle(color: TuuurTheme.brandOrange),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GamingButtonSecondary(
                      text: 'Retour',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      _bottomBarSpace,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPartyInfoHeader(party),

                        const SizedBox(height: 24),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stack = constraints.maxWidth < 900;

                            final leftPanelBox = Container(
                              padding: const EdgeInsets.all(18),
                              decoration: TuuurStyles.gamingCard,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Joueurs',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: TuuurTheme.brandLightGray,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: TuuurStyles.pill,
                                        child: Text(
                                          '${players.length} connecté${players.length > 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            color: TuuurTheme.brandPurple,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (players.isEmpty)
                                    const Text(
                                      'En attente de joueurs...',
                                      style: TextStyle(
                                        color: TuuurTheme.brandGray,
                                      ),
                                    )
                                  else
                                    ...players.map((p) => _buildPlayerTile(p)),
                                ],
                              ),
                            );

                            final rightPanelBox = _buildJoinViaCodeCard(party);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                leftPanelBox,
                                const SizedBox(height: 16),
                                rightPanelBox,
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  StickyBottomBar(child: _buildStickyActions()),
                ],
              ),
      ),
    );
  }

  Widget _buildParameterChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: TuuurStyles.pill,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: TuuurTheme.brandLightGray,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPlayerTile(GroupUser player) {
    final isHost = player.id == _store.currentParty?.idUserHost;
    final isCurrentUser = player.id == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? TuuurTheme.brandPurple
              : TuuurTheme.brandPurple.withOpacity(0.2),
          width: isCurrentUser ? 2 : 1,
        ),
        color: isCurrentUser
            ? TuuurTheme.brandPurple.withOpacity(0.1)
            : TuuurTheme.brandDarkGray.withOpacity(0.3),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              color: TuuurTheme.brandPurple.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: TuuurTheme.brandPurple.withOpacity(0.25),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: AvatarWidget(
                avatarBase64: player.avatar,
                fallbackText: player.nickName,
                size: 46,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.nickName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrentUser
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),

                if (isHost || isCurrentUser) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (isHost)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: TuuurTheme.brandPurple.withOpacity(0.2),
                            border: Border.all(
                              color: TuuurTheme.brandPurple.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Hôte',
                            style: TextStyle(
                              color: TuuurTheme.brandPurple,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: TuuurTheme.brandGreen.withOpacity(0.2),
                            border: Border.all(
                              color: TuuurTheme.brandGreen.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Vous',
                            style: TextStyle(
                              color: TuuurTheme.brandGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyInfoHeader(GroupParty party) {
    final themes = party.partyTheme.map((pt) => pt.theme.label).toList()
      ..sort();

    final difficultyIds =
        party.partyDifficulty.map((pd) => pd.difficulty.id).toList()..sort();

    final scoreLabel = party.scoreEachRound
        ? 'Chaque question'
        : 'Fin de partie';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: TuuurStyles.gamingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Infos de la partie',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: TuuurTheme.brandLightGray,
            ),
          ),
          const SizedBox(height: 14),

          _infoLine(
            icon: FontAwesomeIcons.listOl,
            label: 'Questions',
            child: Text(
              '${party.nbQuestions}',
              style: const TextStyle(
                color: TuuurTheme.brandLightGray,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          _infoLine(
            icon: FontAwesomeIcons.bullseye,
            label: 'Score',
            child: Text(
              scoreLabel,
              style: const TextStyle(
                color: TuuurTheme.brandLightGray,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (themes.isNotEmpty)
            _infoLine(
              icon: FontAwesomeIcons.tags,
              label: 'Thèmes',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: themes.map((t) => ThemePill(label: t)).toList(),
              ),
            ),

          if (difficultyIds.isNotEmpty)
            _infoLine(
              icon: FontAwesomeIcons.fire,
              label: 'Difficultés',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: difficultyIds
                    .map(
                      (id) => DifficultyPill(
                        difficultyId: id,
                        width: _diffPillWidth,
                        height: _diffPillHeight,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoLine({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 14, color: TuuurTheme.brandPurple),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 88, maxWidth: 110),
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '$label :',
                style: const TextStyle(
                  color: TuuurTheme.brandGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildJoinViaCodeCard(GroupParty party) {
    return LayoutBuilder(
      builder: (context, box) {
        final qrSize = box.maxWidth < 360
            ? 140.0
            : box.maxWidth < 460
            ? 180.0
            : 220.0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: TuuurStyles.gamingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rejoindre via code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
              const SizedBox(height: 12),

              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => copyToClipboard(
                  context,
                  party.code,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: TuuurTheme.brandDarkGray.withOpacity(0.45),
                    border: Border.all(
                      color: TuuurTheme.brandPurple.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Code',
                        style: TextStyle(
                          color: TuuurTheme.brandGray,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          party.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: TuuurTheme.brandLightGray,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const FaIcon(
                        FontAwesomeIcons.copy,
                        size: 14,
                        color: TuuurTheme.brandPurple,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: QRPreviewWidget(text: party.code, size: qrSize),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStickyActions() {
    final isHost = _isHost;

    final quitBtn = GamingIconButton(
      icon: FontAwesomeIcons.rightFromBracket,
      tooltip: 'Quitter',
      color: TuuurTheme.brandOrange,
      onPressed: !_leaving ? _leaveWithConfirmation : null,
    );

    if (isHost) {
      // Vue hôte : paramètres + bouton lancer
      final settingsBtn = GamingIconButton(
        icon: FontAwesomeIcons.gear,
        tooltip: 'Paramètres',
        onPressed: !_leaving ? _openSettings : null,
      );

      final launchBtn = GamingButtonPrimary(
        text: 'Lancer la partie',
        onPressed: !_leaving ? _startParty : null,
      );

      return Row(
        children: [
          settingsBtn,
          const SizedBox(width: 10),
          quitBtn,
          const SizedBox(width: 12),
          Expanded(child: launchBtn),
        ],
      );
    } else {
      // Vue non-hôte : juste bouton quitter + message d'attente
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: quitBtn),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'En attente que l\'hôte démarre la partie...',
            style: TextStyle(
              color: TuuurTheme.brandGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }
}
