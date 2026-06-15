import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../stores/ranked_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/common_widgets.dart';
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

  List<QuizQuestionReviewItem> _mapQuestionsHistory(
    List<RankedQuestionHistory> history,
  ) {
    return history.asMap().entries.map((entry) {
      final i = entry.key;
      final h = entry.value;
      final base = h.question.question;

      final answers = base.answer
          .map(
            (a) => QuizAnswerReviewItem(
              label: a.label,
              isCorrect: a.valid == true,
              isUserChoice: a.id == h.userAnswerId,
              userAnswered: h.userAnswerId != null,
            ),
          )
          .toList();

      return QuizQuestionReviewItem(
        number: i + 1,
        questionLabel: base.label,
        wasCorrect: h.wasCorrect,
        scoreGained: h.scoreGained,
        userAnswered: h.userAnswerId != null,
        answers: answers,
      );
    }).toList();
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
                    GamingResultSummaryCard(
                      title: isWinner ? 'Victoire' : 'Défaite',
                      partyType: 'Ranked',
                      score: myScore,
                      totalQuestions: totalQuestions,
                      correctAnswers: correctCount,
                      incorrectAnswers: incorrectCount,
                      successRate: successRate,
                      isFinished: true,
                      isWinner: isWinner,
                      eloDelta: eloDelta,
                    ),
                    const SizedBox(height: 32),
                    GamingQuestionsRecapCard(
                      questions: _mapQuestionsHistory(store.questionsHistory),
                    ),
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