import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/tuuuur_theme.dart';
import '../widgets/gaming_widgets.dart';
import '../navigation/app_router.dart';
import '../stores/auth_store.dart';
import '../stores/ranked_store.dart';
import '../api/api_module.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _logoController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particleController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AuthStore.instance.isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (AuthStore.instance.isGuest) AuthStore.instance.signOut();
      });
    }

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // le système a déjà géré le pop
        context.goBack();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: TuuurTheme.gamingGradient),
          child: SafeArea(
            child: Stack(
              children: [
                // Particules animées en arrière-plan
                _buildAnimatedParticles(),

                // Contenu principal
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo et titre
                        _buildLogoSection(),

                        const SizedBox(height: 32),

                        // Boutons principaux
                        _buildMainButtons(),

                        const SizedBox(height: 40),

                        // Cartes de navigation
                        _buildNavigationCards(),

                        const SizedBox(height: 40),

                        // Footer
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedParticles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return Stack(
            children: [
              // Particule 1
              Positioned(
                top: MediaQuery.of(context).size.height * 0.75,
                right: MediaQuery.of(context).size.width * 0.25,
                child:
                    Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: TuuurTheme.brandOrange.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .moveY(begin: 0, end: -40, duration: 2000.ms)
                        .then()
                        .moveY(begin: -40, end: 0, duration: 2000.ms),
              ),
              // Particule 2
              Positioned(
                top: MediaQuery.of(context).size.height * 0.5,
                left: MediaQuery.of(context).size.width * 0.75,
                child:
                    Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: TuuurTheme.brandGreen.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .moveY(
                          begin: 0,
                          end: -30,
                          duration: 3000.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .moveY(
                          begin: -30,
                          end: 0,
                          duration: 3000.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
              // Particule 3
              Positioned(
                top: MediaQuery.of(context).size.height * 0.33,
                right: MediaQuery.of(context).size.width * 0.33,
                child:
                    Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: TuuurTheme.brandPink.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .rotate(duration: 4000.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: 2000.ms,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.2, 1.2),
                          end: const Offset(0.8, 0.8),
                          duration: 2000.ms,
                        ),
              ),
              // Particule 4
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.25,
                left: MediaQuery.of(context).size.width * 0.5,
                child:
                    Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: TuuurTheme.brandCyan.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .fade(duration: 3000.ms, curve: Curves.easeInOut),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo gaming avec effets de glow
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // gradient: TuuurTheme.purpleGradient,
                    boxShadow: [
                      BoxShadow(
                        color: TuuurTheme.brandPurple.withOpacity(
                          0.3 + (_logoController.value * 0.4),
                        ),
                        blurRadius: 20 + (_logoController.value * 20),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover, // remplit le cercle sans déformer
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            // Titre avec gradient animé
            ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      TuuurTheme.brandPurple,
                      TuuurTheme.brandPink,
                      TuuurTheme.brandOrange,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Tuuuur',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 3000.ms)
                .moveY(
                  begin: 0,
                  end: -10,
                  duration: 3000.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .moveY(
                  begin: -10,
                  end: 0,
                  duration: 3000.ms,
                  curve: Curves.easeInOut,
                ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Quiz fun et compétitif. Jouez en solo, en groupe ou en duel en ligne.',
          style: TextStyle(fontSize: 18, color: TuuurTheme.brandGray),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms, duration: 800.ms),
      ],
    );
  }

  Widget _buildMainButtons() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2.5 : 6,
        children: [
          GamingButtonPrimary(
            text: 'Jouer en solo',
            icon: FontAwesomeIcons.bullseye,
            onPressed: () => context.goSolo(),
          ).animate(delay: 600.ms).fadeIn(duration: 600.ms).slideX(begin: -0.3),

          GamingButtonSecondary(
            text: 'Jouer en groupe',
            icon: FontAwesomeIcons.users,
            onPressed: () => context.goGroup(),
          ).animate(delay: 700.ms).fadeIn(duration: 600.ms).slideX(begin: -0.2),

          GamingButtonGhost(
            text: 'Mode compétitif',
            icon: FontAwesomeIcons.fire,
            onPressed: () async {
              await ApiModule.instance.restartRanked();
              if (!context.mounted) return;
              context.goOnline();
            },
          ).animate(delay: 800.ms).fadeIn(duration: 600.ms).slideX(begin: -0.1),
        ],
      ),
    );
  }

  Widget _buildNavigationCards() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3,
        children: [
          _buildNavigationCard(
                icon: FontAwesomeIcons.user,
                title: 'Profil',
                backgroundColor: TuuurTheme.brandPurple.withOpacity(0.2),
                iconColor: TuuurTheme.brandPurple,
                onTap: () => context.goProfile(),
              )
              .animate(delay: 900.ms)
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          _buildNavigationCard(
                icon: FontAwesomeIcons.trophy,
                title: 'Classement',
                backgroundColor: TuuurTheme.brandOrange.withOpacity(0.2),
                iconColor: TuuurTheme.brandOrange,
                onTap: () => context.goLeaderboard(),
              )
              .animate(delay: 1000.ms)
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GamingCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: TuuurTheme.brandLightGray,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Text(
      '© 2026 Tuuuur',
      style: TextStyle(fontSize: 12, color: TuuurTheme.brandGray),
    ).animate(delay: 1100.ms).fadeIn(duration: 600.ms);
  }
}
