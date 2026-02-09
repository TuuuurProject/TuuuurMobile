import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import 'qr_preview_widget.dart';

class QuizCategory {
  final String id;
  final String name;
  final IconData icon;

  const QuizCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class GroupCreatePage extends StatefulWidget {
  final VoidCallback onBack;
  final Function({
    required List<String> categories,
    required int questions,
    required bool shuffle,
    String? specifics,
  }) onCreated;

  const GroupCreatePage({
    super.key,
    required this.onBack,
    required this.onCreated,
  });

  @override
  State<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  final Set<String> selectedCategories = {'general'};
  int questions = 10;
  bool shuffle = true;
  String specifics = '';
  String roomCode = 'TUR-${DateTime.now().millisecond % 10000}';

  final List<QuizCategory> categories = const [
    QuizCategory(id: 'general', name: 'Général', icon: FontAwesomeIcons.globe),
    QuizCategory(id: 'science', name: 'Sciences', icon: FontAwesomeIcons.flask),
    QuizCategory(id: 'history', name: 'Histoire', icon: FontAwesomeIcons.landmark),
    QuizCategory(id: 'sport', name: 'Sport', icon: FontAwesomeIcons.football),
    QuizCategory(id: 'cinema', name: 'Cinéma', icon: FontAwesomeIcons.film),
    QuizCategory(id: 'music', name: 'Musique', icon: FontAwesomeIcons.music),
    QuizCategory(id: 'art', name: 'Art', icon: FontAwesomeIcons.palette),
    QuizCategory(id: 'geo', name: 'Géographie', icon: FontAwesomeIcons.earthAmericas),
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

  void incrementQuestions() {
    if (questions < 20) setState(() => questions += 5);
  }

  void decrementQuestions() {
    if (questions > 5) setState(() => questions -= 5);
  }

  void createRoom() {
    final selectedCategoryNames = categories
        .where((cat) => selectedCategories.contains(cat.id))
        .map((cat) => cat.name)
        .toList();

    widget.onCreated(
      categories: selectedCategoryNames,
      questions: questions,
      shuffle: shuffle,
      specifics: specifics.isNotEmpty ? specifics : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outer) {
        final narrow = outer.maxWidth < 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (responsive)
            LayoutBuilder(
              builder: (context, header) {
                final isNarrowHeader = header.maxWidth < 420;

                final title = const Text(
                  'Créer une partie',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26, // compact
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                );

                final hint = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: TuuurStyles.pill,
                  child: const Text(
                    'Partagez le code avec vos amis',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: TuuurTheme.brandGray, fontSize: 12),
                  ),
                );

                if (isNarrowHeader) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 8),
                      hint,
                    ],
                  ).animate().fadeIn().slideX(begin: -0.25);
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    Flexible(child: Align(alignment: Alignment.centerRight, child: hint)),
                  ],
                ).animate().fadeIn().slideX(begin: -0.25);
              },
            ),
            const SizedBox(height: 20),

            // Content (Row → Column on mobile)
            if (!narrow)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildSettingsCard()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildRoomCard()),
                ],
              )
            else
              Column(
                children: [
                  _buildSettingsCard(),
                  const SizedBox(height: 16),
                  _buildRoomCard(),
                ],
              ),

            const SizedBox(height: 16),

            // Back button (full width on mobile)
            LayoutBuilder(
              builder: (context, btn) {
                final full = btn.maxWidth < 420;
                return SizedBox(
                  width: full ? double.infinity : null,
                  child: GamingButtonGhost(text: 'Retour', onPressed: widget.onBack),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ---------- SETTINGS CARD ----------
  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(18), // compact
      decoration: TuuurStyles.gamingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paramètres du quiz',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: TuuurTheme.brandLightGray),
          ),
          const SizedBox(height: 6),
          const Text('Choisissez les options pour la partie.', style: TextStyle(color: TuuurTheme.brandGray)),
          const SizedBox(height: 16),

          // Categories
          const Text(
            'Catégories',
            style: TextStyle(fontWeight: FontWeight.w600, color: TuuurTheme.brandLightGray),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories.map((category) {
              final isSelected = selectedCategories.contains(category.id);
              return GestureDetector(
                onTap: () => toggleCategory(category.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected ? TuuurTheme.brandPurple : TuuurTheme.brandDarkGray.withOpacity(0.5),
                    border: Border.all(
                      color: isSelected ? TuuurTheme.brandPurple : TuuurTheme.brandPurple.withOpacity(0.3),
                    ),
                    boxShadow: isSelected ? TuuurTheme.neonShadow : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(category.icon, color: isSelected ? Colors.white : TuuurTheme.brandLightGray, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : TuuurTheme.brandLightGray,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Questions and Shuffle (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 520;

              final questionsBlock = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Nombre de questions',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, color: TuuurTheme.brandLightGray),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: TuuurStyles.pill,
                          child: Text(
                            '$questions',
                            style: const TextStyle(color: TuuurTheme.brandLightGray, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: decrementQuestions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: TuuurStyles.pill,
                            child: const Text('−', style: TextStyle(color: TuuurTheme.brandLightGray, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: questions.toDouble(),
                            min: 5,
                            max: 20,
                            divisions: 3,
                            activeColor: TuuurTheme.brandPurple,
                            onChanged: (value) => setState(() => questions = value.round()),
                          ),
                        ),
                        GestureDetector(
                          onTap: incrementQuestions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: TuuurStyles.pill,
                            child: const Text('＋', style: TextStyle(color: TuuurTheme.brandLightGray, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final shuffleBlock = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: shuffle,
                    onChanged: (v) => setState(() => shuffle = v ?? true),
                    activeColor: TuuurTheme.brandPurple,
                  ),
                  const Flexible(
                    child: Text(
                      'Mélanger les questions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: TuuurTheme.brandLightGray),
                    ),
                  ),
                ],
              );

              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [questionsBlock]),
                    const SizedBox(height: 10),
                    shuffleBlock,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  questionsBlock,
                  const SizedBox(width: 16),
                  shuffleBlock,
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Specifics
          const Text(
            'Catégories spécifiques (champ libre)',
            style: TextStyle(fontWeight: FontWeight.w600, color: TuuurTheme.brandLightGray),
          ),
          const SizedBox(height: 6),
          TextField(
            onChanged: (value) => setState(() => specifics = value),
            style: const TextStyle(color: TuuurTheme.brandLightGray),
            decoration: InputDecoration(
              hintText: 'Ex: Mythologie nordique, Programmation fonctionnelle…',
              hintStyle: const TextStyle(color: TuuurTheme.brandGray),
              filled: true,
              fillColor: TuuurTheme.brandDarkGray.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: TuuurTheme.brandPurple.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: TuuurTheme.brandPurple),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Facultatif — visible par les joueurs.', style: TextStyle(color: TuuurTheme.brandGray, fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.22);
  }

  // ---------- ROOM CARD ----------
  Widget _buildRoomCard() {
    return LayoutBuilder(
      builder: (context, box) {
        final qrSize = box.maxWidth < 380
            ? 140.0
            : box.maxWidth < 520
                ? 160.0
                : 180.0;

        return Container(
          padding: const EdgeInsets.all(18), // compact
          decoration: TuuurStyles.gamingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Salon',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: TuuurTheme.brandLightGray),
              ),
              const SizedBox(height: 12),

              // Room Code row (flex)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Code', style: TextStyle(color: TuuurTheme.brandGray, fontSize: 12)),
                        const SizedBox(height: 2),
                        SelectableText(
                          roomCode,
                          style: const TextStyle(
                            fontSize: 22,
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
                        // TODO: Copy to clipboard (e.g., Clipboard.setData)
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // QR Code (responsive size)
              Center(child: QRPreviewWidget(text: roomCode, size: qrSize)),
              const SizedBox(height: 16),

              // Connected Players
              const Text(
                'Joueurs connectés',
                style: TextStyle(fontWeight: FontWeight.w600, color: TuuurTheme.brandLightGray),
              ),
              const SizedBox(height: 8),

              Column(
                children: [
                  _buildPlayerTile('🦊', 'Alice'),
                  const SizedBox(height: 8),
                  _buildPlayerTile('🐼', 'Ben'),
                ],
              ),
              const SizedBox(height: 20),

              // Create Button (full width)
              SizedBox(
                width: double.infinity,
                child: GamingButtonPrimary(text: 'Créer la partie', onPressed: createRoom),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.22);
      },
    );
  }

  Widget _buildPlayerTile(String emoji, String name) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: TuuurTheme.brandPurple.withOpacity(0.2),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, color: TuuurTheme.brandLightGray),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: TuuurStyles.pill,
          child: const Text('Prêt', style: TextStyle(color: TuuurTheme.brandGreen, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
