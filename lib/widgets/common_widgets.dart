import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tuuuur_theme.dart';
import '../widgets/gaming_widgets.dart';

// Modal Dialog équivalent au ModalDialog.vue
class GamingModal extends StatelessWidget {
  final String title;
  final Widget child;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showActions;

  const GamingModal({
    super.key,
    required this.title,
    required this.child,
    this.confirmText = 'Confirmer',
    this.cancelText = 'Annuler',
    this.onConfirm,
    this.onCancel,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
          color: TuuurTheme.brandDark.withOpacity(0.8),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: TuuurStyles.gamingCard.copyWith(
                border: Border.all(
                  color: TuuurTheme.brandPurple.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: TuuurTheme.neonShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandLightGray,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onCancel ?? () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: TuuurStyles.pill,
                            child: const Icon(
                              Icons.close,
                              color: TuuurTheme.brandLightGray,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: TuuurTheme.brandGray,
                        fontSize: 16,
                      ),
                      child: child,
                    ),
                  ),

                  // Actions
                  if (showActions)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GamingButtonGhost(
                            text: cancelText ?? 'Annuler',
                            onPressed:
                                onCancel ?? () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          GamingButtonPrimary(
                            text: confirmText ?? 'Confirmer',
                            onPressed: onConfirm,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOutBack,
          duration: 300.ms,
        );
  }

  // Méthode statique pour afficher la modal
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showActions = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (context) => GamingModal(
        title: title,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        showActions: showActions,
        child: child,
      ),
    );
  }
}

// Toast Notification équivalent au toast dans App.vue
class ToastManager {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    if (_isVisible) {
      hide();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: TuuurStyles.pill.copyWith(
                      color:
                          backgroundColor ??
                          TuuurTheme.brandDarkGray.withOpacity(0.9),
                      border: Border.all(
                        color: TuuurTheme.brandPurple.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: TuuurTheme.neonShadow,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: TuuurTheme.brandLightGray,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 250.ms)
              .slideY(
                begin: 1.0,
                end: 0.0,
                curve: Curves.easeOutBack,
                duration: 300.ms,
              ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;

    // Auto-hide after duration
    Future.delayed(duration, () {
      hide();
    });
  }

  static void hide() {
    if (_isVisible && _overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }
}

// Loading Indicator
class GamingLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const GamingLoadingIndicator({super.key, this.message, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  TuuurTheme.brandPurple,
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 1000.ms, curve: Curves.linear),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(color: TuuurTheme.brandGray, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// Empty State Widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TuuurTheme.brandPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 40, color: TuuurTheme.brandPurple),
            ).animate().scale(
              begin: const Offset(0.8, 0.8),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: TuuurTheme.brandLightGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, color: TuuurTheme.brandGray),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// Progress Bar Gaming
class GamingProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final String? label;

  const GamingProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor =
        color ??
        (progress < 0.33 ? TuuurTheme.brandOrange : TuuurTheme.brandGreen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? TuuurTheme.brandDark.withOpacity(0.3),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(fontSize: 12, color: TuuurTheme.brandGray),
          ),
        ],
      ],
    );
  }
}

// Modèles UI purs pour les questionnaires
class QuizAnswerReviewItem {
  final String label;
  final bool isCorrect;
  final bool isUserChoice;
  final bool userAnswered;

  const QuizAnswerReviewItem({
    required this.label,
    required this.isCorrect,
    required this.isUserChoice,
    required this.userAnswered,
  });
}

class QuizQuestionReviewItem {
  final int number;
  final String questionLabel;
  final bool wasCorrect;
  final int scoreGained;
  final bool userAnswered;
  final List<QuizAnswerReviewItem> answers;

  const QuizQuestionReviewItem({
    required this.number,
    required this.questionLabel,
    required this.wasCorrect,
    required this.scoreGained,
    required this.userAnswered,
    required this.answers,
  });
}

// Widget récapitulatif
class GamingResultSummaryCard extends StatelessWidget {
  final String title;
  final String partyType;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int successRate;
  final bool isFinished;

  /// Mode "Ranked" : si non-null, colore la carte selon victoire/défaite
  /// (vert/orange) et affiche un badge ELO si [eloDelta] est fourni.
  final bool? isWinner;
  final int? eloDelta;

  const GamingResultSummaryCard({
    super.key,
    required this.title,
    required this.partyType,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.successRate,
    required this.isFinished,
    this.isWinner,
    this.eloDelta,
  });

