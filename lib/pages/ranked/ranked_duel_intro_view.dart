import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../stores/ranked_store.dart';
import '../../stores/auth_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/avatar_widget.dart';

class RankedDuelIntroView extends StatefulWidget {
  const RankedDuelIntroView({super.key});

  @override
  State<RankedDuelIntroView> createState() => _RankedDuelIntroViewState();
}

class _RankedDuelIntroViewState extends State<RankedDuelIntroView>
    with TickerProviderStateMixin {
  late AnimationController _vsController;

  @override
  void initState() {
    super.initState();
    _vsController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _vsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RankedStore>();
    final me = AuthStore.instance.user;
    final opponent = store.opponent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                  'Adversaire trouvé !',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: TuuurTheme.brandOrange,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.5)
                .then()
                .shimmer(duration: 1.seconds),
            const SizedBox(height: 60),

            // Joueur (Moi)
            _buildPlayerAvatar(
                  name: me?.nickName ?? 'Moi',
                  avatarCode: me?.avatar,
                  isMe: true,
                  elo:
                      null, // We could fetch globalElo if stored in SessionUser
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideX(begin: -2.0, curve: Curves.easeOutQuart),

            const SizedBox(height: 24),

            // VS Animé
            AnimatedBuilder(
              animation: _vsController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_vsController.value * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TuuurTheme.brandPurple,
                      boxShadow: [
                        BoxShadow(
                          color: TuuurTheme.brandOrange.withOpacity(
                            0.5 * _vsController.value,
                          ),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Adversaire
            _buildPlayerAvatar(
                  name: opponent?.nickName ?? 'Adversaire',
                  avatarCode: opponent?.avatar,
                  isMe: false,
                  elo: opponent?.globalElo,
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideX(begin: 2.0, curve: Curves.easeOutQuart),

            const SizedBox(height: 48),
            Text(
              'La partie va bientôt commencer...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ).animate().fadeIn(delay: 1.seconds),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar({
    required String name,
    required String? avatarCode,
    required bool isMe,
    int? elo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: TuuurTheme.brandDarkGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? TuuurTheme.brandOrange : TuuurTheme.brandPurple,
          width: 3,
        ),
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isMe) ...[
            AvatarWidget(
              avatarBase64: avatarCode,
              fallbackText: name.substring(0, 1),
              size: 60,
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (elo != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        FontAwesomeIcons.trophy,
                        size: 14,
                        color: TuuurTheme.brandOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$elo Elo',
                        style: const TextStyle(
                          color: TuuurTheme.brandOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!isMe) ...[
            const SizedBox(width: 16),
            AvatarWidget(
              avatarBase64: avatarCode,
              fallbackText: name.substring(0, 1),
              size: 60,
            ),
          ],
        ],
      ),
    );
  }
}
