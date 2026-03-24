import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../api/api_module.dart';
import '../../stores/ranked_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class RankedJoinView extends StatelessWidget {
  const RankedJoinView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 480;
        final isTablet = constraints.maxWidth < 900;
        final horizontal = isPhone ? 16.0 : (isTablet ? 20.0 : 24.0);
        final vertical = isPhone ? 16.0 : 20.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: vertical,
              ),
              child: const _JoinContent(),
            ),
          ),
        );
      },
    );
  }
}

class _JoinContent extends StatelessWidget {
  const _JoinContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        GamingCard(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TuuurTheme.brandOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TuuurTheme.brandOrange.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.trophy,
                  color: TuuurTheme.brandOrange,
                  size: 28,
                ),
              ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Classé',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: TuuurTheme.brandOrange,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
                    const SizedBox(height: 6),
                    Text(
                      'Affrontez d\'autres joueurs, gagnez de l\'elo et grimpez dans le classement !',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

        const SizedBox(height: 24),

        // Join Action
        GamingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Matchmaking Global',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Le système cherchera un adversaire de votre niveau. Si l\'attente se prolonge, la tolérance d\'elo s\'élargira automatiquement.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: GamingButtonPrimary(
                  text: '🔍 Trouver un Match',
                  onPressed: () {
                    // Start queueing
                    ApiModule.instance.rankedCoordinator.joinQueue();
                  },
                ),
              ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }
}
