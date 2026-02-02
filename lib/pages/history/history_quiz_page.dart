import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_module.dart';
import '../../api/other/history_api_service.dart';
import '../../api/other/history_models.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';

class HistoryQuizPage extends StatefulWidget {
  final String partyId;
  final bool isSolo;

  const HistoryQuizPage({
    super.key,
    required this.partyId,
    this.isSolo = false,
  });

  @override
  State<HistoryQuizPage> createState() => _HistoryQuizPageState();
}

class _HistoryQuizPageState extends State<HistoryQuizPage> {
  final ScrollController _questionsScrollCtrl = ScrollController();
  bool _loading = true;
  String? _errorMessage;
  PartyDetailDto? _partyDetail;

  HistoryApi get _historyApi => ApiModule.instance.historyApi;

  @override
  void initState() {
    super.initState();
    _loadPartyDetail();
  }

  @override
  void dispose() {
    _questionsScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPartyDetail() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = widget.isSolo
          ? await _historyApi.getSoloPartyDetail(widget.partyId)
          : await _historyApi.getPartyDetail(widget.partyId);

      if (!mounted) return;

      if (response.ok && response.data != null) {
        setState(() {
          _partyDetail = response.data;
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Impossible de charger la partie';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur: $e';
        _loading = false;
      });
    }
  }

  bool get _canContinueParty {
    if (_partyDetail == null) return false;
    final isNotFinished = !_partyDetail!.finish;
    final isSolo =
        (_partyDetail!.partyType?.label ?? '').toLowerCase() == 'solo';
    return isNotFinished && isSolo;
  }

