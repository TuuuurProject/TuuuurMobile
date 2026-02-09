import 'package:flutter/material.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

enum MatchmakingState { search, found }

class MatchmakingPage extends StatefulWidget {
  final List<String> categories;
  final VoidCallback onBack;
  final VoidCallback onDuel;

  const MatchmakingPage({
    super.key,
    required this.categories,
    required this.onBack,
    required this.onDuel,
  });

  @override
  State<MatchmakingPage> createState() => _MatchmakingPageState();
}

class _MatchmakingPageState extends State<MatchmakingPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  MatchmakingState state = MatchmakingState.search;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Simule la recherche ➜ trouvé au bout de 3s (comme Vue)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && state == MatchmakingState.search) {
        setState(() => state = MatchmakingState.found);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outer) {
        final isPhone = outer.maxWidth < 420;
        final topSpace = isPhone ? 28.0 : 48.0;

        // Taille du cercle responsive (borne entre 200 et 320)
        final circleSize = _clampDouble(outer.maxWidth * 0.7, 200, 320);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: topSpace),

            // ---- CERCLE ANIMÉ RESPONSIVE ----
            Center(
              child: SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  children: [
                    // Halo de fond
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(circleSize / 2),
                          color: TuuurTheme.brandLightGray.withOpacity(0.12),
                          boxShadow: [
                            BoxShadow(
                              color: TuuurTheme.brandLightGray.withOpacity(
                                0.20,
                              ),
                              blurRadius: 28,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Anneaux pulsants
                    for (int i = 0; i < 3; i++)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final delay = i * 0.38;
                            final animValue =
                                (_pulseController.value + delay) % 1.0;
                            final scale = 0.55 + (animValue * 0.65);
                            final opacity = 0.7 - (animValue * 0.7);

                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    circleSize / 2,
                                  ),
                                  border: Border.all(
                                    color: TuuurTheme.brandOrange.withOpacity(
                                      opacity * 0.35,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Contenu central
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(circleSize / 2),
                          color: Colors.white.withOpacity(0.85),
                          border: Border.all(
                            color: TuuurTheme.brandDark.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 18,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: state == MatchmakingState.search
                              ? _buildSearchContent(isPhone)
                              : _buildFoundContent(isPhone),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: isPhone ? 20 : 28),

            // ---- BOUTONS D'ACTION (responsive) ----
            LayoutBuilder(
              builder: (context, inner) {
                final narrowButtons = inner.maxWidth < 420;

                final cancelBtn = SizedBox(
                  width: narrowButtons ? double.infinity : null,
                  child: GamingButtonSecondary(
                    text: 'Annuler',
                    onPressed: widget.onBack,
                  ),
                );
                final duelBtn = SizedBox(
                  width: narrowButtons ? double.infinity : null,
                  child: GamingButtonPrimary(
                    text: 'Commencer le duel',
                    onPressed: state == MatchmakingState.found
                        ? widget.onDuel
                        : null,
                  ),
                );

                if (narrowButtons) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cancelBtn,
                        const SizedBox(height: 10),
                        duelBtn,
                      ],
                    ),
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [cancelBtn, const SizedBox(width: 12), duelBtn],
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ---- WIDGETS DE CONTENU ----

  Widget _buildSearchContent(bool isPhone) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search,
          size: isPhone ? 34 : 40,
          color: TuuurTheme.brandDark.withOpacity(0.85),
        ),
        const SizedBox(height: 6),
        Text(
          'Recherche',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isPhone ? 20 : 22,
            fontWeight: FontWeight.w600,
            color: TuuurTheme.brandDark.withOpacity(0.92),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Nous cherchons un adversaire…',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TuuurTheme.brandDark.withOpacity(0.70),
            fontSize: isPhone ? 13 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFoundContent(bool isPhone) {
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: TuuurTheme.brandDark.withOpacity(0.92),
      fontSize: isPhone ? 14 : 15,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Joueur 1
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _avatarCircle('🦊', isPhone),
            const SizedBox(width: 10),
            Text('Vous', style: labelStyle),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'VS',
          style: TextStyle(
            fontSize: isPhone ? 22 : 26,
            fontWeight: FontWeight.w600,
            color: TuuurTheme.brandDark.withOpacity(0.92),
          ),
        ),
        const SizedBox(height: 8),
        // Joueur 2
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _avatarCircle('🐯', isPhone, orange: true),
            const SizedBox(width: 10),
            Text('Adversaire', style: labelStyle),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Adversaire trouvé !',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TuuurTheme.brandDark.withOpacity(0.70),
            fontSize: isPhone ? 13 : 14,
          ),
        ),
      ],
    );
  }

  Widget _avatarCircle(String emoji, bool isPhone, {bool orange = false}) {
    final size = isPhone ? 44.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: (orange ? TuuurTheme.brandOrange : TuuurTheme.brandLightGray)
            .withOpacity(0.20),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: isPhone ? 22 : 24)),
      ),
    );
  }

  // ---- helper ----
  double _clampDouble(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
}
