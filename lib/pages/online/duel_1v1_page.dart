import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class Duel1v1Page extends StatefulWidget {
  final List<String> categories;
  final VoidCallback onBack;
  final VoidCallback onStart;

  const Duel1v1Page({
    super.key,
    required this.categories,
    required this.onBack,
    required this.onStart,
  });

  @override
  State<Duel1v1Page> createState() => _Duel1v1PageState();
}

class _Duel1v1PageState extends State<Duel1v1Page>
    with TickerProviderStateMixin {
  late AnimationController _vsController;
  bool isReady = false;
  bool opponentReady = false;

  @override
  void initState() {
    super.initState();
    _vsController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Simule la "prêtitude" de l'adversaire
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => opponentReady = true);
    });
  }

  @override
  void dispose() {
    _vsController.dispose();
    super.dispose();
  }

  void toggleReady() => setState(() => isReady = !isReady);

  bool get canStart => isReady && opponentReady;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outer) {
        final isPhone = outer.maxWidth < 420;
        final isNarrow = outer.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- Header responsive --------
            _buildHeader(isPhone).animate().fadeIn().slideX(begin: -0.3),
            SizedBox(height: isPhone ? 16 : 24),

            // -------- Arène principale --------
            Container(
              padding: EdgeInsets.all(isPhone ? 16 : 24),
              decoration: TuuurStyles.gamingCard.copyWith(
                border: Border.all(
                  color: TuuurTheme.brandOrange.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // VS + joueurs : colonne sur mobile, rangée sur large
                  _buildArena(isNarrow: isNarrow, isPhone: isPhone),
                  SizedBox(height: isPhone ? 16 : 24),

                  // Règles du jeu (Wrap => pas d'overflow)
                  _buildRulesCard(
                    isPhone,
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
                  SizedBox(height: isPhone ? 14 : 20),

                  // Catégories (Wrap chips)
                  _buildCategoriesCard(
                    isPhone,
                  ).animate().fadeIn(delay: 1000.ms),
                  SizedBox(height: isPhone ? 18 : 24),

                  // État prêt / pas prêt
                  if (!canStart) ...[
                    _buildReadyHint(isPhone),
                    const SizedBox(height: 12),
                  ],

                  // Boutons d’action (empilement sous 420px)
                  LayoutBuilder(
                    builder: (context, inner) {
                      final stackButtons = inner.maxWidth < 420;

                      final primary = GamingButtonPrimary(
                        text: canStart
                            ? '⚔️ COMMENCER LE DUEL !'
                            : (isReady ? 'Pas prêt' : 'Prêt !'),
                        onPressed: canStart ? widget.onStart : toggleReady,
                      );

                      if (stackButtons) {
                        return Row(children: [Expanded(child: primary)]);
                      }
                      return Row(children: [Expanded(child: primary)]);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          ],
        );
      },
    );
  }

  // ---------- UI blocks ----------

  Widget _buildHeader(bool isPhone) {
    final left = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        // Back
      ],
    );

    final backBtn = GestureDetector(
      onTap: widget.onBack,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: TuuurStyles.pill,
        child: const FaIcon(
          FontAwesomeIcons.arrowLeft,
          color: TuuurTheme.brandLightGray,
          size: 16,
        ),
      ),
    );

    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        FaIcon(FontAwesomeIcons.fire, color: TuuurTheme.brandOrange, size: 22),
        SizedBox(width: 10),
        Flexible(
          child: Text(
            'Duel 1vs1',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ),
        ),
      ],
    );

    final rightPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: TuuurStyles.pill.copyWith(
        color: TuuurTheme.brandOrange.withOpacity(0.2),
        border: Border.all(color: TuuurTheme.brandOrange.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.bolt,
            color: TuuurTheme.brandOrange,
            size: 12,
          ),
          SizedBox(width: 6),
          Text(
            'Compétitif',
            style: TextStyle(
              color: TuuurTheme.brandOrange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              backBtn,
              const SizedBox(width: 12),
              Expanded(child: titleRow),
            ],
          ),
          const SizedBox(height: 10),
          rightPill,
        ],
      );
    }

    return Row(
      children: [
        backBtn,
        const SizedBox(width: 12),
        Expanded(child: titleRow),
        const SizedBox(width: 12),
        rightPill,
      ],
    );
  }

  Widget _buildArena({required bool isNarrow, required bool isPhone}) {
    final vsSize = isNarrow ? 64.0 : 80.0;

    final vsCircle = Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
      child: AnimatedBuilder(
        animation: _vsController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_vsController.value * 0.2),
            child: Container(
              width: vsSize,
              height: vsSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(vsSize / 2),
                color: TuuurTheme.brandOrange.withOpacity(0.2),
                border: Border.all(color: TuuurTheme.brandOrange, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: TuuurTheme.brandOrange.withOpacity(
                      _vsController.value * 0.5,
                    ),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TuuurTheme.brandOrange,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 600.ms);

    final you = _buildPlayerCard(
      emoji: '🎮',
      name: 'Vous',
      level: 'Niveau 23',
      isReady: isReady,
      isPlayer: true,
    );

    final oppo = _buildPlayerCard(
      emoji: '🤖',
      name: 'CyberQuiz_Master',
      level: 'Niveau 47',
      isReady: opponentReady,
      isPlayer: false,
    );

    if (isNarrow) {
      return Column(
        children: [
          you,
          const SizedBox(height: 12),
          vsCircle,
          const SizedBox(height: 12),
          oppo,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: you),
        vsCircle,
        Expanded(child: oppo),
      ],
    );
  }

  Widget _buildRulesCard(bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 14 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: TuuurTheme.brandDarkGray.withOpacity(0.3),
        border: Border.all(color: TuuurTheme.brandPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.trophy,
                color: TuuurTheme.brandPurple,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Règles du Duel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, inner) {
              final wrapH = inner.maxWidth < 420;
              final rules = [
                _buildGameRule(
                  icon: FontAwesomeIcons.clock,
                  title: '10 Questions',
                  description: 'Temps limité',
                ),
                _buildGameRule(
                  icon: FontAwesomeIcons.bolt,
                  title: 'Points rapides',
                  description: 'Réponse + vitesse',
                ),
                _buildGameRule(
                  icon: FontAwesomeIcons.crown,
                  title: 'Victoire',
                  description: 'Meilleur score',
                ),
              ];

              if (wrapH) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: rules
                      .map((w) => SizedBox(width: 140, child: w))
                      .toList(),
                );
              }
              return Row(
                children: rules.map((w) => Expanded(child: w)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard(bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: TuuurTheme.brandOrange.withOpacity(0.1),
        border: Border.all(color: TuuurTheme.brandOrange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.tags,
                color: TuuurTheme.brandOrange,
                size: 14,
              ),
              SizedBox(width: 8),
              Text(
                'Catégories du duel',
                style: TextStyle(
                  color: TuuurTheme.brandOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((category) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: TuuurStyles.pill.copyWith(
                  color: TuuurTheme.brandOrange.withOpacity(0.2),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: TuuurTheme.brandOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyHint(bool isPhone) {
    final ready = isReady;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: ready
            ? TuuurTheme.brandGreen.withOpacity(0.2)
            : TuuurTheme.brandOrange.withOpacity(0.2),
        border: Border.all(
          color: ready
              ? TuuurTheme.brandGreen.withOpacity(0.3)
              : TuuurTheme.brandOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            ready ? FontAwesomeIcons.check : FontAwesomeIcons.clock,
            color: ready ? TuuurTheme.brandGreen : TuuurTheme.brandOrange,
            size: 14,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              ready
                  ? 'En attente de l\'adversaire...'
                  : 'Cliquez sur "Prêt" pour commencer',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ready ? TuuurTheme.brandGreen : TuuurTheme.brandOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({
    required String emoji,
    required String name,
    required String level,
    required bool isReady,
    required bool isPlayer,
  }) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isPlayer
                ? TuuurTheme.brandPurple.withOpacity(0.1)
                : TuuurTheme.brandDarkGray.withOpacity(0.3),
            border: Border.all(
              color: isPlayer
                  ? TuuurTheme.brandPurple.withOpacity(0.3)
                  : TuuurTheme.brandGray.withOpacity(0.3),
              width: isReady ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(29),
                  color: isPlayer
                      ? TuuurTheme.brandPurple.withOpacity(0.2)
                      : TuuurTheme.brandGray.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(height: 10),

              // Name
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),

              // Level
              Text(
                level,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TuuurTheme.brandGray,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),

              // Ready Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: TuuurStyles.pill.copyWith(
                  color: isReady
                      ? TuuurTheme.brandGreen.withOpacity(0.2)
                      : TuuurTheme.brandOrange.withOpacity(0.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      isReady ? FontAwesomeIcons.check : FontAwesomeIcons.clock,
                      color: isReady
                          ? TuuurTheme.brandGreen
                          : TuuurTheme.brandOrange,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isReady ? 'Prêt' : 'En attente',
                      style: TextStyle(
                        color: isReady
                            ? TuuurTheme.brandGreen
                            : TuuurTheme.brandOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (isPlayer ? 400 : 600).ms)
        .slideX(begin: isPlayer ? -0.25 : 0.25);
  }

  Widget _buildGameRule({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      children: [
        FaIcon(icon, color: TuuurTheme.brandPurple, size: 18),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: TuuurTheme.brandLightGray,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: TuuurTheme.brandGray, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
