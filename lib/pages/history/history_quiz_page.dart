import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_module.dart';
import '../../api/other/history_api_service.dart';
import '../../api/other/history_models.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/navigation_header.dart';
import '../../widgets/avatar_widget.dart';

class HistoryQuizPage extends StatefulWidget {
  final String partyId;
  final bool isSolo;
  final Object? historyMatchRaw;

  /// Injection point for tests — leave null to use ApiModule.instance.historyApi.
  final HistoryApi? historyApiOverride;

  const HistoryQuizPage({
    super.key,
    required this.partyId,
    this.isSolo = false,
    this.historyMatchRaw,
    this.historyApiOverride,
  });

  @override
  State<HistoryQuizPage> createState() => _HistoryQuizPageState();
}

class _HistoryQuizPageState extends State<HistoryQuizPage> {
  final ScrollController _questionsScrollCtrl = ScrollController();

  bool _loading = true;
  String? _errorMessage;
  PartyDetailDto? _partyDetail;

  HistoryApi get _historyApi =>
      widget.historyApiOverride ?? ApiModule.instance.historyApi;

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

  bool _isRankedMatch(HistoryMatchDto match) {
    return match.idPartyType == 2 ||
        (match.partyType?.label ?? '').toLowerCase() == 'ranked';
  }

  bool get _isRankedParty {
    if (_partyDetail == null) return false;
    return _partyDetail!.idPartyType == 2 ||
        (_partyDetail!.partyType?.label ?? '').toLowerCase() == 'ranked';
  }

  bool get _isGroupParty {
    if (_partyDetail == null) return false;
    return _partyDetail!.idPartyType == 1 ||
        (_partyDetail!.partyType?.label ?? '').toLowerCase() == 'group';
  }

  List<_HistoryLeaderboardEntry> get _groupLeaderboardEntries {
    final detail = _partyDetail;
    if (detail == null || !_isGroupParty) return const [];

    final usersById = <String, HistoryUserDto>{};

    for (final partyUser in detail.partyUsers) {
      final key = partyUser.idUser ?? partyUser.user?.userId;
      if (key != null && key.isNotEmpty && partyUser.user != null) {
        usersById[key] = partyUser.user!;
      }
    }

    final seen = <String>{};
    final entries = <_HistoryLeaderboardEntry>[];

    for (final userScore in detail.userScores) {
      final userId = userScore.userId ?? '';
      final user = usersById[userId] ?? userScore.user;

      if (userId.isEmpty && user == null) {
        continue;
      }

      entries.add(
        _HistoryLeaderboardEntry(
          userId: userId,
          name: user?.displayName ?? 'Joueur',
          avatarBase64: user?.avatar,
          score: userScore.score,
        ),
      );

      if (userId.isNotEmpty) {
        seen.add(userId);
      }
    }

    for (final partyUser in detail.partyUsers) {
      final userId = partyUser.idUser ?? partyUser.user?.userId ?? '';
      if (userId.isEmpty || seen.contains(userId)) continue;

      entries.add(
        _HistoryLeaderboardEntry(
          userId: userId,
          name: partyUser.user?.displayName ?? 'Joueur',
          avatarBase64: partyUser.user?.avatar,
          score: 0,
        ),
      );
    }

    entries.sort((a, b) => b.score.compareTo(a.score));
    return entries;
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return TuuurTheme.brandPurple;
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

  Future<void> _loadPartyDetail() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Ranked: on réutilise directement les données de l'historique.
      if (widget.historyMatchRaw is HistoryMatchDto) {
        final match = widget.historyMatchRaw as HistoryMatchDto;

        if (_isRankedMatch(match)) {
          setState(() {
            _partyDetail = PartyDetailDto(
              id: match.id,
              dt: match.dt,
              idPartyType: match.idPartyType ?? match.partyType?.id,
              idUserHost: null,
              active: false,
              finish: match.finish,
              inProgress: false,
              nbQuestions: match.nbQuestions,
              percent: match.percent,
              score: match.score,
              time: match.time,
              partyType: match.partyType,
              user: null,
              partyDifficulty: match.partyDifficulty,
              partyTheme: match.partyTheme,
              partyQuestions: const [],
              partyUsers: const [],
              userScores: const [],
            );
            _loading = false;
          });
          return;
        }
      }

      // Solo / Group : on charge le détail via l'API.
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
          if (response.statusCode == 404) {
            _errorMessage =
                "${response.message ?? 'Impossible de charger la partie'}\n"
                "S'il s'agit d'une partie Ranked, elle doit être ouverte depuis l'historique avec les données déjà chargées.";
          } else {
            _errorMessage =
                response.message ?? 'Impossible de charger la partie';
          }
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
    if (_isRankedParty) return false;

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

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}min';
    return '${minutes}min ${remainingSeconds}s';
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
      return const Center(child: GamingLoadingIndicator());
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