  Widget _buildEloBadge(bool win, int elo, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.chartLine, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            win ? '+${elo.abs()} ELO' : '-${elo.abs()} ELO',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: TuuurTheme.brandPurple.withOpacity(0.30),
    );
  }

  Widget _buildTopStat({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: TuuurTheme.brandGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ranked = isWinner != null;
    final accent = ranked
        ? (isWinner! ? TuuurTheme.brandGreen : TuuurTheme.brandOrange)
        : null;

    final icon = ranked
        ? (isWinner!
              ? FontAwesomeIcons.crown
              : FontAwesomeIcons.skullCrossbones)
        : (isFinished
              ? FontAwesomeIcons.trophy
              : FontAwesomeIcons.hourglassHalf);

    final ringColor =
        accent ??
        (isFinished ? TuuurTheme.brandYellow : TuuurTheme.brandOrange);

    final titleColor = accent ?? TuuurTheme.brandLightGray;

    return Container(
      // Même cadre (dégradé + bordure) que solo/groupe, quel que soit le mode.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TuuurTheme.brandPurple.withOpacity(0.2)),
        boxShadow: TuuurTheme.cardShadow,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TuuurTheme.brandPurple.withOpacity(0.20),
            TuuurTheme.brandOrange.withOpacity(0.18),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringColor.withOpacity(0.20),
                    border: Border.all(color: ringColor, width: 2),
                  ),
                  child: Center(
                    child: FaIcon(icon, size: 30, color: ringColor),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  duration: 1400.ms,
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.06, 1.06),
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 16),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: titleColor,
                shadows: [
                  Shadow(
                    color: (accent ?? TuuurTheme.brandPurple).withOpacity(0.45),
                    blurRadius: 18,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 120.ms).slideY(begin: -0.2),

            const SizedBox(height: 6),

            Text(
              partyType,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: TuuurTheme.brandGray,
              ),
            ).animate().fadeIn(delay: 180.ms),

            if (ranked && eloDelta != null) ...[
              const SizedBox(height: 14),
              _buildEloBadge(isWinner!, eloDelta!, accent!),
            ],

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTopStat(
                  label: ranked ? 'Score final' : 'Score',
                  value: '$score',
                  valueColor: TuuurTheme.brandYellow,
                ),
                _buildDivider(),
                _buildTopStat(
                  label: 'Questions',
                  value: '$totalQuestions',
                  valueColor: TuuurTheme.brandLightGray,
                ),
                _buildDivider(),
                _buildTopStat(
                  label: ranked ? 'Taux de réussite' : 'Réussite',
                  value: '$successRate%',
                  valueColor: TuuurTheme.brandGreen,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                BadgeSuccess(
                  text: ranked
                      ? '$correctAnswers Correctes'
                      : '$correctAnswers bonnes réponses',
                  icon: FontAwesomeIcons.checkCircle,
                ),
                BadgeWarning(
                  text: ranked
                      ? '$incorrectAnswers Incorrectes'
                      : '$incorrectAnswers mauvaises réponses',
                  icon: FontAwesomeIcons.timesCircle,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 220.ms);
  }
}

class GamingQuestionsRecapCard extends StatelessWidget {
  final String title;
  final List<QuizQuestionReviewItem> questions;
  final bool scrollable;
  final double? maxHeight;
  final ScrollController? scrollController;

  const GamingQuestionsRecapCard({
    super.key,
    this.title = "Récapitulatif des questions",
    required this.questions,
    this.scrollable = false,
    this.maxHeight,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    Widget listContent;

    if (scrollable) {
      listContent = SizedBox(
        height: maxHeight,
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.only(right: 6),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TuuurTheme.brandPurple.withOpacity(0.20),
                  ),
                  color: TuuurTheme.brandDarkGray.withOpacity(0.50),
                ),
                child: GamingQuestionReviewCard(question: questions[index]),
              ).animate(delay: (40 * index).ms).fadeIn().slideX(begin: 0.08);
            },
          ),
        ),
      );
    } else {
      listContent = Column(
        children: questions.asMap().entries.map((entry) {
          final index = entry.key;
          final q = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TuuurTheme.brandPurple.withOpacity(0.2),
              ),
              color: TuuurTheme.brandDarkGray.withOpacity(0.5),
            ),
            child: GamingQuestionReviewCard(question: q),
          ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1);
        }).toList(),
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
                  color: TuuurTheme.brandPurple.withOpacity(0.20),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.listCheck,
                  color: TuuurTheme.brandPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          listContent,
        ],
      ),
    ).animate().fadeIn(delay: scrollable ? 420.ms : 1000.ms);
  }
}

class GamingQuestionReviewCard extends StatelessWidget {
  final QuizQuestionReviewItem question;

