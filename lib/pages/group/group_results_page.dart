import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:confetti/confetti.dart';

import '../../api/api_module.dart';
import '../../api/group/group_models.dart';
import '../../navigation/app_router.dart';
import '../../stores/group_coordinator.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';
import '../../navigation/navigation_utils.dart';

class GroupResultsPage extends StatefulWidget {
  final List<UserScore> finalScores;
  final String currentUserId;
  final String partyCode;
  final List<QuestionHistory> questionsHistory;

  const GroupResultsPage({
    super.key,
    required this.finalScores,
    required this.currentUserId,
    required this.partyCode,
    this.questionsHistory = const [],
  });

  @override
  State<GroupResultsPage> createState() => _GroupResultsPageState();
}

class _GroupResultsPageState extends State<GroupResultsPage> {
  late ConfettiController _confettiController;
  UserScore? _currentUserScore;
  int _currentUserRank = 0;
  bool _isLeaving = false;

  GroupCoordinator get _coordinator => ApiModule.instance.groupCoordinator;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _findCurrentUserScore();

    // Si l'utilisateur est dans le top 3, lancer les confettis
    if (_currentUserRank > 0 && _currentUserRank <= 3) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _confettiController.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _findCurrentUserScore() {
    for (int i = 0; i < widget.finalScores.length; i++) {
      if (widget.finalScores[i].user.id == widget.currentUserId) {
        _currentUserScore = widget.finalScores[i];
        _currentUserRank = i + 1;
        break;
      }
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Or
      case 2:
        return Colors.grey; // Argent
      case 3:
        return Colors.brown; // Bronze
      default:
        return TuuurTheme.brandPurple;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return FontAwesomeIcons.trophy;
      case 2:
        return FontAwesomeIcons.medal;
      case 3:
        return FontAwesomeIcons.award;
      default:
        return FontAwesomeIcons.rankingStar;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavigationHeader(
        showBack: !_isLeaving,
        confirmOnBack: !_isLeaving,
        confirmOnHome: !_isLeaving,
        backConfirmMessage: 'Voulez-vous vraiment quitter le groupe ?',
        homeConfirmMessage:
            'Voulez-vous vraiment quitter le groupe et retourner à l\'accueil ?',
        onBackPressed: _handleLeaveGroup,
        onHomePressed: _handleLeaveGroup,
      ),
      body: _isLeaving
          ? const Center(
              child: CircularProgressIndicator(color: TuuurTheme.brandPurple),
            )
          : Stack(
              children: [
                // Contenu scrollable
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    120, // IMPORTANT: marge basse pour ne pas cacher le contenu
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      if (_currentUserScore != null) _buildUserSummary(),
                      const SizedBox(height: 32),
                      _buildPodium(),
                      const SizedBox(height: 32),
                      _buildFullRanking(),
                      const SizedBox(height: 32),
                      if (widget.questionsHistory.isNotEmpty)
                        _buildQuestionsRecap(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Confettis pour le top 3
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: 3.14 / 2, // vers le bas
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    gravity: 0.3,
                    colors: const [
                      TuuurTheme.brandPurple,
                      TuuurTheme.brandGreen,
                      TuuurTheme.brandOrange,
                      Colors.amber,
                    ],
                  ),
                ),

                // Bouton sticky en bas, sans barre
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _buildActions(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const FaIcon(
          FontAwesomeIcons.trophy,
          color: TuuurTheme.brandPurple,
          size: 48,
        ).animate().scale(
          begin: const Offset(0.5, 0.5),
          duration: 800.ms,
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: 16),
        const Text(
          'Partie terminée !',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: TuuurTheme.brandLightGray,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildUserSummary() {
    if (_currentUserScore == null) return const SizedBox.shrink();

    final rank = _currentUserRank;
    final score = _currentUserScore!.score;
    final isTopThree = rank > 0 && rank <= 3;

    // Calculer les statistiques sur les questions
    final totalQuestions = widget.questionsHistory.length;
    final correctAnswers = widget.questionsHistory
        .where((q) => q.wasCorrect)
        .length;
    final successRate = totalQuestions > 0
        ? ((correctAnswers / totalQuestions) * 100).round()
        : 0;

    return GamingCard(
      child: Column(
        children: [
          Text(
            isTopThree ? 'Félicitations !' : 'Votre résultat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isTopThree
                  ? TuuurTheme.brandGreen
                  : TuuurTheme.brandLightGray,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                label: 'Classement',
                value: rank > 0 ? '$rank${_getRankEmoji(rank)}' : 'N/A',
                color: _getRankColor(rank),
              ),
              _buildStatCard(
                label: 'Score',
                value: '$score pts',
                color: TuuurTheme.brandGreen,
              ),
            ],
          ),
          if (totalQuestions > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  label: 'Questions',
                  value: '$totalQuestions',
                  color: TuuurTheme.brandPurple,
                ),
                _buildStatCard(
                  label: 'Réussite',
                  value: '$successRate%',
                  color: TuuurTheme.brandGreen,
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: TuuurTheme.brandGray),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    // Afficher le podium dès qu'il y a au moins 1 joueur
    if (widget.finalScores.isEmpty) {
      return const SizedBox.shrink();
    }

    final first = widget.finalScores.length > 0 ? widget.finalScores[0] : null;
    final second = widget.finalScores.length > 1 ? widget.finalScores[1] : null;
    final third = widget.finalScores.length > 2 ? widget.finalScores[2] : null;

    return GamingCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.trophy,
                size: 22,
                color: TuuurTheme.brandLightGray,
              ),
              const SizedBox(width: 10),
              const Text(
                'Podium',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;

              if (isNarrow) {
                return Column(
                  children: [
                    if (first != null)
                      _buildPodiumPlace(first, 1, isNarrow: true),
                    const SizedBox(height: 12),
                    if (second != null)
                      _buildPodiumPlace(second, 2, isNarrow: true),
                    const SizedBox(height: 12),
                    if (third != null)
                      _buildPodiumPlace(third, 3, isNarrow: true),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (second != null)
                    Expanded(child: _buildPodiumPlace(second, 2, height: 100)),
                  const SizedBox(width: 8),
                  if (first != null)
                    Expanded(child: _buildPodiumPlace(first, 1, height: 140)),
                  const SizedBox(width: 8),
                  if (third != null)
                    Expanded(child: _buildPodiumPlace(third, 3, height: 80)),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildPodiumPlace(
    UserScore userScore,
    int rank, {
    double height = 100,
    bool isNarrow = false,
  }) {
    final color = _getRankColor(rank);
    final isCurrentUser = userScore.user.id == widget.currentUserId;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: rank == 1 ? 80 : 64,
          height: rank == 1 ? 80 : 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: rank == 1 ? 3 : 2),
            boxShadow: rank == 1
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: AvatarWidget(
            avatarBase64: userScore.user.avatar,
            fallbackText: userScore.user.nickName,
            size: rank == 1 ? 74 : 60,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          userScore.user.nickName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
            color: TuuurTheme.brandLightGray,
            fontSize: rank == 1 ? 16 : 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.2),
          ),
          child: Text(
            '${userScore.score} pts',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: rank == 1 ? 14 : 12,
            ),
          ),
        ),
      ],
    );

    if (isNarrow) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
          border: Border.all(
            color: isCurrentUser ? color : color.withOpacity(0.3),
            width: isCurrentUser ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(_getRankEmoji(rank), style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: color.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: color, width: 3),
          left: BorderSide(color: color.withOpacity(0.3)),
          right: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: content,
    );
  }

  Widget _buildFullRanking() {
    if (widget.finalScores.length <= 3) {
      return const SizedBox.shrink();
    }

    final remainingScores = widget.finalScores.skip(3).toList();

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Classement complet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ),
          const SizedBox(height: 16),
          ...remainingScores.asMap().entries.map((entry) {
            final index = entry.key + 3; // +3 car on skip les 3 premiers
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
                      color: TuuurTheme.brandPurple.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: TuuurTheme.brandPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AvatarWidget(
                    avatarBase64: userScore.user.avatar,
                    fallbackText: userScore.user.nickName,
                    size: 40,
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
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
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
            ).animate(delay: (100 * index).ms).fadeIn().slideX(begin: 0.2);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildQuestionsRecap() {
    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: TuuurTheme.brandPurple.withOpacity(0.2),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.listCheck,
                  color: TuuurTheme.brandPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Récapitulatif des questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.questionsHistory.asMap().entries.map((entry) {
            final index = entry.key;
            final questionHistory = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: TuuurTheme.brandPurple.withOpacity(0.2),
                ),
                color: TuuurTheme.brandDarkGray.withOpacity(0.5),
              ),
              child: _buildQuestionCard(index + 1, questionHistory),
            ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }

  Widget _buildQuestionCard(int questionNumber, QuestionHistory history) {
    final question = history.groupQuestion.question;
    final wasCorrect = history.wasCorrect;
    final userAnswer = history.userAnswer;
    final correctAnswer = history.correctAnswer;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec numéro et badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: wasCorrect
                      ? TuuurTheme.brandGreen.withOpacity(0.2)
                      : TuuurTheme.brandOrange.withOpacity(0.2),
                  border: Border.all(
                    color: wasCorrect
                        ? TuuurTheme.brandGreen.withOpacity(0.4)
                        : TuuurTheme.brandOrange.withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: wasCorrect
                          ? TuuurTheme.brandGreen
                          : TuuurTheme.brandOrange,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: TuuurTheme.brandLightGray,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: wasCorrect
                            ? TuuurTheme.brandGreen.withOpacity(0.2)
                            : TuuurTheme.brandOrange.withOpacity(0.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            wasCorrect
                                ? FontAwesomeIcons.check
                                : FontAwesomeIcons.xmark,
                            color: wasCorrect
                                ? TuuurTheme.brandGreen
                                : TuuurTheme.brandOrange,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            wasCorrect
                                ? 'Bonne réponse +${history.scoreGained} pts'
                                : 'Mauvaise réponse',
                            style: TextStyle(
                              color: wasCorrect
                                  ? TuuurTheme.brandGreen
                                  : TuuurTheme.brandOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Liste des réponses
          ...question.answer.map((answer) {
            final isCorrect = answer.valid == true;
            final isUserChoice = userAnswer?.id == answer.id;

            Color backgroundColor;
            Color borderColor;
            Color textColor;
            IconData? icon;

            if (isCorrect && isUserChoice) {
              // Bonne réponse sélectionnée
              backgroundColor = TuuurTheme.brandGreen.withOpacity(0.2);
              borderColor = TuuurTheme.brandGreen;
              textColor = TuuurTheme.brandGreen;
              icon = FontAwesomeIcons.check;
            } else if (isCorrect) {
              // Bonne réponse non sélectionnée
              backgroundColor = TuuurTheme.brandGreen.withOpacity(0.1);
              borderColor = TuuurTheme.brandGreen.withOpacity(0.4);
              textColor = TuuurTheme.brandGreen;
              icon = FontAwesomeIcons.check;
            } else if (isUserChoice) {
              // Mauvaise réponse sélectionnée
              backgroundColor = TuuurTheme.brandOrange.withOpacity(0.2);
              borderColor = TuuurTheme.brandOrange;
              textColor = TuuurTheme.brandOrange;
              icon = FontAwesomeIcons.xmark;
            } else {
              // Autre réponse
              backgroundColor = TuuurTheme.brandDarkGray.withOpacity(0.3);
              borderColor = TuuurTheme.brandGray.withOpacity(0.2);
              textColor = TuuurTheme.brandGray;
              icon = FontAwesomeIcons.circle;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: backgroundColor,
                border: Border.all(
                  color: borderColor,
                  width: isUserChoice || isCorrect ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  FaIcon(
                    icon,
                    size: icon == FontAwesomeIcons.circle ? 8 : 14,
                    color: textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      answer.value,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: isUserChoice || isCorrect
                            ? FontWeight.w600
                            : FontWeight.normal,
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

  Future<void> _handleLeaveGroup() async {
    if (_isLeaving) return;

    setState(() => _isLeaving = true);

    try {
      await _coordinator.leaveParty();
      if (!mounted) return;
      context.goHome();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLeaving = false);
      context.goHome();
    }
  }

  Future<void> _handleBackToLobby() async {
    if (_isLeaving) return;

    setState(() => _isLeaving = true);

    try {
      // Reset store state to lobby before popping
      _coordinator.store.returnToLobby();
      
      if (!mounted) return;
      // Pop both GroupResultsPage and GroupQuizPage to return to GroupLobbyPage
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      // En cas d'erreur, retourner à l'accueil
      if (!mounted) return;
      setState(() => _isLeaving = false);
      context.goHome();
    }
  }

  Widget _buildActions() {
    return GamingButtonPrimary(
      text: 'Retour au lobby',
      icon: FontAwesomeIcons.arrowLeft,
      onPressed: _isLeaving ? null : _handleBackToLobby,
      isLoading: _isLeaving,
    );
  }
}
