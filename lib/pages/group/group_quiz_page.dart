import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/api_module.dart';
import '../../api/group/group_models.dart';
import '../../navigation/app_router.dart';
import '../../stores/group_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';
import '../../navigation/navigation_utils.dart';

class GroupQuizPage extends StatefulWidget {
  final GroupStore groupStore;
  final int currentUserId;
  final VoidCallback onFinished;
  final VoidCallback onLeave;

  const GroupQuizPage({
    super.key,
    required this.groupStore,
    required this.currentUserId,
    required this.onFinished,
    required this.onLeave,
  });

  @override
  State<GroupQuizPage> createState() => _GroupQuizPageState();
}

class _GroupQuizPageState extends State<GroupQuizPage> {
  StreamSubscription? _storeSubscription;
  bool _leaving = false;

  // Mémoriser l'état précédent pour éviter les rebuilds inutiles
  GroupPartyState? _previousState;
  int? _previousQuestionId;
  Set<int> _previousAnsweredUserIds = {};
  Map<int, bool> _previousUserAnswerCorrectness = {};

  @override
  void initState() {
    super.initState();
    _listenToStore();
  }

  @override
  void dispose() {
    _storeSubscription?.cancel();
    widget.groupStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _listenToStore() {
    _storeSubscription = Stream.periodic(const Duration(milliseconds: 100))
        .listen((_) {
          if (!mounted) return;

          final state = widget.groupStore.state;

          // Si la partie est terminée, naviguer vers les résultats
          if (state == GroupPartyState.finished) {
            _storeSubscription?.cancel();
            widget.onFinished();
          }

          // Si erreur critique, afficher et proposer de quitter
          if (state == GroupPartyState.error) {
            final error = widget.groupStore.errorMessage;
            if (error != null && error.contains('supprimée')) {
              _storeSubscription?.cancel();
              _showPartyDeletedMessage();
              widget.onLeave();
            }
          }
        });

    // Trigger rebuild on store changes
    widget.groupStore.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (!mounted) return;

    final state = widget.groupStore.state;
    final currentQuestionId = widget.groupStore.currentQuestion?.question.id;
    final answeredUserIds = widget.groupStore.answeredUserIds;
    final userAnswerCorrectness = widget.groupStore.userAnswerCorrectness;

    // Vérifier si quelque chose a vraiment changé
    final stateChanged = state != _previousState;
    final questionChanged = currentQuestionId != _previousQuestionId;
    final answersChanged =
        !answeredUserIds.difference(_previousAnsweredUserIds).isEmpty ||
        !_previousAnsweredUserIds.difference(answeredUserIds).isEmpty;
    final correctnessChanged =
        userAnswerCorrectness.length != _previousUserAnswerCorrectness.length ||
        userAnswerCorrectness.keys.any(
          (key) =>
              userAnswerCorrectness[key] != _previousUserAnswerCorrectness[key],
        );

    // Ne faire setState que si quelque chose a changé
    if (stateChanged ||
        questionChanged ||
        answersChanged ||
        correctnessChanged) {
      _previousState = state;
      _previousQuestionId = currentQuestionId;
      _previousAnsweredUserIds = Set.from(answeredUserIds);
      _previousUserAnswerCorrectness = Map.from(userAnswerCorrectness);

      setState(() {});
    }
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
              Navigator.of(context).pop(); // Fermer le dialog
              // Retourner à GroupModePage en enlevant toutes les pages
              Navigator.of(context).popUntil((route) => route.isFirst);
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

  void _showPartyDeletedMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('L\'hôte a quitté la partie'),
        backgroundColor: TuuurTheme.brandOrange,
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _selectAnswer(int answerId) async {
    // Sélectionner la réponse
    widget.groupStore.selectAnswer(answerId);

    // Envoyer automatiquement la réponse sans attendre de clic sur "Valider"
    try {
      await widget.groupStore.submitAnswer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: TuuurTheme.brandOrange,
        ),
      );
    }
  }

  Color _getAnswerBackgroundColor(Answer answer) {
    final myAnswerId = widget.groupStore.myAnswerId;
    final state = widget.groupStore.state;

    // Pendant la révélation de la réponse
    if (state == GroupPartyState.answerReveal) {
      if (answer.valid == true) {
        return TuuurTheme.brandGreen.withOpacity(0.2);
      } else if (answer.id == myAnswerId) {
        return TuuurTheme.brandOrange.withOpacity(0.2);
      }
    }

    // Si la réponse est sélectionnée
    if (answer.id == myAnswerId) {
      return TuuurTheme.brandPurple.withOpacity(0.2);
    }

    return TuuurTheme.brandDarkGray.withOpacity(0.3);
  }

