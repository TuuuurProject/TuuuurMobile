import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class CompetitiveCategory {
  final String id;
  final String name;
  final IconData icon;

  const CompetitiveCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class CompetitiveSelectPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(List<String>) onSearch;

  const CompetitiveSelectPage({
    super.key,
    required this.onBack,
    required this.onSearch,
  });

  @override
  State<CompetitiveSelectPage> createState() => _CompetitiveSelectPageState();
}

class _CompetitiveSelectPageState extends State<CompetitiveSelectPage> {
  final Set<String> selectedCategories = {'general'};

  final List<CompetitiveCategory> categories = const [
    CompetitiveCategory(
      id: 'general',
      name: 'Général',
      icon: FontAwesomeIcons.wandMagicSparkles,
    ),
    CompetitiveCategory(
      id: 'histoire',
      name: 'Histoire',
      icon: FontAwesomeIcons.university,
    ),
    CompetitiveCategory(
      id: 'science',
      name: 'Science',
      icon: FontAwesomeIcons.flask,
    ),
    CompetitiveCategory(
      id: 'sport',
      name: 'Sport',
      icon: FontAwesomeIcons.medal,
    ),
    CompetitiveCategory(
      id: 'musique',
      name: 'Musique',
      icon: FontAwesomeIcons.music,
    ),
    CompetitiveCategory(
      id: 'cinema',
      name: 'Cinéma',
      icon: FontAwesomeIcons.film,
    ),
    CompetitiveCategory(
      id: 'art',
      name: 'Art',
      icon: FontAwesomeIcons.palette,
    ),
    CompetitiveCategory(
      id: 'geo',
      name: 'Géographie',
      icon: FontAwesomeIcons.globe,
    ),
  ];

  void toggleCategory(String categoryId) {
    setState(() {
      if (selectedCategories.contains(categoryId)) {
        if (selectedCategories.length > 1) {
          selectedCategories.remove(categoryId);
        }
      } else {
        selectedCategories.add(categoryId);
      }
    });
  }

  void proceed() {
    final selectedNames = categories
        .where((cat) => selectedCategories.contains(cat.id))
        .map((cat) => cat.name)
        .toList();
    widget.onSearch(selectedNames);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader()
                .animate()
                .fadeIn(duration: 600.ms)
                .slideX(begin: -0.25),
            const SizedBox(height: 16),

            // ---------------- MAIN CARD ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: TuuurStyles.gamingCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(),
                  const SizedBox(height: 16),

                  // Grid de catégories (Wrap = anti-overflow)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories.map((category) {
                      final isSelected = selectedCategories.contains(
                        category.id,
                      );
                      return _CategoryChip(
                        icon: category.icon,
                        label: category.name,
                        selected: isSelected,
                        onTap: () => toggleCategory(category.id),
                        selectedColor: TuuurTheme.brandOrange,
                      ).animate().fadeIn(
                            delay: (categories.indexOf(category) * 70).ms,
                          );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Info bloc compact
                  _InfoBlockCompact(),
                  const SizedBox(height: 18),

                  // Boutons d'action (responsive sur largeur dispo)
                  LayoutBuilder(
                    builder: (context, inner) {
                      final narrow = inner.maxWidth < 420;

                      final backBtn = SizedBox(
                        width: narrow ? double.infinity : null,
                        child: GamingButtonGhost(
                          text: '← Retour',
                          onPressed: widget.onBack,
                        ),
                      );

                      final searchBtn = SizedBox(
                        width: narrow ? double.infinity : null,
                        child: GamingButtonSecondary(
                          text: '🔍 Lancer la recherche',
                          onPressed:
                              selectedCategories.isNotEmpty ? proceed : null,
                        ),
                      );

                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            backBtn,
                            const SizedBox(height: 10),
                            searchBtn,
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          backBtn,
                          const SizedBox(width: 12),
                          searchBtn,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ---------- widgets privés ----------

  Widget _buildHeader() {
    final right = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: TuuurStyles.pill.copyWith(
        color: TuuurTheme.brandOrange.withOpacity(0.18),
      ),
      child: const Text(
        'Choisissez vos catégories favorites',
        style: TextStyle(
          color: TuuurTheme.brandOrange,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.fire,
              color: TuuurTheme.brandOrange,
              size: 28,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Mode Compétitif',
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
        ),
        const SizedBox(height: 10),
        right,
      ],
    );
  }

  Widget _buildCardHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: TuuurTheme.brandOrange.withOpacity(0.2),
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.bullseye,
              color: TuuurTheme.brandOrange,
              size: 18,
            ),
          ),
        ).animate().rotate(duration: 3000.ms, curve: Curves.linear),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.trophy,
                    color: TuuurTheme.brandOrange,
                    size: 14,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Catégories de Combat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: TuuurTheme.brandLightGray,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Sélectionnez vos domaines d\'expertise pour des duels équilibrés.',
                style: TextStyle(
                  color: TuuurTheme.brandGray,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- sous-composants ----------

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? selectedColor
              : TuuurTheme.brandDarkGray.withOpacity(0.5),
          border: Border.all(
            color: selected ? selectedColor : selectedColor.withOpacity(0.35),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.28),
                    blurRadius: 10,
                    spreadRadius: 1.5,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              color: selected ? Colors.white : TuuurTheme.brandLightGray,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : TuuurTheme.brandLightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlockCompact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: TuuurTheme.brandOrange.withOpacity(0.1),
        border: Border.all(color: TuuurTheme.brandOrange.withOpacity(0.2)),
      ),
      child: const Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _InfoDot(color: TuuurTheme.brandOrange),
          Text(
            'Mode Compétitif',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandOrange,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Affrontez des joueurs de niveau similaire dans des duels rapides. Plus vous gagnez, plus votre rang augmente !',
            style: TextStyle(
              fontSize: 13,
              color: TuuurTheme.brandGray,
              height: 1.2,
            ),
          ),
          SizedBox(width: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoTag(
                text: 'Matchmaking équilibré',
                color: TuuurTheme.brandGreen,
              ),
              _InfoTag(
                text: 'Rang dynamique',
                color: TuuurTheme.brandPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoDot extends StatelessWidget {
  final Color color;
  const _InfoDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: TuuurTheme.brandGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