  void _navigateToSoloQuiz() {
    if (_partyDetail == null) return;

    context.pushNamed(
      'solo-quiz',
      queryParameters: {
        'partyId': widget.partyId,
        'categories': '',
        'questions': '0',
        'difficulties': '',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuuurTheme.brandDark,
      appBar: const NavigationHeader(showBack: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: TuuurTheme.brandPurple),
      );
    }

    if (_errorMessage != null) {
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
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: TuuurTheme.brandLightGray,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              GamingButtonSecondary(
                text: 'Retour',
                icon: FontAwesomeIcons.arrowLeft,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    if (_partyDetail == null) {
      return const Center(
        child: Text(
          'Aucune donnée',
          style: TextStyle(color: TuuurTheme.brandGray),
        ),
      );
    }

    // Bottom bar sticky (comme le web)
    const bottomBarHeight = 120.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, bottomBarHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopSummaryCard(),
              const SizedBox(height: 24),
              _buildPartyInfoCard(),
              const SizedBox(height: 24),
              _buildQuestionsRecapCard(),
            ],
          ),
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _buildBottomActions(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final backBtn = GamingButtonSecondary(
      text: 'Retour',
      icon: FontAwesomeIcons.arrowLeft,
      onPressed: () => context.pop(),
      width: double.infinity,
    );

    final continueBtn = GamingButtonPrimary(
      text: 'Continuer',
      icon: FontAwesomeIcons.play,
      onPressed: _navigateToSoloQuiz,
      width: double.infinity,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 420;

        if (_canContinueParty) {
          if (isWide) {
            return Row(
              children: [
                Expanded(child: backBtn),
                const SizedBox(width: 12),
                Expanded(child: continueBtn),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [backBtn, const SizedBox(height: 12), continueBtn],
          );
        }

        return backBtn;
      },
    );
  }

  // ====== 1) HEADER “FINISHED CARD” LIKE WEB ======

  Widget _buildTopSummaryCard() {
    final isFinished = _partyDetail!.finish;
    final partyType = _partyDetail!.partyType?.label ?? 'Partie';

    final score = _partyDetail!.score ?? 0;
    final totalQuestions = _partyDetail!.partyQuestions.length;

    final correctAnswers = _partyDetail!.partyQuestions
        .where((pq) => pq.userPartyQuestion?.correct == true)
        .length;

    final incorrectAnswers = totalQuestions - correctAnswers;

    final successRate = totalQuestions > 0
        ? ((correctAnswers / totalQuestions) * 100).round()
        : 0;

    final icon = isFinished
        ? FontAwesomeIcons.trophy
        : FontAwesomeIcons.hourglassHalf;

    final ringColor = isFinished
        ? TuuurTheme.brandYellow
        : TuuurTheme.brandOrange;

    return Container(
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
            // Icon ring (trophy / hourglass)
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
              isFinished ? 'Partie terminée' : 'Partie en cours',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: isFinished
                    ? TuuurTheme.brandLightGray
                    : TuuurTheme.brandLightGray,
                shadows: [
                  Shadow(
                    color: TuuurTheme.brandPurple.withOpacity(0.45),
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

            const SizedBox(height: 20),

            // Stats row: Score / Questions / Success
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTopStat(
                  label: 'Score',
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
                  label: 'Réussite',
                  value: '$successRate%',
                  valueColor: TuuurTheme.brandGreen, // comme web
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Quick badges: correct / incorrect (and optionally unanswered if in progress)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                BadgeSuccess(
                  text: '$correctAnswers bonnes réponses',
                  icon: FontAwesomeIcons.checkCircle,
                ),
                BadgeWarning(
                  text: '$incorrectAnswers mauvaises réponses',
                  icon: FontAwesomeIcons.timesCircle,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 220.ms);
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

  // ====== 2) PARTY INFO CARD (Themes / Difficulties / Nb Questions) ======

  Widget _buildPartyInfoCard() {
    final totalQuestions = _partyDetail!.partyQuestions.length;

    // Difficulties sorted by id like you already did (and web shows them grouped)
    final sortedDifficulties = List.from(
      _partyDetail!.partyDifficulty,
    )..sort((a, b) => (a.difficulty?.id ?? 0).compareTo(b.difficulty?.id ?? 0));

    final List<int> difficultyIds = sortedDifficulties
        .map((pd) => pd.difficulty?.id)
        .whereType<int>()
        .toList();

    final themes =
        _partyDetail!.partyTheme
            .where((pt) => pt.theme?.label != null)
            .map((pt) => pt.theme!.label)
            .toList()
          ..sort((a, b) => a.compareTo(b));

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: TuuurTheme.brandPurple.withOpacity(0.20),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.infoCircle,
                    size: 16,
                    color: TuuurTheme.brandPurple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Infos de la partie',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Themes
          if (themes.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FaIcon(
                  FontAwesomeIcons.tag,
                  size: 16,
                  color: TuuurTheme.brandLightGray,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Thèmes :',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _twoPerLineWrap<String>(
              items: themes,
              itemBuilder: (t, expand) => _buildThemeChip(t, expand: expand),
            ),
            const SizedBox(height: 18),
          ],

          // Difficulties
          if (difficultyIds.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FaIcon(
                  FontAwesomeIcons.fire,
                  size: 16,
                  color: TuuurTheme.brandOrange,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Difficultés :',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _twoPerLineWrap<int>(
              items: difficultyIds,
              itemBuilder: (id, expand) =>
                  _buildDifficultyChip(id, expand: expand),
            ),
            const SizedBox(height: 18),
          ],

          // Number of questions
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.listOl,
                size: 16,
                color: TuuurTheme.brandLightGray,
              ),
              const SizedBox(width: 10),
              Text(
                'Nombre de questions : $totalQuestions',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 320.ms);
  }

  Widget _buildThemeChip(String label, {bool expand = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TuuurTheme.brandDarkGray.withOpacity(0.50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TuuurTheme.brandPurple.withOpacity(0.35),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const FaIcon(
            FontAwesomeIcons.tag,
            size: 14,
            color: TuuurTheme.brandPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TuuurTheme.brandLightGray,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(int id, {bool expand = false}) {
    final label = TuuurTheme.labelForDifficulty(id);
    final color = TuuurTheme.colorForDifficulty(id: id);
    final icon = TuuurTheme.iconForDifficulty(id: id);

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TuuurTheme.brandDarkGray.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.85), width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 18)],
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          FaIcon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TuuurTheme.brandLightGray,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====== 3) QUESTIONS RECAP CARD (scrollable like web) ======

  Widget _buildQuestionsRecapCard() {
    final sortedQuestions = List<HistoryPartyQuestionDto>.from(
      _partyDetail!.partyQuestions,
    )..sort((a, b) => a.order.compareTo(b.order));

    final maxHeight = MediaQuery.of(context).size.height * 0.60;

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
              const Text(
                'Récapitulatif des questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: maxHeight,
            child: Scrollbar(
              controller: _questionsScrollCtrl,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _questionsScrollCtrl,
                padding: const EdgeInsets.only(right: 6),
                itemCount: sortedQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final partyQuestion = sortedQuestions[index];
                  return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: TuuurTheme.brandPurple.withOpacity(0.20),
                          ),
                          color: TuuurTheme.brandDarkGray.withOpacity(0.50),
                        ),
                        child: _buildQuestionCard(index + 1, partyQuestion),
                      )
                      .animate(delay: (40 * index).ms)
                      .fadeIn()
                      .slideX(begin: 0.08);
                },
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 420.ms);
  }

  Widget _buildQuestionCard(
    int questionNumber,
    HistoryPartyQuestionDto partyQuestion,
  ) {
    final question = partyQuestion.question;
    final userAnswer = partyQuestion.userPartyQuestion;

    if (question == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Question non disponible',
          style: TextStyle(color: TuuurTheme.brandGray),
        ),
      );
    }

    final wasCorrect = userAnswer?.correct ?? false;
    final scoreGained = userAnswer?.score ?? 0;
    final userAnswerId = userAnswer?.idAnswer;
    final userAnswered = userAnswerId != null;

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
          // Header question
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
                    '$questionNumber',
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
                      question.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: TuuurTheme.brandLightGray,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Mini badge result : pas de réponse = faux
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: wasCorrect
                            ? TuuurTheme.brandGreen.withOpacity(0.20)
                            : TuuurTheme.brandOrange.withOpacity(0.20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            wasCorrect
                                ? FontAwesomeIcons.check
                                : FontAwesomeIcons.times,
                            color: wasCorrect
                                ? TuuurTheme.brandGreen
                                : TuuurTheme.brandOrange,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            wasCorrect
                                ? 'Bonne réponse +$scoreGained pts'
                                : 'Mauvaise réponse',
                            style: TextStyle(
                              color: wasCorrect
                                  ? TuuurTheme.brandGreen
                                  : TuuurTheme.brandOrange,
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

          // Answers -> grid-like (1 col phone / 2 col tablet) like web `sm:grid-cols-2`
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCols = constraints.maxWidth >= 520;
              final spacing = 10.0;
              final itemWidth = twoCols
                  ? (constraints.maxWidth - spacing) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: spacing,
                runSpacing: 8,
                children: question.answer.map((answer) {
                  final isCorrect = answer.valid;
                  final isUserChoice = userAnswerId == answer.id;

                  return SizedBox(
                    width: itemWidth,
                    child: _buildAnswerTile(
                      label: answer.value,
                      isCorrect: isCorrect,
                      isUserChoice: isUserChoice,
                      userAnswered: userAnswered,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerTile({
    required String label,
    required bool isCorrect,
    required bool isUserChoice,
    required bool userAnswered,
  }) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    if (isCorrect && isUserChoice) {
      backgroundColor = TuuurTheme.brandGreen.withOpacity(0.22);
      borderColor = TuuurTheme.brandGreen;
      textColor = TuuurTheme.brandGreen;
      icon = FontAwesomeIcons.check;
    } else if (isCorrect) {
      backgroundColor = TuuurTheme.brandGreen.withOpacity(0.12);
      borderColor = TuuurTheme.brandGreen.withOpacity(0.45);
      textColor = TuuurTheme.brandGreen;
      icon = FontAwesomeIcons.check;
    } else if (isUserChoice) {
      backgroundColor = TuuurTheme.brandOrange.withOpacity(0.22);
      borderColor = TuuurTheme.brandOrange;
      textColor = TuuurTheme.brandOrange;
      icon = FontAwesomeIcons.times;
    } else {
      backgroundColor = TuuurTheme.brandDarkGray.withOpacity(0.25);
      borderColor = TuuurTheme.brandGray.withOpacity(0.20);
      textColor = TuuurTheme.brandGray;
      icon = userAnswered ? FontAwesomeIcons.times : FontAwesomeIcons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: (isUserChoice || isCorrect) ? 2 : 1,
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
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: (isUserChoice || isCorrect)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoPerLineWrap<T>({
    required List<T> items,
    required Widget Function(T item, bool expand) itemBuilder,
    double spacing = 10,
    double minTileWidthFor2Cols = 170,
    bool centerSingle = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {

        // largeur d'une "case" (1/2 si possible, sinon full)
        final tileWidth = (constraints.maxWidth - spacing) / 2;

        final wrapAlignment = (centerSingle && items.length == 1)
            ? WrapAlignment.center
            : WrapAlignment.start;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: wrapAlignment,
          children: items.map((it) {
            return SizedBox(
              width: (items.length == 1) ? tileWidth : tileWidth,
              child: itemBuilder(it, true), // expand = true
            );
          }).toList(),
        );
      },
    );
  }
}
