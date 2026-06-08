import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../stores/ranked_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../navigation/app_router.dart';
import '../../api/ranked/ranked_models.dart';

class RankedResultsView extends StatefulWidget {
  const RankedResultsView({super.key});

  @override
  State<RankedResultsView> createState() => _RankedResultsViewState();
}

class _RankedResultsViewState extends State<RankedResultsView> {
  late ConfettiController _confettiController;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isWinner = context.read<RankedStore>().isWinner == true;
      if (isWinner) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  RankedUserScore? _findCurrentUserScore(RankedStore store) {
    final scores = store.finalScores.isNotEmpty
        ? store.finalScores
        : store.currentScores;

    if (scores.isEmpty) return null;

    final opponentId = store.opponent?.id;
    if (opponentId == null) {
      return scores.first;
    }

    for (final score in scores) {
      if (score.user.id != opponentId) {
        return score;
      }
    }

    return scores.first;
  }

  Future<void> _handleGoHome() async {
    if (_isLeaving) return;

    setState(() => _isLeaving = true);

    try {
      await context.read<RankedStore>().disconnect();
    } catch (_) {
      // On force quand même le retour à l'accueil
    }

    if (!mounted) return;
    context.goHome();
  }

  Color _resultColor(bool isWinner) {
    return isWinner ? TuuurTheme.brandGreen : TuuurTheme.brandOrange;
  }

  Widget _buildHeader(bool isWinner) {
    return Column(
      children: [
        FaIcon(
          isWinner ? FontAwesomeIcons.crown : FontAwesomeIcons.skullCrossbones,
          color: isWinner ? TuuurTheme.brandOrange : TuuurTheme.brandOrange,
          size: 52,
        ).animate().scale(
          begin: const Offset(0.5, 0.5),
          duration: 800.ms,
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: 16),
        Text(
          isWinner ? 'Victoire !' : 'Défaite',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: TuuurTheme.brandLightGray,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),
        const SizedBox(height: 8),
        const Text(
          'Partie terminée',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: TuuurTheme.brandGray,
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    double width = 150,
  }) {
    return SizedBox(
      width: width,
      child: Container(
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: TuuurTheme.brandGray,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required bool isWinner,
    required int eloDelta,
    required int finalScore,
    required int totalQuestions,
    required int successRate,
    required int correctCount,
    required int incorrectCount,
  }) {
    final accentColor = _resultColor(isWinner);

    return GamingCard(
      child: Column(
        children: [
          Text(
            isWinner ? 'Victoire' : 'Défaite',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isWinner ? '+$eloDelta ELO' : '-$eloDelta ELO',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard(
                label: 'Score final',
                value: '$finalScore',
                color: TuuurTheme.brandGreen,
              ),
              _buildStatCard(
                label: 'Questions',
                value: '$totalQuestions',
                color: TuuurTheme.brandPurple,
              ),
              _buildStatCard(
                label: 'Taux de réussite',
                value: '$successRate%',
                color: accentColor,
              ),
              _buildStatCard(
                label: 'Correctes',
                value: '$correctCount',
                color: TuuurTheme.brandGreen,
              ),
              _buildStatCard(
                label: 'Incorrectes',
                value: '$incorrectCount',
                color: TuuurTheme.brandOrange,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildQuestionsRecap(List<RankedQuestionHistory> history) {
    if (history.isEmpty) {
      return GamingCard(
        child: Column(
          children: const [
            Text(
              'Récapitulatif des réponses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: TuuurTheme.brandLightGray,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Aucune réponse enregistrée.',
              style: TextStyle(
                color: TuuurTheme.brandGray,
              ),
            ),
          ],
        ),
      );
    }

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
              const Expanded(
                child: Text(
                  'Récapitulatif des réponses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...history.asMap().entries.map((entry) {
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
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildQuestionCard(int questionNumber, RankedQuestionHistory history) {
    final question = history.question.question;
    final answers = question.answer;

    final hasAnswered = history.userAnswerId != null;
    final wasCorrect = history.wasCorrect;

    final badgeColor = !hasAnswered
        ? TuuurTheme.brandGray
        : wasCorrect
            ? TuuurTheme.brandGreen
            : TuuurTheme.brandOrange;

    final badgeLabel = !hasAnswered
        ? 'Aucune réponse'
        : wasCorrect
            ? 'Bonne réponse +${history.scoreGained} pts'
            : 'Mauvaise réponse';

    final badgeIcon = !hasAnswered
        ? FontAwesomeIcons.clock
        : wasCorrect
            ? FontAwesomeIcons.check
            : FontAwesomeIcons.xmark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: badgeColor.withOpacity(0.2),
                  border: Border.all(
                    color: badgeColor.withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
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
                        color: badgeColor.withOpacity(0.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            badgeIcon,
                            color: badgeColor,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeColor,
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

          ...answers.map((answer) {
            final isCorrect = answer.valid == true;
            final isUserChoice = history.userAnswerId == answer.id;

            Color backgroundColor;
            Color borderColor;
            Color textColor;
            IconData icon;

            if (isCorrect && isUserChoice) {
              backgroundColor = TuuurTheme.brandGreen.withOpacity(0.2);
              borderColor = TuuurTheme.brandGreen;
              textColor = TuuurTheme.brandGreen;
              icon = FontAwesomeIcons.check;
            } else if (isCorrect) {
              backgroundColor = TuuurTheme.brandGreen.withOpacity(0.1);
              borderColor = TuuurTheme.brandGreen.withOpacity(0.4);
              textColor = TuuurTheme.brandGreen;
              icon = FontAwesomeIcons.check;
            } else if (isUserChoice) {
              backgroundColor = TuuurTheme.brandOrange.withOpacity(0.2);
              borderColor = TuuurTheme.brandOrange;
              textColor = TuuurTheme.brandOrange;
              icon = FontAwesomeIcons.xmark;
            } else {
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
                      answer.label,
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

  Widget _buildActions() {
    return GamingButtonPrimary(
      text: 'Accueil',
      icon: FontAwesomeIcons.house,
      onPressed: _isLeaving ? null : _handleGoHome,
      isLoading: _isLeaving,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RankedStore>();
    final isWinner = store.isWinner == true;
    final eloDelta = store.eloDelta ?? 0;
    final myScore = _findCurrentUserScore(store)?.score ?? 0;

    final totalQuestions = store.questionsHistory.length;
    final correctCount = store.questionsHistory
        .where((q) => q.wasCorrect)
        .length;
    final incorrectCount = totalQuestions - correctCount;
    final successRate = totalQuestions > 0
        ? ((correctCount / totalQuestions) * 100).round()
        : 0;

    if (_isLeaving) {
      return const Center(
        child: CircularProgressIndicator(color: TuuurTheme.brandPurple),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: SafeArea(
            top: true,
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isWinner),
                    const SizedBox(height: 32),
                    _buildSummaryCard(
                      isWinner: isWinner,
                      eloDelta: eloDelta,
                      finalScore: myScore,
                      totalQuestions: totalQuestions,
                      successRate: successRate,
                      correctCount: correctCount,
                      incorrectCount: incorrectCount,
                    ),
                    const SizedBox(height: 32),
                    _buildQuestionsRecap(store.questionsHistory),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                TuuurTheme.brandOrange,
                TuuurTheme.brandPurple,
                Colors.white,
                TuuurTheme.brandGreen,
              ],
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 10,
            ),
          ),
        ),

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
    );
  }
}