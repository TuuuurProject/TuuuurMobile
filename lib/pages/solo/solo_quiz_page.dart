import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../navigation/route_history.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/common_widgets.dart';
import '../../navigation/app_router.dart';

class SoloQuizPage extends StatefulWidget {
  final List<String> categories;
  final int questions;
  final bool shuffle;

  const SoloQuizPage({
    super.key,
    required this.categories,
    required this.questions,
    required this.shuffle,
  });

  @override
  State<SoloQuizPage> createState() => _SoloQuizPageState();
}

class _SoloQuizPageState extends State<SoloQuizPage> {
  static const int totalTime = 15; // secondes par question

  List<QuizQuestion> _deck = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  bool _wasCorrect = false;
  int _lastPoints = 0;
  bool _finished = false;

  double _remainingTime = totalTime.toDouble();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _buildDeck();
    _startTimer();
  }

  @override
  void dispose() {
    _clearTimer();
    super.dispose();
  }

  void _buildDeck() {
    final pool = <QuizQuestion>[];
    final categories = widget.categories.isEmpty
        ? ['general']
        : widget.categories;

    for (final category in categories) {
      final questions = _getQuestionsForCategory(category);
      pool.addAll(questions);
    }

    // Fallback si pas assez de questions
    if (pool.length < widget.questions) {
      final allQuestions = _getAllQuestions();
      pool.addAll(allQuestions.where((q) => !pool.contains(q)));
    }

    _deck = widget.shuffle ? _shuffleList(pool) : pool;
    _deck = _deck.take(widget.questions).toList();
  }

  List<QuizQuestion> _getQuestionsForCategory(String category) {
    return _questionBank[category] ?? [];
  }

  List<QuizQuestion> _getAllQuestions() {
    return _questionBank.values.expand((questions) => questions).toList();
  }

  List<T> _shuffleList<T>(List<T> list) {
    final random = Random();
    final shuffled = List<T>.from(list);
    for (int i = shuffled.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      T temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  QuizQuestion get _currentQuestion => _deck[_currentIndex];

  double get _remainingRatio => max(0, _remainingTime / totalTime);

  int get _previewPoints => (30 + 70 * _remainingRatio).round();

  void _startTimer() {
    _clearTimer();
    _remainingTime = totalTime.toDouble();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _remainingTime = max(0, _remainingTime - 0.1);
        if (_remainingTime <= 0) {
          _clearTimer();
          _answered = true;
          _wasCorrect = false;
          _lastPoints = 0;
        }
      });
    });
  }

  void _clearTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _answer(String option) {
    if (_answered) return;

    setState(() {
      _answered = true;
      _clearTimer();

      if (option == _currentQuestion.correct) {
        _wasCorrect = true;
        _lastPoints = (30 + 70 * _remainingRatio).round();
        _score += _lastPoints;
      } else {
        _wasCorrect = false;
        _lastPoints = 0;
      }
    });
  }

  void _skip() {
    if (!_answered) {
      setState(() {
        _answered = true;
        _clearTimer();
        _wasCorrect = false;
        _lastPoints = 0;
      });
    }
  }

  void _next() {
    if (!_answered) return;

    if (_currentIndex + 1 >= _deck.length) {
      setState(() {
        _finished = true;
        _clearTimer();
      });
      return;
    }

    setState(() {
      _currentIndex++;
      _answered = false;
      _wasCorrect = false;
      _lastPoints = 0;
    });
    _startTimer();
  }

  void _restart() {
    setState(() {
      _buildDeck();
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _wasCorrect = false;
      _lastPoints = 0;
      _finished = false;
    });
    _startTimer();
  }

  Color _getButtonColor(String option) {
    if (!_answered) {
      return TuuurTheme.brandDarkGray.withOpacity(0.5);
    }
    if (option == _currentQuestion.correct) {
      return TuuurTheme.brandGreen.withOpacity(0.2);
    } else {
      return TuuurTheme.brandOrange.withOpacity(0.2);
    }
  }

  Color _getButtonBorderColor(String option) {
    if (!_answered) {
      return TuuurTheme.brandPurple.withOpacity(0.3);
    }
    if (option == _currentQuestion.correct) {
      return TuuurTheme.brandGreen;
    } else {
      return TuuurTheme.brandOrange;
    }
  }

  Color _getButtonTextColor(String option) {
    if (!_answered) {
      return TuuurTheme.brandLightGray;
    }
    if (option == _currentQuestion.correct) {
      return TuuurTheme.brandGreen;
    } else {
      return TuuurTheme.brandOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // le système a déjà géré le pop
        RouteHistory.instance.navigateBack(context);
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header avec progress
              _buildHeader(),
              const SizedBox(height: 24),

              // Timer / Progress bar
              _buildTimerSection(),
              const SizedBox(height: 24),

              if (!_finished) ...[
                // Question en cours
                _buildQuestionSection(),
              ] else ...[
                // Résultats finaux
                _buildResultsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.goHome(),
      ),
      title: const Text('Quiz Solo'),
      backgroundColor: TuuurTheme.brandDarkGray.withOpacity(0.8),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;

        final left = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PillBadge(text: '← Accueil', onTap: () => context.goHome()),
            const SizedBox(width: 12),
            const Text(
              'Quiz Solo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: TuuurTheme.brandLightGray,
              ),
            ),
          ],
        );

        final right = Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            PillBadge(text: 'Question ${_currentIndex + 1} / ${_deck.length}'),
            PillBadge(text: 'Score: $_score'),
          ],
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [left, const SizedBox(height: 12), right],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: left),
            const SizedBox(width: 12),
            Flexible(
              child: Align(alignment: Alignment.centerRight, child: right),
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
          // Barre de progression
          GamingProgressBar(progress: _remainingRatio, height: 6),
          // Informations timer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 360;
                final row = Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Temps restant: ${_remainingTime.toStringAsFixed(1)}s',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TuuurTheme.brandLightGray,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '+$_previewPoints pts si correct',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temps restant: ${_remainingTime.toStringAsFixed(1)}s',
                        style: const TextStyle(
                          color: TuuurTheme.brandLightGray,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+$_previewPoints pts si correct',
                        style: const TextStyle(
                          color: TuuurTheme.brandLightGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }
                return row;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection() {
    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question
          Text(
            _currentQuestion.question,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ),
          const SizedBox(height: 16),

          // Options de réponse (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final spacing = 12.0;
              final itemWidth = isWide
                  ? (constraints.maxWidth - spacing) /
                        2 // 2 colonnes avec spacing
                  : constraints.maxWidth; // 1 colonne

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _currentQuestion.options.map((option) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: itemWidth,
                      maxWidth: itemWidth,
                    ),
                    child: _OptionButton(
                      option: option,
                      enabled: !_answered,
                      onTap: () => _answer(option),
                      bgColor: _getButtonColor(option),
                      borderColor: _getButtonBorderColor(option),
                      textColor: _getButtonTextColor(option),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Actions et feedback (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              final showPasser =
                  !_answered; // ⬅️ cacher Passer après réponse / timeout

              final feedback = _answered
                  ? (_wasCorrect
                        ? BadgeSuccess(text: 'Correct +$_lastPoints pts')
                        : const BadgeWarning(text: 'Mauvaise réponse'))
                  : const SizedBox.shrink();

              // Bouton Suivant (activé seulement après réponse)
              Widget nextBtn({bool fullWidth = false}) => SizedBox(
                width: fullWidth ? double.infinity : null,
                child: GamingButtonPrimary(
                  text: 'Suivant',
                  onPressed: !_answered ? null : _next,
                ),
              );

              // Bouton Passer (seulement si pas encore répondu)
              Widget? skipBtn({bool fullWidth = false}) => showPasser
                  ? SizedBox(
                      width: fullWidth ? double.infinity : null,
                      child: GamingButtonSecondary(
                        text: 'Passer',
                        onPressed: _answered ? null : _skip,
                      ),
                    )
                  : null;

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    feedback,
                    const SizedBox(height: 12),
                    if (showPasser) ...[
                      skipBtn(fullWidth: true)!,
                      const SizedBox(height: 12),
                    ],
                    nextBtn(fullWidth: true),
                  ],
                );
              }

              // Largeur suffisante : feedback à gauche, boutons à droite
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  feedback,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showPasser) ...[
                        GamingButtonSecondary(
                          text: 'Passer',
                          onPressed: _answered ? null : _skip,
                        ),
                        const SizedBox(width: 12),
                      ],
                      GamingButtonPrimary(
                        text: 'Suivant',
                        onPressed: !_answered ? null : _next,
                      ),
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
              style: const TextStyle(fontSize: 18, color: TuuurTheme.brandGray),
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

          // Boutons fin — responsive
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
              final replayBtn = SizedBox(
                width: narrow ? double.infinity : null,
                child: GamingButtonPrimary(
                  text: 'Rejouer',
                  onPressed: _restart,
                ),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [homeBtn, const SizedBox(height: 12), replayBtn],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [homeBtn, const SizedBox(width: 16), replayBtn],
              );
            },
          ),
        ],
      ),
    );
  }

  // Banque de questions (équivalent au BANK dans Vue)
  static final Map<String, List<QuizQuestion>> _questionBank = {
    'general': [
      QuizQuestion(
        question: 'Quelle est la capitale de la France ?',
        correct: 'Paris',
        incorrect: ['Lyon', 'Marseille', 'Bordeaux'],
      ),
      QuizQuestion(
        question: 'Combien font 7 × 6 ?',
        correct: '42',
        incorrect: ['36', '48', '54'],
      ),
      QuizQuestion(
        question: 'Quelle planète est surnommée la planète rouge ?',
        correct: 'Mars',
        incorrect: ['Jupiter', 'Vénus', 'Saturne'],
      ),
    ],
    'histoire': [
      QuizQuestion(
        question: 'En quelle année a eu lieu la Révolution française ?',
        correct: '1789',
        incorrect: ['1492', '1815', '1914'],
      ),
      QuizQuestion(
        question: 'Qui était Napoléon Bonaparte ?',
        correct: 'Un empereur français',
        incorrect: ['Un peintre', 'Un physicien', 'Un poète'],
      ),
    ],
    'science': [
      QuizQuestion(
        question: 'Quelle est la formule chimique de l\'eau ?',
        correct: 'H₂O',
        incorrect: ['CO₂', 'O₂', 'NaCl'],
      ),
      QuizQuestion(
        question: 'Quel organe pompe le sang ?',
        correct: 'Le cœur',
        incorrect: ['Le foie', 'Le poumon', 'Le cerveau'],
      ),
    ],
    'sport': [
      QuizQuestion(
        question:
            'Combien de joueurs dans une équipe de football sur le terrain ?',
        correct: '11',
        incorrect: ['9', '10', '12'],
      ),
      QuizQuestion(
        question: 'Dans quel sport utilise-t-on une raquette et un volant ?',
        correct: 'Badminton',
        incorrect: ['Tennis', 'Squash', 'Ping-pong'],
      ),
    ],
    'musique': [
      QuizQuestion(
        question: 'Combien de notes dans une gamme majeure ?',
        correct: '7',
        incorrect: ['5', '6', '8'],
      ),
    ],
    'cinema': [
      QuizQuestion(
        question: 'Qui a réalisé "Inception" ?',
        correct: 'Christopher Nolan',
        incorrect: ['Steven Spielberg', 'James Cameron', 'Ridley Scott'],
      ),
    ],
    'art': [
      QuizQuestion(
        question: 'Qui a peint La Joconde ?',
        correct: 'Léonard de Vinci',
        incorrect: ['Michel-Ange', 'Raphaël', 'Botticelli'],
      ),
    ],
    'geo': [
      QuizQuestion(
        question: 'Quel est le plus grand océan ?',
        correct: 'Pacifique',
        incorrect: ['Atlantique', 'Arctique', 'Indien'],
      ),
    ],
    'tech': [
      QuizQuestion(
        question: 'Que signifie HTML ?',
        correct: 'HyperText Markup Language',
        incorrect: [
          'HighText Makeup Language',
          'Hyperlinks and Text Mark Language',
          'Home Tool Markup Language',
        ],
      ),
    ],
    'jeux': [
      QuizQuestion(
        question: 'Quel studio a créé Minecraft ?',
        correct: 'Mojang',
        incorrect: ['Epic Games', 'Valve', 'Ubisoft'],
      ),
    ],
  };
}

class _OptionButton extends StatelessWidget {
  final String option;
  final bool enabled;
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _OptionButton({
    required this.option,
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
              option,
              softWrap: true,
              // Laisse respirer jusqu’à 3–4 lignes max sans scroller
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 15, // -1pt pour limiter la hauteur
                fontWeight: FontWeight.w600,
                height: 1.25, // compacter un peu la ligne
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final String correct;
  final List<String> incorrect;
  late final List<String> options;

  QuizQuestion({
    required this.question,
    required this.correct,
    required this.incorrect,
  }) {
    // Mélange les options (bonne réponse + mauvaises réponses)
    final allOptions = [correct, ...incorrect];
    allOptions.shuffle();
    options = allOptions.take(4).toList();
  }
}