  const GamingQuestionReviewCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final wasCorrect = question.wasCorrect;
    final scoreGained = question.scoreGained;
    final userAnswered = question.userAnswered;

    final badgeBg = wasCorrect
        ? TuuurTheme.brandGreen.withOpacity(0.20)
        : (userAnswered
              ? TuuurTheme.brandOrange.withOpacity(0.20)
              : TuuurTheme.brandGray.withOpacity(0.20));

    final badgeBorder = wasCorrect
        ? TuuurTheme.brandGreen.withOpacity(0.40)
        : (userAnswered
              ? TuuurTheme.brandOrange.withOpacity(0.40)
              : TuuurTheme.brandGray.withOpacity(0.40));

    final badgeText = wasCorrect
        ? TuuurTheme.brandGreen
        : (userAnswered ? TuuurTheme.brandOrange : TuuurTheme.brandGray);

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
                  color: badgeBg,
                  border: Border.all(color: badgeBorder),
                ),
                child: Center(
                  child: Text(
                    '${question.number}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: badgeText,
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
                      question.questionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: TuuurTheme.brandLightGray,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: wasCorrect
                            ? TuuurTheme.brandGreen.withOpacity(0.20)
                            : (userAnswered
                                  ? TuuurTheme.brandOrange.withOpacity(0.20)
                                  : TuuurTheme.brandGray.withOpacity(0.20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            wasCorrect
                                ? FontAwesomeIcons.check
                                : (userAnswered
                                      ? FontAwesomeIcons.times
                                      : FontAwesomeIcons.minus),
                            color: wasCorrect
                                ? TuuurTheme.brandGreen
                                : (userAnswered
                                      ? TuuurTheme.brandOrange
                                      : TuuurTheme.brandGray),
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            wasCorrect
                                ? 'Bonne réponse +$scoreGained pts'
                                : (userAnswered
                                      ? 'Mauvaise réponse'
                                      : 'Pas de réponse'),
                            style: TextStyle(
                              color: wasCorrect
                                  ? TuuurTheme.brandGreen
                                  : (userAnswered
                                        ? TuuurTheme.brandOrange
                                        : TuuurTheme.brandGray),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
          LayoutBuilder(
            builder: (context, constraints) {
              // Only phone layout for group page, web layout like was found in history?
              // The original logic used two cols for history and 1 col for group...
              // So we can compute width for 2 columns. If constraints.maxWidth >= 520 then 2 cols.
              final twoCols = constraints.maxWidth >= 520;
              final spacing = 10.0;
              final itemWidth = twoCols
                  ? (constraints.maxWidth - spacing) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: spacing,
                runSpacing: 8,
                children: question.answers.map((answer) {
                  return SizedBox(
                    width: itemWidth,
                    child: GamingAnswerReviewTile(answer: answer),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class GamingAnswerReviewTile extends StatelessWidget {
  final QuizAnswerReviewItem answer;

  const GamingAnswerReviewTile({super.key, required this.answer});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    if (answer.isCorrect && answer.isUserChoice) {
      backgroundColor = TuuurTheme.brandGreen.withOpacity(0.22);
      borderColor = TuuurTheme.brandGreen;
      textColor = TuuurTheme.brandGreen;
      icon = FontAwesomeIcons.check;
    } else if (answer.isCorrect) {
      backgroundColor = TuuurTheme.brandGreen.withOpacity(0.12);
      borderColor = TuuurTheme.brandGreen.withOpacity(0.45);
      textColor = TuuurTheme.brandGreen;
      icon = FontAwesomeIcons.check;
    } else if (answer.isUserChoice) {
      backgroundColor = TuuurTheme.brandOrange.withOpacity(0.22);
      borderColor = TuuurTheme.brandOrange;
      textColor = TuuurTheme.brandOrange;
      icon = FontAwesomeIcons.times;
    } else {
      backgroundColor = TuuurTheme.brandDarkGray.withOpacity(0.25);
      borderColor = TuuurTheme.brandGray.withOpacity(0.20);
      textColor = TuuurTheme.brandGray;
      icon = answer.userAnswered
          ? FontAwesomeIcons.times
          : FontAwesomeIcons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: (answer.isUserChoice || answer.isCorrect) ? 2 : 1,
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
                fontWeight: (answer.isUserChoice || answer.isCorrect)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GamingErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const GamingErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.triangleExclamation,
              color: TuuurTheme.brandOrange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TuuurTheme.brandLightGray,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              GamingButtonSecondary(
                text: 'Retour',
                icon: FontAwesomeIcons.arrowLeft,
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}
