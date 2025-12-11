import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../api/solo_api_service.dart';
import '../../navigation/app_router.dart';
import '../../navigation/navigation_utils.dart';
import '../../stores/auth_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';

class SoloQuizPage extends StatefulWidget {
  final List<String> categories;
  final int questions;
  final int difficulty; // id de difficulté backend

  const SoloQuizPage({
    super.key,
    required this.categories,
    required this.questions,
    required this.difficulty,
  });

  @override
  State<SoloQuizPage> createState() => _SoloQuizPageState();
}

class _SoloQuizPageState extends State<SoloQuizPage>
    with WidgetsBindingObserver {
  static const int totalTime = 15; // secondes (juste pour l'UI)

  AppLifecycleState? _appLifecycleState;
  bool _pendingAutoSubmitOnResume = false;
  int _pendingAnswerIdOnResume = 0;

  // Pour éviter d'appeler _initGame() trop tôt / plusieurs fois
  bool _initialized = false;

  // État de la partie
  String? _partyId;
  int _score = 0;
  int _totalQuestions = 0;
  int _answeredCount = 0;
  bool _finished = false; // état "terminé" renvoyé par le backend

  // Question en cours + éventuelle prochaine question déjà connue
  SoloQuestionViewModel? _currentQuestion;
  SoloQuestionViewModel? _nextQuestion;

  // État de réponse
  bool _answered = false;
  bool _wasCorrect = false;
  int _lastPoints = 0;
  int? _selectedAnswerId;
  bool _submitting = false;

  // Chargement / erreurs
  bool _loading = true;
  String? _error;
  bool _unauthorized = false;

  // Timer visuel
  double _remainingTime = totalTime.toDouble();
  Timer? _timer;

  double get _remainingRatio => max(0, min(1, _remainingTime / totalTime));

  int get _currentQuestionNumber {
    if (_totalQuestions <= 0) {
      return _answeredCount + 1;
    }
    if (_finished) {
      // Si la partie est marquée finie par le backend,
      // on affiche le total de questions (pour le "X / X").
      return _totalQuestions;
    }
    return min(_answeredCount + 1, _totalQuestions);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // NE PAS appeler _initGame() ici, pour éviter dependOnInheritedWidgetOfExactType
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ici, on a le droit d'utiliser les InheritedWidgets (MyAuthStore, Theme, etc.)
    if (!_initialized) {
      _initialized = true;
      _initGame();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      _autoSubmitIfNeeded();
    }
  }

  void _autoSubmitIfNeeded() {
    if (!_pendingAutoSubmitOnResume) return;

    if (_answered || _submitting || _finished) {
      _pendingAutoSubmitOnResume = false;
      return;
    }

    if (_partyId == null || _currentQuestion == null) {
      _pendingAutoSubmitOnResume = false;
      return;
    }

    if (_remainingTime > 0) {
      return;
    }

    _pendingAutoSubmitOnResume = false;
    _submitAnswer(answerId: _pendingAnswerIdOnResume);
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _clearTimer();
    _remainingTime = totalTime.toDouble();
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _remainingTime = max(0, _remainingTime - 0.1);
        });

        if (_remainingTime <= 0) {
          _clearTimer();
          _onTimeUp();
        }
      },
    );
  }

  void _clearTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTimeUp() {
    if (_answered || _submitting || _finished) return;
    if (_currentQuestion == null || _partyId == null) return;

    if (_appLifecycleState == null ||
        _appLifecycleState == AppLifecycleState.resumed) {
      _submitAnswer(answerId: 0);
    } else {
      _pendingAutoSubmitOnResume = true;
      _pendingAnswerIdOnResume = 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Initialisation / API
  // ---------------------------------------------------------------------------

  Future<void> _initGame() async {
    _clearTimer();
    setState(() {
      _loading = true;
      _error = null;
      _unauthorized = false;
      _finished = false;
      _score = 0;
      _answeredCount = 0;
      _totalQuestions = widget.questions;
      _currentQuestion = null;
      _nextQuestion = null;
      _answered = false;
      _wasCorrect = false;
      _lastPoints = 0;
      _selectedAnswerId = null;
    });

    try {
      final store = MyAuthStore.of(context);
      final headers = store.isAuthenticated ? store.authHeaders : null;

      // On suppose que les catégories sont des IDs de thème en string (ex: "1").
      final themeIds = <int>[];
      for (final c in widget.categories) {
        final parsed = int.tryParse(c);
        if (parsed != null) themeIds.add(parsed);
      }

      final difficultyIds = <int>[widget.difficulty];

      // 1) Création de la partie solo
      final createRes = await soloApi.createSolo(
        themeIds: themeIds,
        difficultyIds: difficultyIds,
        nbQuestions: widget.questions,
        headers: headers,
      );

      if (!mounted) return;

      if (!createRes.ok) {
        setState(() {
          _loading = false;
          _error =
              createRes.message ?? 'Impossible de démarrer la partie.';
          _unauthorized = createRes.statusCode == 401;
        });
        return;
      }

      final result = createRes.data;
      final partyId = result?.partyId;

      if (partyId == null || partyId.isEmpty) {
        setState(() {
          _loading = false;
          _error =
              'Réponse inattendue du serveur (id de partie manquant).';
        });
        return;
      }
      _partyId = partyId;

      // 2) Récupération de l’état initial (première question)
      final partyRes = await soloApi.getSolo(
        partyId: partyId,
        headers: headers,
      );

      if (!mounted) return;

      if (!partyRes.ok || partyRes.data == null) {
        setState(() {
          _loading = false;
          _error =
              partyRes.message ?? 'Impossible de récupérer la partie.';
          _unauthorized = partyRes.statusCode == 401;
        });
        return;
      }

      _applyInitialParty(partyRes.data!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erreur: $e';
      });
    }
  }

  /// Recharge la partie depuis le backend (utile si le POST /answer
  /// ne renvoie pas encore la prochaine question).
  Future<void> _reloadParty() async {
    if (_partyId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final store = MyAuthStore.of(context);
      final headers = store.isAuthenticated ? store.authHeaders : null;

      final res = await soloApi.getSolo(
        partyId: _partyId!,
        headers: headers,
      );

      if (!mounted) return;

      if (!res.ok || res.data == null) {
        setState(() {
          _loading = false;
          _error =
              res.message ?? 'Impossible de récupérer la partie.';
          _unauthorized = res.statusCode == 401;
        });
        return;
      }

      _applyInitialParty(res.data!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erreur: $e';
      });
    }
  }

  void _applyInitialParty(SoloPartyDto party) {
    final questions = List<SoloPartyQuestionDto>.from(
      party.partyQuestions,
    );

    // Tri sur order puis id (en gérant les nulls)
    questions.sort((a, b) {
      final ao = a.order ?? 0;
      final bo = b.order ?? 0;
      if (ao != bo) return ao.compareTo(bo);
      final aid = a.id ?? 0;
      final bid = b.id ?? 0;
      return aid.compareTo(bid);
    });

    final answered = questions.where((q) => q.isAnswered).toList();
    final pending = questions.where((q) => !q.isAnswered).toList();

    SoloPartyQuestionDto? current;
    if (pending.isNotEmpty) {
      current = pending.first;
    } else if (answered.isNotEmpty) {
      current = answered.last;
    }

    setState(() {
      _partyId = party.id;
      _score = party.score ?? 0;
      _totalQuestions = party.nbQuestions ?? questions.length;
      _answeredCount = answered.length;
      _finished = party.isFinished;
      _currentQuestion = current != null
          ? SoloQuestionViewModel.fromPartyQuestion(current)
          : null;
      _nextQuestion = null;
      _loading = false;
      _answered = false;
      _wasCorrect = false;
      _lastPoints = 0;
      _selectedAnswerId = null;
    });

    if (!_finished && _currentQuestion != null) {
      _startTimer();
    }
  }

  void _applyAfterAnswer(
    SoloPartyDto party, {
    required int answerId,
  }) {
    final questions = List<SoloPartyQuestionDto>.from(
      party.partyQuestions,
    );

    questions.sort((a, b) {
      final ao = a.order ?? 0;
      final bo = b.order ?? 0;
      if (ao != bo) return ao.compareTo(bo);
      final aid = a.id ?? 0;
      final bid = b.id ?? 0;
      return aid.compareTo(bid);
    });

    final answered = questions.where((q) => q.isAnswered).toList();
    final pending = questions.where((q) => !q.isAnswered).toList();

    final lastAnswered = answered.isNotEmpty ? answered.last : null;
    final next = pending.isNotEmpty ? pending.first : null;

    int lastPoints = 0;
    bool wasCorrect = false;

    if (lastAnswered?.userAnswer != null) {
      final upq = lastAnswered!.userAnswer!;
      lastPoints = upq.score ?? 0;
      wasCorrect = upq.correct ?? false;
    }

    setState(() {
      _partyId = party.id;
      _score = party.score ?? 0;
      _totalQuestions = party.nbQuestions ?? questions.length;
      _answeredCount = answered.length;
      _currentQuestion = lastAnswered != null
          ? SoloQuestionViewModel.fromPartyQuestion(lastAnswered)
          : null;
      _nextQuestion = next != null
          ? SoloQuestionViewModel.fromPartyQuestion(next)
          : null;
      _answered = true;
      _wasCorrect = wasCorrect;
      _lastPoints = lastPoints;
      _selectedAnswerId = answerId;
      _loading = false;
      _submitting = false;
      _finished = party.isFinished; // état de fin fourni par le backend
    });

    _clearTimer();
  }

  // ---------------------------------------------------------------------------
  // Actions (réponses / navigation)
  // ---------------------------------------------------------------------------

  Future<void> _submitAnswer({required int answerId}) async {
    if (_submitting || _partyId == null || _currentQuestion == null) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _selectedAnswerId = answerId;
    });

    try {
      final store = MyAuthStore.of(context);
      final headers = store.isAuthenticated ? store.authHeaders : null;

      final res = await soloApi.answerSolo(
        partyId: _partyId!,
        answerId: answerId,
        headers: headers,
      );

      if (!mounted) return;

      if (!res.ok || res.data == null) {
        setState(() {
          _submitting = false;
          _error =
              res.message ?? 'Erreur lors de l\'envoi de la réponse.';
        });
        ToastManager.show(
          context: context,
          message: _error!,
          backgroundColor: TuuurTheme.brandOrange.withOpacity(0.9),
        );
        return;
      }

      _applyAfterAnswer(res.data!, answerId: answerId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Erreur: $e';
      });
      ToastManager.show(
        context: context,
        message: _error!,
        backgroundColor: TuuurTheme.brandOrange.withOpacity(0.9),
      );
    }
  }

  Future<void> _next() async {
    if (!_answered) return;

    // Si le backend a marqué la partie comme finie,
    // on n'affiche l'écran de résultat que quand l'utilisateur
    // clique sur "Terminer".
    if (_finished) {
      _clearTimer();
      setState(() {
        _currentQuestion = null; // -> affiche les résultats
      });
      return;
    }

    // Si on a déjà une prochaine question dans la réponse précédente,
    // on passe simplement à celle-ci.
    if (_nextQuestion != null) {
      setState(() {
        _currentQuestion = _nextQuestion;
        _nextQuestion = null;
        _answered = false;
        _wasCorrect = false;
        _lastPoints = 0;
        _selectedAnswerId = null;
      });

      _startTimer();
      return;
    }

    // La partie n'est pas finie mais le backend ne nous a pas encore donné
    // la prochaine question : on recharge l'état depuis l'API.
    await _reloadParty();
  }

  void _answer(SoloAnswerViewModel answer) {
    if (_answered || _submitting || _finished) return;
    _submitAnswer(answerId: answer.id);
  }

  /// "Passer" — côté backend, `answerId = 0` représente "pas de réponse".
  void _skip() {
    if (_answered || _submitting || _finished) return;
    _submitAnswer(answerId: 0);
  }

  void _restart() {
    _initGame();
  }

  // ---------------------------------------------------------------------------
  // Helpers UI (couleurs boutons selon correction)
  // ---------------------------------------------------------------------------

  Color _getButtonBgColor(SoloAnswerViewModel answer) {
    if (!_answered) {
      return TuuurTheme.brandDarkGray.withOpacity(0.5);
    }
    if (answer.valid == true) {
      return TuuurTheme.brandGreen.withOpacity(0.2);
    }
    if (_selectedAnswerId != null && answer.id == _selectedAnswerId) {
      return TuuurTheme.brandOrange.withOpacity(0.2);
    }
    return TuuurTheme.brandDarkGray.withOpacity(0.3);
  }

  Color _getButtonBorderColor(SoloAnswerViewModel answer) {
    if (!_answered) {
      return TuuurTheme.brandPurple.withOpacity(0.3);
    }
    if (answer.valid == true) {
      return TuuurTheme.brandGreen;
    }
    if (_selectedAnswerId != null && answer.id == _selectedAnswerId) {
      return TuuurTheme.brandOrange;
    }
    return TuuurTheme.brandPurple.withOpacity(0.3);
  }

  Color _getButtonTextColor(SoloAnswerViewModel answer) {
    if (!_answered) {
      return TuuurTheme.brandLightGray;
    }
    if (answer.valid == true) {
      return TuuurTheme.brandGreen;
    }
    if (_selectedAnswerId != null && answer.id == _selectedAnswerId) {
      return TuuurTheme.brandOrange;
    }
    return TuuurTheme.brandLightGray;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        runWithConfirmIfNeeded(
          context,
          confirm: true,
          message:
              'Voulez-vous vraiment quitter le quiz et retourner en arrière ?',
          action: () => context.goBack(),
        );
      },
      child: Scaffold(
        appBar: const NavigationHeader(
          showBack: true,
          confirmOnBack: true,
          confirmOnHome: true,
          backConfirmMessage:
              'Voulez-vous vraiment quitter le quiz et retourner en arrière ?',
          homeConfirmMessage:
              'Voulez-vous vraiment quitter le quiz et retourner à l\'accueil ?',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTimerSection(),
              const SizedBox(height: 24),
              if (_loading)
                _buildLoadingCard()
              else if (_error != null)
                _buildErrorCard()
              else if (_currentQuestion != null)
                // Affiche la dernière question avec la correction même si la partie est terminée.
                _buildQuestionSection()
              else
                _buildResultsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;

        final right = Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            PillBadge(
              text: _totalQuestions > 0
                  ? 'Question $_currentQuestionNumber / $_totalQuestions'
                  : 'Question $_currentQuestionNumber',
            ),
            PillBadge(text: 'Score: $_score'),
          ],
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [right],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: right,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimerSection() {
    return GamingCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          GamingProgressBar(progress: _remainingRatio, height: 6),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildLoadingCard() {
    return GamingCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            CircularProgressIndicator(color: TuuurTheme.brandPurple),
            SizedBox(height: 12),
            Text(
              'Chargement du quiz…',
              style: TextStyle(color: TuuurTheme.brandGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
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
          Text(
            _error ?? 'Erreur inconnue',
            style: const TextStyle(color: TuuurTheme.brandOrange),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GamingButtonSecondary(
                text: '↻ Réessayer',
                onPressed: _partyId != null ? _reloadParty : _initGame,
              ),
              if (_unauthorized)
                GamingButtonPrimary(
                  text: 'Se connecter',
                  onPressed: () => context.goLogin(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection() {
    final q = _currentQuestion;
    if (q == null) return const SizedBox.shrink();

    const double maxQuestionFontSize = 22;
    const double minQuestionFontSize = 14;
    const double questionLineHeight = 1.2;
    const int questionMaxLines = 3;

    const double questionBoxHeight =
        maxQuestionFontSize * questionLineHeight * questionMaxLines;

    const double feedbackHeight = 28.0;

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: questionBoxHeight,
            child: AutoSizeText(
              q.label,
              maxLines: questionMaxLines,
              minFontSize: minQuestionFontSize,
              stepGranularity: 1,
              style: const TextStyle(
                fontSize: maxQuestionFontSize,
                height: questionLineHeight,
                fontWeight: FontWeight.w600,
                color: TuuurTheme.brandLightGray,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Réponses (responsive)
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
                children: q.answers.map((answer) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: itemWidth,
                      maxWidth: itemWidth,
                    ),
                    child: _OptionButton(
                      label: answer.label,
                      enabled: !_answered && !_submitting && !_loading,
                      onTap: () => _answer(answer),
                      bgColor: _getButtonBgColor(answer),
                      borderColor: _getButtonBorderColor(answer),
                      textColor: _getButtonTextColor(answer),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Feedback + boutons
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;

              final showPasser = !_answered;

              final feedback = _answered
                  ? (_wasCorrect
                      ? BadgeSuccess(text: 'Correct +$_lastPoints pts')
                      : const BadgeWarning(text: 'Mauvaise réponse'))
                  : const SizedBox.shrink();

              Widget nextBtn({bool fullWidth = false}) => SizedBox(
                    width: fullWidth ? double.infinity : null,
                    child: GamingButtonPrimary(
                      text: _finished && _nextQuestion == null
                          ? 'Terminer'
                          : 'Suivant',
                      onPressed: !_answered ? null : () => _next(),
                    ),
                  );

              Widget? skipBtn({bool fullWidth = false}) => showPasser
                  ? SizedBox(
                      width: fullWidth ? double.infinity : null,
                      child: GamingButtonSecondary(
                        text: 'Passer',
                        onPressed: _answered ? null : _skip,
                      ),
                    )
                  : null;

              // Petite zone de feedback avec hauteur fixe
              Widget feedbackSlot = SizedBox(
                height: feedbackHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: 200.ms,
                    child: feedback,
                  ),
                ),
              );

              if (narrow) {
                // Sur mobile : bouton toujours au même endroit,
                // la zone de feedback a une hauteur fixe.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    feedbackSlot,
                    const SizedBox(height: 12),
                    if (showPasser) ...[
                      skipBtn(fullWidth: true)!,
                    ] else ...[
                      nextBtn(fullWidth: true),
                    ],
                  ],
                );
              }

              // Large écran : même principe avec hauteur fixe pour le feedback
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: feedbackSlot),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showPasser) ...[
                        GamingButtonSecondary(
                          text: 'Passer',
                          onPressed: _answered ? null : _skip,
                        ),
                      ] else ...[
                        GamingButtonPrimary(
                          text: _finished && _nextQuestion == null
                              ? 'Terminer'
                              : 'Suivant',
                          onPressed: !_answered ? null : () => _next(),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return GamingCard(
      child: Column(
        children: [
          const Text(
            'Terminé !',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 18,
                color: TuuurTheme.brandGray,
              ),
              children: [
                const TextSpan(text: 'Score final: '),
                TextSpan(
                  text: '$_score',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
                const TextSpan(text: ' pts'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;

              final homeBtn = SizedBox(
                width: narrow ? double.infinity : null,
                child: GamingButtonSecondary(
                  text: 'Accueil',
                  onPressed: () => context.goHome(),
                ),
              );

              if (narrow) {
                return homeBtn;
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  homeBtn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ViewModels pour l’UI (à partir des DTO de solo_api_service.dart)
// -----------------------------------------------------------------------------

class SoloAnswerViewModel {
  final int id;
  final String label;
  final bool? valid;

  SoloAnswerViewModel({
    required this.id,
    required this.label,
    this.valid,
  });
}

class SoloQuestionViewModel {
  final int? partyQuestionId;
  final int? questionId;
  final String label;
  final List<SoloAnswerViewModel> answers;
  final int? selectedAnswerId;
  final bool? correct;

  SoloQuestionViewModel({
    required this.partyQuestionId,
    required this.questionId,
    required this.label,
    required this.answers,
    this.selectedAnswerId,
    this.correct,
  });

  factory SoloQuestionViewModel.fromPartyQuestion(
    SoloPartyQuestionDto pq,
  ) {
    final q = pq.question;
    final user = pq.userAnswer;

    final rawAnswers = q?.answers ?? const <SoloAnswerDto>[];

    final answers = rawAnswers
        .map(
          (a) => SoloAnswerViewModel(
            id: a.id ?? 0,
            label: a.value,
            valid: a.valid,
          ),
        )
        .toList();

    return SoloQuestionViewModel(
      partyQuestionId: pq.id,
      questionId: q?.id,
      label: q?.label ?? '',
      answers: answers,
      selectedAnswerId: user?.answerId,
      correct: user?.correct,
    );
  }
}

// -----------------------------------------------------------------------------
// Bouton d’option (UI pour les réponses)
// -----------------------------------------------------------------------------

class _OptionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _OptionButton({
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
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
