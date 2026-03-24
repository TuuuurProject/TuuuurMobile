import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../stores/ranked_store.dart';
import '../../api/api_module.dart';
import '../../stores/auth_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class RankedQuizView extends StatelessWidget {
  const RankedQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RankedStore>();
    final state = store.state;

    return Column(
      children: [
        _buildHealthBar(context, store),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (state == RankedGameState.countdown)
                  _buildCountdown(store.countdownValue)
                else if (state == RankedGameState.scoreDisplay)
                  _buildScoreReveal(store)
                else
                  _buildQuestionContent(context, store),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown(int? seconds) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Prochaine question dans',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 24),
          Container(
                padding: const EdgeInsets.all(40),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: TuuurTheme.brandPurple,
                ),
                child: Text(
                  '${seconds ?? 0}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
              .animate(key: ValueKey(seconds))
              .scale(duration: 300.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildHealthBar(BuildContext context, RankedStore store) {
    final me = AuthStore.instance.user;
    final opponent = store.opponent;

    int myScore = 5000;
    int oppScore = 5000;

    for (var s in store.currentScores) {
      if (s.user.id == me?.id) {
        myScore = s.score;
      } else {
        oppScore = s.score;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TuuurTheme.brandDarkGray,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Moi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me?.nickName ?? 'Moi',
                  style: const TextStyle(
                    color: TuuurTheme.brandOrange,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$myScore pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Multiplier / VS Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: TuuurTheme.brandDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  FontAwesomeIcons.fire,
                  color: TuuurTheme.brandOrange,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'x${store.currentQuestion?.multiplier.toStringAsFixed(1) ?? "1.0"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Adversaire
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  opponent?.nickName ?? 'Adversaire',
                  style: const TextStyle(
                    color: TuuurTheme.brandPurple,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$oppScore pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool? _getMyAnswerCorrectness(RankedStore store) {
    final q = store.currentQuestion;
    final myAnswerId = store.myAnswerId;

    if (q == null || myAnswerId == null) return null;

    for (final ans in q.question.answer) {
      if (ans.id == myAnswerId) {
        return ans.valid;
      }
    }
    return null;
  }

  Widget _buildQuestionContent(BuildContext context, RankedStore store) {
    final q = store.currentQuestion;
    if (q == null) return const SizedBox.shrink();

    final isReveal = store.state == RankedGameState.answerReveal;
    final myAnswerId = store.myAnswerId;
    final opponentAnswered = store.opponentHasAnswered;
    
    final myAnswerCorrect = _getMyAnswerCorrectness(store);

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heading (Question index & difficulty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tour ${q.currentIndex + 1}',
                style: const TextStyle(
                  color: TuuurTheme.brandOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (q.question.difficulty != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TuuurTheme.brandPurple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    q.question.difficulty!.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Label
          AutoSizeText(
            q.question.label,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Answers
          ...q.question.answer.map((ans) {
            final isSelected = myAnswerId == ans.id;
            bool isCorrect = ans.valid == true;

            Color? bgColor;
            Color? borderColor;

            if (isReveal) {
              if (isCorrect) {
                bgColor = TuuurTheme.brandGreen.withOpacity(0.2);
                borderColor = TuuurTheme.brandGreen;
              } else if (isSelected && !isCorrect) {
                bgColor = Colors.red.withOpacity(0.2);
                borderColor = Colors.red;
              }
            } else if (isSelected) {
              bgColor = TuuurTheme.brandOrange.withOpacity(0.2);
              borderColor = TuuurTheme.brandOrange;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  if (!store.hasAnswered && !isReveal) {
                    store.selectAnswer(ans.id);
                    ApiModule.instance.rankedCoordinator.submitAnswer();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor ?? TuuurTheme.brandDarkGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor ?? Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ans.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isReveal && isCorrect)
                        const Icon(
                          Icons.check_circle,
                          color: TuuurTheme.brandGreen,
                        )
                      else if (isReveal && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          if (!isReveal) ...[
            if (store.hasAnswered)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: BadgeSuccess(text: 'Réponse envoyée ✓'),
                ),
              ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: myAnswerId == null
                    ? const BadgeWarning(text: 'Aucune réponse donnée')
                    : myAnswerCorrect == true
                        ? const BadgeSuccess(text: 'Correct !')
                        : const BadgeWarning(text: 'Mauvaise réponse'),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ],

          // Opponent status
          if (!isReveal && opponentAnswered)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: TuuurTheme.brandOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${store.opponent?.nickName} a répondu !',
                    style: const TextStyle(
                      color: TuuurTheme.brandOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ).animate().fadeIn(),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildScoreReveal(RankedStore store) {
    // Phase où l'on montre l'impact sur les scores avec un petit délai
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Mise à jour des scores...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideY(),
          const SizedBox(height: 48),
          const Icon(
            FontAwesomeIcons.boltLightning,
            color: TuuurTheme.brandOrange,
            size: 64,
          ).animate().shake(hz: 8, duration: 800.ms).shimmer(delay: 400.ms),
        ],
      ),
    );
  }
}