    const bottomBarHeight = 120.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, bottomBarHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isRankedParty) ...[
                _buildRankedSummaryCard(),
              ] else ...[
                GamingResultSummaryCard(
                  title: _partyDetail!.finish
                      ? 'Partie terminée'
                      : 'Partie en cours',
                  partyType: _partyDetail!.partyType?.label ?? 'Partie',
                  score: _partyDetail!.score ?? 0,
                  totalQuestions: _partyDetail!.partyQuestions.length,
                  correctAnswers: _partyDetail!.partyQuestions
                      .where((pq) => pq.userPartyQuestion?.correct == true)
                      .length,
                  incorrectAnswers:
                      _partyDetail!.partyQuestions.length -
                      _partyDetail!.partyQuestions
                          .where((pq) => pq.userPartyQuestion?.correct == true)
                          .length,
                  successRate: _partyDetail!.partyQuestions.isNotEmpty
                      ? (((_partyDetail!.partyQuestions
                                        .where(
                                          (pq) =>
                                              pq.userPartyQuestion?.correct ==
                                              true,
                                        )
                                        .length) /
                                    _partyDetail!.partyQuestions.length) *
                                100)
                            .round()
                      : 0,
                  isFinished: _partyDetail!.finish,
                ),
                const SizedBox(height: 24),
                _buildPartyInfoCard(),
                if (_isGroupParty && _groupLeaderboardEntries.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildGroupPodium(),
                  if (_groupLeaderboardEntries.length > 3) ...[
                    const SizedBox(height: 24),
                    _buildGroupFullRanking(),
                  ],
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    final sortedQuestions = List<HistoryPartyQuestionDto>.from(
                      _partyDetail!.partyQuestions,
                    )..sort((a, b) => a.order.compareTo(b.order));

                    final reviewQuestions = sortedQuestions.asMap().entries.map(
                      (entry) {
                        final i = entry.key;
                        final HistoryPartyQuestionDto q = entry.value;

                        final answers = (q.question?.answer ?? const [])
                            .map<QuizAnswerReviewItem>(
                              (a) => QuizAnswerReviewItem(
                                label: a.value,
                                isCorrect: a.valid == true,
                                isUserChoice:
                                    q.userPartyQuestion?.idAnswer == a.id,
                                userAnswered:
                                    q.userPartyQuestion?.idAnswer != null,
                              ),
                            )
                            .toList();

                        return QuizQuestionReviewItem(
                          number: i + 1,
                          questionLabel:
                              q.question?.label ?? 'Question non disponible',
                          wasCorrect: q.userPartyQuestion?.correct ?? false,
                          scoreGained: q.userPartyQuestion?.score ?? 0,
                          userAnswered: q.userPartyQuestion?.idAnswer != null,
                          answers: answers,
                        );
                      },
                    ).toList();

                    return GamingQuestionsRecapCard(
                      maxHeight: MediaQuery.of(context).size.height * 0.60,
                      scrollable: true,
                      scrollController: _questionsScrollCtrl,
                      questions: reviewQuestions,
                    );
                  },
                ),
              ],
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

    if (_isRankedParty) {
      return backBtn;
    }

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

  Widget _buildRankedSummaryCard() {
    final score = _partyDetail!.score ?? 0;
    final isVictory = score > 0;
    final accentColor = isVictory
        ? TuuurTheme.brandGreen
        : TuuurTheme.brandOrange;
    final title = isVictory ? 'Victoire' : 'Défaite';

    return Container(
      decoration: TuuurStyles.gamingCard.copyWith(
        border: Border.all(
          color: TuuurTheme.brandPurple.withOpacity(0.30),
          width: 1,
        ),
        boxShadow: TuuurTheme.neonShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: accentColor.withOpacity(0.16),
                        border: Border.all(
                          color: accentColor.withOpacity(0.45),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          isVictory
                              ? FontAwesomeIcons.trophy
                              : FontAwesomeIcons.skullCrossbones,
                          size: 24,
                          color: accentColor,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      duration: 1400.ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.04, 1.04),
                    ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ranked',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TuuurTheme.brandGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: TuuurTheme.brandDark.withOpacity(0.35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: TuuurTheme.brandPurple.withOpacity(0.22),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TuuurTheme.brandGray.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: TuuurTheme.brandLightGray,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_partyDetail!.time != null)
                  _buildRankedInfoTile(
                    icon: FontAwesomeIcons.clock,
                    label: 'Temps',
                    value: _formatDuration(_partyDetail!.time!),
                    color: TuuurTheme.brandPurple,
                  ),
                if (_partyDetail!.dt != null)
                  _buildRankedInfoTile(
                    icon: FontAwesomeIcons.calendar,
                    label: 'Date',
                    value: _formatDate(_partyDetail!.dt!),
                    color: TuuurTheme.brandLightGray,
                  ),
                _buildRankedInfoTile(
                  icon: FontAwesomeIcons.flagCheckered,
                  label: 'Statut',
                  value: _partyDetail!.finish ? 'Terminée' : 'En cours',
                  color: accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 220.ms);
  }

  Widget _buildRankedInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TuuurTheme.brandDark.withOpacity(0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TuuurTheme.brandPurple.withOpacity(0.20)),
      ),
      child: Column(
        children: [
          FaIcon(icon, size: 15, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandGray,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupPodium() {
    final scores = _groupLeaderboardEntries;
    if (scores.isEmpty) return const SizedBox.shrink();

    final first = scores.length > 0 ? scores[0] : null;
    final second = scores.length > 1 ? scores[1] : null;
    final third = scores.length > 2 ? scores[2] : null;

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
              Text(
                _partyDetail!.finish ? 'Podium' : 'Classement provisoire',
                style: const TextStyle(
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
                      _buildGroupPodiumPlace(first, 1, isNarrow: true),
                    const SizedBox(height: 12),
                    if (second != null)
                      _buildGroupPodiumPlace(second, 2, isNarrow: true),
                    const SizedBox(height: 12),
                    if (third != null)
                      _buildGroupPodiumPlace(third, 3, isNarrow: true),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (second != null)
                    Expanded(
                      child: _buildGroupPodiumPlace(second, 2, height: 100),
                    ),
                  const SizedBox(width: 8),
                  if (first != null)
                    Expanded(
                      child: _buildGroupPodiumPlace(first, 1, height: 140),
                    ),
                  const SizedBox(width: 8),
                  if (third != null)
                    Expanded(
                      child: _buildGroupPodiumPlace(third, 3, height: 80),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildGroupPodiumPlace(
    _HistoryLeaderboardEntry entry,
    int rank, {
    double height = 100,
    bool isNarrow = false,
  }) {
    final color = _getRankColor(rank);

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
            avatarBase64: entry.avatarBase64,
            fallbackText: entry.name,
            size: rank == 1 ? 74 : 60,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
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
            '${entry.score} pts',
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
          border: Border.all(color: color.withOpacity(0.3), width: 1),
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
        border: Border.all(color: color, width: 2),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: content),
    );
  }

  Widget _buildGroupFullRanking() {
    final scores = _groupLeaderboardEntries;
    if (scores.length <= 3) return const SizedBox.shrink();

    final remainingScores = scores.skip(3).toList();

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
            final index = entry.key + 3;
            final player = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TuuurTheme.brandPurple.withOpacity(0.2),
                ),
                color: TuuurTheme.brandDarkGray.withOpacity(0.3),
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
                    avatarBase64: player.avatarBase64,
                    fallbackText: player.name,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
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
                      '${player.score} pts',
                      style: const TextStyle(
                        color: TuuurTheme.brandGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: (80 * index).ms).fadeIn().slideX(begin: 0.15);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 650.ms);
  }

  Widget _buildPartyInfoCard() {
    final totalQuestions = _partyDetail!.partyQuestions.length;

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

  Widget _twoPerLineWrap<T>({
    required List<T> items,
    required Widget Function(T item, bool expand) itemBuilder,
    double spacing = 10,
    double minTileWidthFor2Cols = 170,
    bool centerSingle = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing) / 2;

        final wrapAlignment = (centerSingle && items.length == 1)
            ? WrapAlignment.center
            : WrapAlignment.start;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: wrapAlignment,
          children: items.map((it) {
            return SizedBox(width: tileWidth, child: itemBuilder(it, true));
          }).toList(),
        );
      },
    );
  }
}

class _HistoryLeaderboardEntry {
  final String userId;
  final String name;
  final String? avatarBase64;
  final int score;

  const _HistoryLeaderboardEntry({
    required this.userId,
    required this.name,
    required this.avatarBase64,
    required this.score,
  });
}
