import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import 'group_mode_page.dart';
import 'qr_preview_widget.dart';

class GroupLobbyPage extends StatefulWidget {
  final GroupLobbyData lobby;
  final VoidCallback onBack;

  const GroupLobbyPage({super.key, required this.lobby, required this.onBack});

  @override
  State<GroupLobbyPage> createState() => _GroupLobbyPageState();
}

class _GroupLobbyPageState extends State<GroupLobbyPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------- HEADER (responsive) ----------
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 620;

            final left = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
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
                ),
                const SizedBox(width: 12),
                const Text(
                  'Lobby',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26, // compact
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: TuuurStyles.pill.copyWith(
                    color: TuuurTheme.brandGreen.withOpacity(0.2),
                  ),
                  child: const Text(
                    'En attente d\'hôte',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: TuuurTheme.brandGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );

            final right = Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: TuuurStyles.pill,
                  child: const Text(
                    'Code',
                    style: TextStyle(
                      color: TuuurTheme.brandLightGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: TuuurTheme.brandDarkGray.withOpacity(0.5),
                    border: Border.all(
                      color: TuuurTheme.brandPurple.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    widget.lobby.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: TuuurTheme.brandLightGray,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            );

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [left, const SizedBox(height: 10), right],
              ).animate().fadeIn().slideX(begin: -0.25);
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
            ).animate().fadeIn().slideX(begin: -0.25);
          },
        ),
        const SizedBox(height: 20),

        // ---------- PARAMETER CHIPS ----------
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildParameterChip(
              'Catégories: ${widget.lobby.categories.join(', ')}',
            ),
            _buildParameterChip('Questions: ${widget.lobby.questions}'),
            _buildParameterChip(
              'Mélanger: ${widget.lobby.shuffle ? 'Oui' : 'Non'}',
            ),
            if (widget.lobby.specifics.isNotEmpty)
              _buildParameterChip('Spécifiques: ${widget.lobby.specifics}'),
          ],
        ),
        const SizedBox(height: 24),

        // ---------- CONTENT (Left: players | Right: QR + actions) ----------
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 900;

            final leftPanelBox = Container(
              padding: const EdgeInsets.all(18),
              decoration: TuuurStyles.gamingCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Joueurs',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: TuuurTheme.brandLightGray,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: TuuurStyles.pill,
                        child: Text(
                          '${widget.lobby.players.length} connectés',
                          style: const TextStyle(
                            color: TuuurTheme.brandPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.lobby.players.map((p) => _buildPlayerTile(p)),
                ],
              ),
            );

            final rightPanelBox = Column(
              children: [
                // QR card (inchangé)
                LayoutBuilder(
                  builder: (context, box) {
                    final qrSize = box.maxWidth < 360
                        ? 140.0
                        : box.maxWidth < 460
                        ? 180.0
                        : 220.0;
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: TuuurStyles.gamingCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rejoindre via code',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandLightGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Code',
                                      style: TextStyle(
                                        color: TuuurTheme.brandGray,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.lobby.code,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: TuuurTheme.brandLightGray,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 90),
                                child: GamingButtonSecondary(
                                  text: 'Copier',
                                  onPressed: () {
                                    /* TODO: copier */
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: QRPreviewWidget(
                              text: widget.lobby.code,
                              size: qrSize,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Actions card (inchangé)
                LayoutBuilder(
                  builder: (context, box) {
                    final narrowButtons = box.maxWidth < 420;
                    final quitBtn = SizedBox(
                      width: narrowButtons ? double.infinity : null,
                      child: GamingButtonSecondary(
                        text: 'Quitter',
                        onPressed: widget.onBack,
                      ),
                    );
                    final launchBtn = SizedBox(
                      width: narrowButtons ? double.infinity : null,
                      child: GamingButtonPrimary(
                        text: 'Lancer la partie',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité en démo'),
                              backgroundColor: TuuurTheme.brandOrange,
                            ),
                          );
                        },
                      ),
                    );
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: TuuurStyles.gamingCard,
                      child: Column(
                        children: [
                          const Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandLightGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (narrowButtons)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                quitBtn,
                                const SizedBox(height: 10),
                                launchBtn,
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(child: quitBtn),
                                const SizedBox(width: 12),
                                Expanded(child: launchBtn),
                              ],
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Lecture seule (démo) — l\'hôte peut lancer lorsqu\'il sera prêt.',
                            style: TextStyle(
                              color: TuuurTheme.brandGray,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );

            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftPanelBox,
                  const SizedBox(height: 16),
                  rightPanelBox,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: leftPanelBox),
                const SizedBox(width: 20),
                Expanded(child: rightPanelBox),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------- helpers ----------
  Widget _buildParameterChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: TuuurStyles.pill,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: TuuurTheme.brandLightGray,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPlayerTile(GroupPlayer player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TuuurTheme.brandPurple.withOpacity(0.2)),
        color: TuuurTheme.brandDarkGray.withOpacity(0.3),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              color: TuuurTheme.brandPurple.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: TuuurTheme.brandPurple.withOpacity(0.25),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(player.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
                Text(
                  'ID #${player.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TuuurTheme.brandGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: TuuurStyles.pill,
            child: Text(
              player.status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TuuurTheme.brandPurple,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