  Color _getAnswerBorderColor(Answer answer) {
    final myAnswerId = widget.groupStore.myAnswerId;
    final state = widget.groupStore.state;

    // Pendant la révélation de la réponse
    if (state == GroupPartyState.answerReveal) {
      if (answer.valid == true) {
        return TuuurTheme.brandGreen;
      } else if (answer.id == myAnswerId) {
        return TuuurTheme.brandOrange;
      }
    }

    // Si la réponse est sélectionnée
    if (answer.id == myAnswerId) {
      return TuuurTheme.brandPurple;
    }

    return TuuurTheme.brandPurple.withOpacity(0.3);
  }

  Color _getAnswerTextColor(Answer answer) {
    final state = widget.groupStore.state;

    // Pendant la révélation
    if (state == GroupPartyState.answerReveal) {
      if (answer.valid == true) {
        return TuuurTheme.brandGreen;
      }
    }

    return TuuurTheme.brandLightGray;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.groupStore.state;
    final party = widget.groupStore.currentParty;
    final question = widget.groupStore.currentQuestion;
    final players = widget.groupStore.players;
    final answeredUserIds = widget.groupStore.answeredUserIds;
    final myAnswerId = widget.groupStore.myAnswerId;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _leaving) return;
        runWithConfirmIfNeeded(
          context,
          confirm: true,
          message: 'Voulez-vous vraiment quitter la partie en cours ?',
          action: () async {
            await _leave();
          },
        );
      },
      child: Scaffold(
        appBar: NavigationHeader(
          showBack: !_leaving,
          confirmOnBack: !_leaving,
          confirmOnHome: !_leaving,
          backConfirmMessage:
              'Voulez-vous vraiment quitter la partie en cours ?',
          homeConfirmMessage:
              'Voulez-vous vraiment quitter la partie et retourner à l\'accueil ?',
          onBackPressed: _leave,
          onHomePressed: _leave,
        ),
        body: _leaving
            ? const Center(
                child: CircularProgressIndicator(color: TuuurTheme.brandPurple),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(party, question),
                    const SizedBox(height: 24),

                    // Timer section (seulement pendant la question)
                    if (state == GroupPartyState.questionActive)
                      const _QuestionTimerWidget(),

                    if (state == GroupPartyState.questionActive)
                      const SizedBox(height: 16),

                    // Affichage selon l'état
                    if (state == GroupPartyState.countdown)
                      _CountdownWidget(groupStore: widget.groupStore)
                    else if (state == GroupPartyState.questionActive ||
                        state == GroupPartyState.answerReveal)
                      _buildQuestionSection(question, myAnswerId)
                    else if (state == GroupPartyState.scoreDisplay)
                      _buildScoreDisplay()
                    else if (state == GroupPartyState.loading)
                      _buildLoadingCard()
                    else if (state == GroupPartyState.error)
                      _buildErrorCard(),

                    const SizedBox(height: 20),

                    // Liste des joueurs et leur statut
                    _buildPlayersStatus(players, answeredUserIds),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(GroupParty? party, GroupQuestion? question) {
    // currentIndex arrive en 1-based (commence à 1 selon la doc)
    final baseIndex = question?.currentIndex ?? 0;
    final questionNumber = baseIndex + 1;
    final totalQuestions = party?.nbQuestions ?? 0;

    // Récupérer le score total du joueur (cumulé)
    final myTotalScore = widget.groupStore.myTotalScore;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;

        final info = Wrap(
          alignment: narrow ? WrapAlignment.start : WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (party != null) ...[
              if (totalQuestions > 0)
                PillBadge(text: '$questionNumber/$totalQuestions'),
              // Affichage du score total du joueur (toujours affiché)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: TuuurStyles.pill.copyWith(
                  color: TuuurTheme.brandGreen.withOpacity(0.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Score: ',
                      style: TextStyle(
                        color: TuuurTheme.brandGray,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$myTotalScore',
                      style: const TextStyle(
                        color: TuuurTheme.brandGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [info],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: info),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionSection(GroupQuestion? question, int? myAnswerId) {
    if (question == null) {
      return const GamingCard(
        child: Center(
          child: Text(
            'En attente de la question...',
            style: TextStyle(color: TuuurTheme.brandGray),
          ),
        ),
      );
    }

    final q = question.question;
    final isAnswerReveal =
        widget.groupStore.state == GroupPartyState.answerReveal;
    final hasAnswered = myAnswerId != null;

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question
          AutoSizeText(
            q.label,
            maxLines: 3,
            minFontSize: 14,
            stepGranularity: 1,
            style: const TextStyle(
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ),

          const SizedBox(height: 16),

          // Réponses
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final spacing = 12.0;
              final itemWidth = isWide
                  ? (constraints.maxWidth - spacing) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: q.answer.map((answer) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: itemWidth,
                      maxWidth: itemWidth,
                    ),
                    child: _AnswerButton(
                      label: answer.value,
                      enabled: !hasAnswered && !isAnswerReveal,
                      onTap: () => _selectAnswer(answer.id),
                      bgColor: _getAnswerBackgroundColor(answer),
                      borderColor: _getAnswerBorderColor(answer),
                      textColor: _getAnswerTextColor(answer),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),

          // Affichage du statut de la réponse
          if (!isAnswerReveal) ...[
            if (hasAnswered)
              const Center(child: BadgeSuccess(text: 'Réponse envoyée ✓')),
          ] else ...[
            // Afficher si la réponse était correcte
            _buildAnswerFeedback(question, myAnswerId),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerFeedback(GroupQuestion question, int? myAnswerId) {
    if (myAnswerId == null) {
      return const BadgeWarning(text: 'Aucune réponse donnée');
    }

    final correctAnswer = question.question.answer.firstWhere(
      (a) => a.valid == true,
      orElse: () => question.question.answer.first,
    );

    final wasCorrect = myAnswerId == correctAnswer.id;

    if (wasCorrect) {
      return BadgeSuccess(text: 'Correct ! +${question.score} pts');
    } else {
      return const BadgeWarning(text: 'Mauvaise réponse');
    }
  }

  Widget _buildScoreDisplay() {
    final scores = widget.groupStore.currentScores;

    if (scores.isEmpty) {
      return const GamingCard(
        child: Center(
          child: Text(
            'Chargement des scores...',
            style: TextStyle(color: TuuurTheme.brandGray),
          ),
        ),
      );
    }

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.trophy,
                size: 22,
                color: TuuurTheme.brandLightGray,
              ),
              const SizedBox(width: 10),
              const Text(
                'Classement',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...scores.asMap().entries.map((entry) {
            final index = entry.key;
            final userScore = entry.value;
            final isCurrentUser = userScore.user.id == widget.currentUserId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _getRankColor(index).withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: _getRankColor(index),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userScore.user.nickName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrentUser
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: TuuurTheme.brandLightGray,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: TuuurStyles.pill.copyWith(
                      color: TuuurTheme.brandGreen.withOpacity(0.2),
                    ),
                    child: Text(
                      '${userScore.score} pts',
                      style: const TextStyle(
                        color: TuuurTheme.brandGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return TuuurTheme.brandPurple;
    }
  }

  List<Widget> _buildThemeBadges() {
    final party = widget.groupStore.currentParty;
    if (party == null || party.partyTheme.isEmpty) {
      return [];
    }

    // Récupérer et trier les thèmes par ordre alphabétique
    final sortedThemes = party.partyTheme.toList()
      ..sort((a, b) => a.theme.label.compareTo(b.theme.label));

    return sortedThemes.map((pt) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: TuuurTheme.brandPurple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: TuuurTheme.brandPurple.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(
              FontAwesomeIcons.tag,
              size: 10,
              color: TuuurTheme.brandPurple,
            ),
            const SizedBox(width: 6),
            Text(
              pt.theme.label,
              style: const TextStyle(
                color: TuuurTheme.brandPurple,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPlayersStatus(
    List<GroupUser> players,
    Set<int> answeredUserIds,
  ) {
    if (players.isEmpty) return const SizedBox.shrink();

    final state = widget.groupStore.state;
    final showAnswerStatus =
        state == GroupPartyState.questionActive ||
        state == GroupPartyState.answerReveal ||
        state == GroupPartyState.scoreDisplay;
    final userAnswerCorrectness = widget.groupStore.userAnswerCorrectness;

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Joueurs',
                style: TextStyle(
                  fontSize: 18,
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
          Column(
            children: players.map((player) {
              final hasAnswered = answeredUserIds.contains(player.id);
              final isCurrentUser = player.id == widget.currentUserId;

              // Déterminer la couleur en fonction de l'état
              Color borderColor;
              Color backgroundColor;
              IconData iconData;
              Color iconColor;

              if ((state == GroupPartyState.answerReveal ||
                      state == GroupPartyState.scoreDisplay) &&
                  userAnswerCorrectness.containsKey(player.id)) {
                // Pendant la révélation, afficher rouge/vert selon la correctness
                final wasCorrect = userAnswerCorrectness[player.id] ?? false;
                final resultColor = wasCorrect
                    ? TuuurTheme.brandGreen
                    : TuuurTheme.brandOrange;
                borderColor = resultColor;
                backgroundColor = resultColor.withOpacity(
                  isCurrentUser ? 0.3 : 0.2,
                );
                iconData = wasCorrect
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circleXmark;
                iconColor = resultColor;
              } else if (state == GroupPartyState.questionActive) {
                // Pendant la question, afficher vert s'ils ont répondu, orange sinon
                final statusColor = hasAnswered
                    ? TuuurTheme.brandGreen
                    : TuuurTheme.brandOrange;
                borderColor = statusColor;
                backgroundColor = statusColor.withOpacity(
                  isCurrentUser ? 0.3 : 0.2,
                );
                iconData = hasAnswered
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.clock;
                iconColor = hasAnswered
                    ? TuuurTheme.brandGreen
                    : TuuurTheme.brandGray;
              } else {
                // Par défaut
                borderColor = isCurrentUser
                    ? TuuurTheme.brandPurple
                    : TuuurTheme.brandPurple.withOpacity(0.2);
                backgroundColor = isCurrentUser
                    ? TuuurTheme.brandPurple.withOpacity(0.2)
                    : TuuurTheme.brandDarkGray.withOpacity(0.3);
                iconData = FontAwesomeIcons.user;
                iconColor = TuuurTheme.brandGray;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: backgroundColor,
                  border: Border.all(
                    color: borderColor,
                    width: isCurrentUser ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AvatarWidget(
                      key: ValueKey('avatar_${player.id}'),
                      avatarBase64: player.avatar,
                      fallbackText: player.nickName,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        player.nickName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TuuurTheme.brandLightGray,
                          fontWeight: isCurrentUser
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (showAnswerStatus) ...[
                      const SizedBox(width: 8),
                      FaIcon(iconData, size: 16, color: iconColor),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const GamingCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              CircularProgressIndicator(color: TuuurTheme.brandPurple),
              SizedBox(height: 12),
              Text(
                'Chargement...',
                style: TextStyle(color: TuuurTheme.brandGray),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    final error = widget.groupStore.errorMessage ?? 'Une erreur est survenue';

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Erreur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: TuuurTheme.brandOrange)),
          const SizedBox(height: 12),
          GamingButtonSecondary(text: 'Quitter', onPressed: widget.onLeave),
        ],
      ),
    );
  }

  Future<void> _leave() async {
    if (_leaving) return;

    setState(() => _leaving = true);

    try {
      // Retirer le listener AVANT de quitter
      _storeSubscription?.cancel();
      widget.groupStore.removeListener(_onStoreChanged);

      // Appeler le callback qui gère la déconnexion
      widget.onLeave();
    } catch (e) {
      if (!mounted) return;

      // Remettre le listener en cas d'erreur
      widget.groupStore.addListener(_onStoreChanged);
      setState(() => _leaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: TuuurTheme.brandOrange,
        ),
      );
    }
  }
}

// Widget séparé pour le compte à rebours afin d'éviter de rebuilder toute la page
class _CountdownWidget extends StatefulWidget {
  final GroupStore groupStore;

  const _CountdownWidget({required this.groupStore});

  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget> {
  int? _previousCountdownValue;

  @override
  void initState() {
    super.initState();
    widget.groupStore.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.groupStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;

    final countdownValue = widget.groupStore.countdownValue;

    // Ne rebuild que si le countdownValue a changé
    if (countdownValue != _previousCountdownValue) {
      _previousCountdownValue = countdownValue;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final countdown = widget.groupStore.countdownValue ?? 3;

    return GamingCard(
      child: Center(
        child: Column(
          children: [
            const Text(
              'La question arrive dans...',
              style: TextStyle(color: TuuurTheme.brandGray, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
                  '$countdown',
                  style: const TextStyle(
                    color: TuuurTheme.brandPurple,
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 1000.ms,
                ),
          ],
        ),
      ),
    );
  }
}

// Widget séparé pour le timer afin d'éviter de rebuilder toute la page
class _QuestionTimerWidget extends StatefulWidget {
  const _QuestionTimerWidget();

  @override
  State<_QuestionTimerWidget> createState() => _QuestionTimerWidgetState();
}

class _QuestionTimerWidgetState extends State<_QuestionTimerWidget> {
  static const int totalTime = 15;
  double _remainingTime = totalTime.toDouble();
  Timer? _timer;

  double get _remainingRatio => max(0, min(1, _remainingTime / totalTime));

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _clearTimer();
    super.dispose();
  }

  void _startTimer() {
    _clearTimer();
    _remainingTime = totalTime.toDouble();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingTime = max(0, _remainingTime - 0.1);
      });

      if (_remainingTime <= 0) {
        _clearTimer();
      }
    });
  }

  void _clearTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return GamingCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          GamingProgressBar(progress: _remainingRatio, height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Temps restant: ${_remainingTime.toStringAsFixed(1)}s',
                style: const TextStyle(
                  color: TuuurTheme.brandLightGray,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _AnswerButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              label,
              softWrap: true,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ),
    );
  }
}
