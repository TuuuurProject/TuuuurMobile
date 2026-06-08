import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/api_module.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class RankedMatchmakingView extends StatefulWidget {
  const RankedMatchmakingView({super.key});

  @override
  State<RankedMatchmakingView> createState() => _RankedMatchmakingViewState();
}

class _RankedMatchmakingViewState extends State<RankedMatchmakingView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  int _waitingSeconds = 0;
  StreamSubscription<int>? _timerSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _timerSubscription = Stream.periodic(const Duration(seconds: 1), (i) => i + 1).listen((sec) {
      if (mounted) setState(() => _waitingSeconds = sec);
    });
  }

  @override
  void dispose() {
    _timerSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Radar animation
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 150 + (_pulseController.value * 100),
                    height: 150 + (_pulseController.value * 100),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TuuurTheme.brandOrange.withOpacity(
                          1.0 - _pulseController.value,
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: TuuurTheme.brandOrange,
                ),
                child: const Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: Colors.white,
                  size: 40,
                ),
              ).animate().shimmer(duration: 2.seconds, delay: 500.ms),
            ],
          ),
          const SizedBox(height: 48),

          Text(
            'Recherche d\'adversaire...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.5),

          const SizedBox(height: 12),

          Text(
            'Temps d\'attente : ${_waitingSeconds}s',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 48),

          GamingButtonGhost(
            text: 'Annuler',
            onPressed: () {
              ApiModule.instance.rankedCoordinator.leaveQueue();
            },
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}
