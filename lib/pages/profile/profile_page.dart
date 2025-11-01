import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/route_history.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Matching Vue.js exactly - simple auth state switch
  bool isAuthenticated = false;

  // User data when authenticated
  String playerName = 'sanbiX';
  String playerId = '#123456';
  int level = 12;
  int elo = 1210;
  String status = 'Actif';

  String get avatarUrl {
    final seed = Uri.encodeComponent(playerName);
    return 'https://api.dicebear.com/9.x/adventurer-neutral/svg?seed=$seed';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        RouteHistory.instance.navigateBack(context);
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: const NavigationHeader(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('👤', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Profil Joueur',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandLightGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main content responsive
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SidebarDemo(
                          isAuthenticated: isAuthenticated,
                          onSetAuth: (v) => setState(() => isAuthenticated = v),
                        ),
                        const SizedBox(height: 24),
                        _RightPanel(
                          isAuthenticated: isAuthenticated,
                          buildAuthenticatedView: _buildAuthenticatedView,
                          buildUnauthenticatedView: _buildUnauthenticatedView,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left sidebar - Demo status switcher
                        Expanded(
                          flex: 1,
                          child: _SidebarDemo(
                            isAuthenticated: isAuthenticated,
                            onSetAuth: (v) =>
                                setState(() => isAuthenticated = v),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right main panel
                        Expanded(
                          flex: 2,
                          child: _RightPanel(
                            isAuthenticated: isAuthenticated,
                            buildAuthenticatedView: _buildAuthenticatedView,
                            buildUnauthenticatedView: _buildUnauthenticatedView,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String text,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: isSelected
            ? TuuurTheme.brandPurple.withOpacity(0.2)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? TuuurTheme.brandPurple.withOpacity(0.4)
                : TuuurTheme.brandPurple.withOpacity(0.2),
          ),
        ),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: TuuurTheme.brandLightGray,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return Column(
      children: [
        // Gaming icon and welcome text
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: TuuurTheme.brandOrange.withOpacity(0.2),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.gamepad,
                  color: TuuurTheme.brandOrange,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejoignez l\'Aventure',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: TuuurTheme.brandLightGray,
                    ),
                  ),
                  Text(
                    'Sauvegardez votre historique, suivez votre rang et personnalisez votre avatar gaming.',
                    style: TextStyle(color: TuuurTheme.brandGray, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Features grid
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TuuurTheme.brandPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TuuurTheme.brandPurple.withOpacity(0.2),
                  ),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.chartBar,
                          color: TuuurTheme.brandPurple,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Statistiques',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandPurple,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Historique détaillé des parties',
                      style: TextStyle(
                        color: TuuurTheme.brandGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TuuurTheme.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TuuurTheme.brandGreen.withOpacity(0.2),
                  ),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.trophy,
                          color: TuuurTheme.brandGreen,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Classement',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandGreen,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Système de rang compétitif',
                      style: TextStyle(
                        color: TuuurTheme.brandGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Action buttons (déjà responsives via LayoutBuilder)
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 360;
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: GamingButtonPrimary(
                      text: '🚀 Se connecter',
                      onPressed: () => context.push('/login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GamingButtonSecondary(
                      text: '🔗 Créer un compte',
                      onPressed: () => context.push('/register'),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: GamingButtonPrimary(
                    text: '🚀 Se connecter',
                    onPressed: () => context.push('/login'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GamingButtonSecondary(
                    text: '🔗 Créer un compte',
                    onPressed: () => context.push('/register'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAuthenticatedView() {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 420;

    // Sur très petit écran : Wrap pour éviter l’overflow horizontal
    final headerContent = isNarrow
        ? Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              _AvatarWithStatus(avatarUrl: avatarUrl),
              _UserInfo(
                playerName: playerName,
                playerId: playerId,
                status: status,
                level: level,
              ),
              _EloAndModify(elo: elo),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarWithStatus(avatarUrl: avatarUrl),
              const SizedBox(width: 16),
              Expanded(
                child: _UserInfo(
                  playerName: playerName,
                  playerId: playerId,
                  status: status,
                  level: level,
                ),
              ),
              const SizedBox(width: 12),
              _EloAndModify(elo: elo),
            ],
          );

    return Column(
      children: [
        // User profile header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TuuurTheme.brandPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TuuurTheme.brandPurple.withOpacity(0.2)),
          ),
          child: headerContent,
        ),
        const SizedBox(height: 24),

        // Security section — RESPONSIVE, pas d'overflow
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 420;

            final btnText = '🔄 Réinitialiser mot de passe';

            final content = [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: TuuurTheme.brandCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🔒', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sécurité',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                    fontSize: 16,
                  ),
                ),
              ),
              // Le bouton : pas d’Expanded ici pour ne pas forcer trop large
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 0),
                child: GamingButtonSecondary(
                  text: btnText,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité en démo'),
                        backgroundColor: TuuurTheme.brandOrange,
                      ),
                    );
                  },
                ),
              ),
            ];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TuuurTheme.brandDarkGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: TuuurTheme.brandPurple.withOpacity(0.2),
                ),
              ),
              child: narrow
                  // Sur petit écran : on passe en colonne, bouton plein largeur
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: content.sublist(0, 3)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: GamingButtonSecondary(
                            text: btnText,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fonctionnalité en démo'),
                                  backgroundColor: TuuurTheme.brandOrange,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  // Largeur OK : Flow horizontal
                  : Row(children: content),
            );
          },
        ),
        const SizedBox(height: 24),

        // Game history
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('📈', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Historique',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: TuuurTheme.brandLightGray,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Dernières sessions',
                  style: TextStyle(color: TuuurTheme.brandCyan, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: TuuurStyles.gamingCard,
              child: const Row(
                children: [
                  Text(
                    'S',
                    style: TextStyle(
                      color: TuuurTheme.brandGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solo',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TuuurTheme.brandLightGray,
                          ),
                        ),
                        Text(
                          'Score 870',
                          style: TextStyle(
                            color: TuuurTheme.brandGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Aujourd\'hui à 12:45',
                        style: TextStyle(
                          color: TuuurTheme.brandGray,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '+12',
                        style: TextStyle(
                          color: TuuurTheme.brandGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// --- Widgets privés pour aérer le build et éviter l’overflow ---

class _SidebarDemo extends StatelessWidget {
  final bool isAuthenticated;
  final ValueChanged<bool> onSetAuth;
  const _SidebarDemo({required this.isAuthenticated, required this.onSetAuth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: TuuurStyles.gamingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔧', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Statut de Démo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Wrap au lieu de Row pour éviter tout overflow
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _StatusBtn(
                text: '🔓 Déconnecté',
                selected: !isAuthenticated,
                onTap: () => onSetAuth(false),
              ),
              _StatusBtn(
                text: '🔐 Connecté',
                selected: isAuthenticated,
                onTap: () => onSetAuth(true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Basculez pour voir les deux interfaces gaming.',
            style: TextStyle(color: TuuurTheme.brandGray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  final bool isAuthenticated;
  final Widget Function() buildAuthenticatedView;
  final Widget Function() buildUnauthenticatedView;

  const _RightPanel({
    required this.isAuthenticated,
    required this.buildAuthenticatedView,
    required this.buildUnauthenticatedView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: TuuurStyles.gamingCard,
      child: isAuthenticated
          ? buildAuthenticatedView()
          : buildUnauthenticatedView(),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _StatusBtn({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: selected
            ? TuuurTheme.brandPurple.withOpacity(0.2)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? TuuurTheme.brandPurple.withOpacity(0.4)
                : TuuurTheme.brandPurple.withOpacity(0.2),
          ),
        ),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: TuuurTheme.brandLightGray,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _AvatarWithStatus extends StatelessWidget {
  final String avatarUrl;
  const _AvatarWithStatus({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: TuuurTheme.brandPurple, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.network(
              avatarUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: TuuurTheme.brandPurple.withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  color: TuuurTheme.brandPurple,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: TuuurTheme.brandGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TuuurTheme.brandDarkGray, width: 2),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.fire,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserInfo extends StatelessWidget {
  final String playerName;
  final String playerId;
  final String status;
  final int level;

  const _UserInfo({
    required this.playerName,
    required this.playerId,
    required this.status,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          playerName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: TuuurTheme.brandLightGray,
          ),
        ),
        Text(
          'Joueur $playerId',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: TuuurTheme.brandGray, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TuuurTheme.brandGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: TuuurTheme.brandGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TuuurTheme.brandYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Niveau $level',
                style: const TextStyle(
                  color: TuuurTheme.brandYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EloAndModify extends StatelessWidget {
  final int elo;
  const _EloAndModify({required this.elo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: TuuurTheme.brandOrange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TuuurTheme.brandOrange.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.trophy,
                color: TuuurTheme.brandOrange,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'Élo: $elo',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TuuurTheme.brandOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GamingButtonSecondary(
          text: '⚙️ Modifier avatar',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fonctionnalité en démo'),
                backgroundColor: TuuurTheme.brandOrange,
              ),
            );
          },
        ),
      ],
    );
  }
}
