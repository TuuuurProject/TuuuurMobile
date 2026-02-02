import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/api_module.dart';
import '../../api/other/difficulty_api_service.dart';
import '../../api/other/difficulty_models.dart';
import '../../api/group/group_models.dart';
import '../../api/group/group_rest_api_service.dart';
import '../../api/other/theme_api_service.dart';
import '../../api/other/theme_models.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';

class GroupSettingsPage extends StatefulWidget {
  /// Partie de groupe actuelle
  final GroupParty party;

  /// ID de l'utilisateur actuel pour vérifier s'il est l'hôte
  final int currentUserId;

  /// Callback appelé lorsque les paramètres sont sauvegardés avec succès
  final VoidCallback onSettingsSaved;

  /// Callback pour revenir en arrière
  final VoidCallback onBack;

  const GroupSettingsPage({
    super.key,
    required this.party,
    required this.currentUserId,
    required this.onSettingsSaved,
    required this.onBack,
  });

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  // API Services
  ThemeApi get _themeApi => ApiModule.instance.themeApi;
  DifficultyApi get _difficultyApi => ApiModule.instance.difficultyApi;
  GroupRestApiService get _groupApi => ApiModule.instance.groupRestApi;

  // Sélections utilisateur
  final Set<int> _selectedThemeIds = {};
  final Set<int> _selectedDifficultyIds = {};
  int _questionCount = 10;
  bool _scoreEachRound = false;

  // Thèmes
  List<ThemeDto> _themes = [];
  bool _loadingThemes = false;
  String? _themeError;

  // Difficultés
  List<DifficultyDto> _difficulties = [];
  bool _loadingDifficulties = false;
  String? _difficultyError;

  // Sauvegarde
  bool _saving = false;

  bool get _isHost => widget.party.idUserHost == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeFromParty();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchThemes();
    _fetchDifficulties();
  }

  void _initializeFromParty() {
    // Initialiser avec les paramètres actuels de la partie
    _questionCount = widget.party.nbQuestions;
    _scoreEachRound = widget.party.scoreEachRound;

    // Initialiser les thèmes sélectionnés
    for (final pt in widget.party.partyTheme) {
      _selectedThemeIds.add(pt.idTheme);
    }

    // Initialiser les difficultés sélectionnées
    for (final pd in widget.party.partyDifficulty) {
      _selectedDifficultyIds.add(pd.idDifficulty);
    }
  }

  Future<void> _fetchThemes() async {
    setState(() {
      _loadingThemes = true;
      _themeError = null;
    });

    try {
      final res = await _themeApi.getThemes();
      if (!mounted) return;

      if (!res.ok) {
        setState(() {
          _loadingThemes = false;
          _themeError = res.message ?? 'Impossible de charger les thèmes';
        });
        return;
      }

      final themes = res.data ?? [];
      themes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        _themes = themes;
        _loadingThemes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingThemes = false;
        _themeError = 'Erreur réseau: $e';
      });
    }
  }

  Future<void> _fetchDifficulties() async {
    setState(() {
      _loadingDifficulties = true;
      _difficultyError = null;
    });

    try {
      final res = await _difficultyApi.getDifficulties();
      if (!mounted) return;

      if (!res.ok) {
        setState(() {
          _loadingDifficulties = false;
          _difficultyError =
              res.message ?? 'Impossible de charger les difficultés';
        });
        return;
      }

      setState(() {
        _difficulties = res.data ?? [];
        _loadingDifficulties = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDifficulties = false;
        _difficultyError = 'Erreur réseau: $e';
      });
    }
  }

  void _toggleTheme(int themeId) {
    if (!_isHost) return;

    setState(() {
      if (_selectedThemeIds.contains(themeId)) {
        _selectedThemeIds.remove(themeId);
      } else {
        _selectedThemeIds.add(themeId);
      }
    });
  }

  void _toggleDifficulty(int difficultyId) {
    if (!_isHost) return;

    setState(() {
      if (_selectedDifficultyIds.contains(difficultyId)) {
        _selectedDifficultyIds.remove(difficultyId);
      } else {
        _selectedDifficultyIds.add(difficultyId);
      }
    });
  }

  Future<void> _saveSettings() async {
    if (!_isHost) {
      _showSnack('Seul l\'hôte peut modifier les paramètres', isError: true);
      return;
    }

    if (_selectedThemeIds.isEmpty) {
      _showSnack('Veuillez sélectionner au moins un thème', isError: true);
      return;
    }

    if (_selectedDifficultyIds.isEmpty) {
      _showSnack(
        'Veuillez sélectionner au moins une difficulté',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final res = await _groupApi.updateSettings(
        themes: _selectedThemeIds.toList(),
        difficulties: _selectedDifficultyIds.toList(),
        nbQuestions: _questionCount,
        scoreEachRound: _scoreEachRound,
      );

      if (!mounted) return;

      if (!res.ok) {
        setState(() => _saving = false);
        _showSnack(
          res.message ?? 'Erreur lors de la sauvegarde',
          isError: true,
        );
        return;
      }

      setState(() => _saving = false);
      _showSnack('Paramètres mis à jour avec succès');
      widget.onSettingsSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Erreur: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? TuuurTheme.brandOrange
            : TuuurTheme.brandGreen,
      ),
    );
  }

  IconData _iconForTheme(ThemeDto theme) {
    final icon = (theme.icon ?? '').toLowerCase().trim();
    final name = theme.name.toLowerCase();

    switch (icon) {
      case 'wand-magic-sparkles':
        return FontAwesomeIcons.wandMagicSparkles;
      case 'building-columns':
        return FontAwesomeIcons.buildingColumns;
      case 'flask':
        return FontAwesomeIcons.flask;
      case 'medal':
        return FontAwesomeIcons.medal;
      case 'music':
        return FontAwesomeIcons.music;
      case 'film':
        return FontAwesomeIcons.film;
      case 'palette':
        return FontAwesomeIcons.palette;
      case 'globe':
        return FontAwesomeIcons.globe;
      case 'laptop-code':
        return FontAwesomeIcons.laptopCode;
      case 'gamepad':
        return FontAwesomeIcons.gamepad;
    }

    // Fallback par nom
    if (name.contains('général') || name.contains('general')) {
      return FontAwesomeIcons.wandMagicSparkles;
    }
    if (name.contains('histoire') || name.contains('history')) {
      return FontAwesomeIcons.buildingColumns;
    }
    if (name.contains('science')) return FontAwesomeIcons.flask;
    if (name.contains('sport')) return FontAwesomeIcons.medal;
    if (name.contains('musique') || name.contains('music')) {
      return FontAwesomeIcons.music;
    }
    if (name.contains('cinéma') ||
        name.contains('cinema') ||
        name.contains('film')) {
      return FontAwesomeIcons.film;
    }
    if (name.contains('art')) return FontAwesomeIcons.palette;
    if (name.contains('géographie') || name.contains('geo')) {
      return FontAwesomeIcons.globe;
    }
    if (name.contains('tech') || name.contains('informatique')) {
      return FontAwesomeIcons.laptopCode;
    }
    if (name.contains('jeu') ||
        name.contains('gaming') ||
        name.contains('vidéo')) {
      return FontAwesomeIcons.gamepad;
    }

    return FontAwesomeIcons.shapes;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavigationHeader(
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paramètres de la partie',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: TuuurTheme.brandLightGray,
              ),
            ).animate().fadeIn().slideX(begin: -0.25),
            const SizedBox(height: 24),

            if (!_isHost) _buildNotHostWarning(),

            if (_loadingThemes || _loadingDifficulties)
              const GamingCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: TuuurTheme.brandPurple,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Chargement des paramètres…',
                          style: TextStyle(color: TuuurTheme.brandGray),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              if (_themeError != null || _difficultyError != null)
                _buildErrorCard()
              else ...[
                _buildThemesSection(),
                const SizedBox(height: 24),
                _buildDifficultiesSection(),
                const SizedBox(height: 24),
                _buildGeneralSettings(),
              ],
            ],

            const SizedBox(height: 32),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotHostWarning() {
    return GamingCard(
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.circleInfo,
            color: TuuurTheme.brandOrange,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Seul l\'hôte peut modifier les paramètres',
              style: TextStyle(color: TuuurTheme.brandLightGray, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final error = _themeError ?? _difficultyError ?? 'Erreur inconnue';

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Erreur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: TuuurTheme.brandOrange)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GamingButtonSecondary(
                text: '↻ Réessayer',
                onPressed: () {
                  if (_themeError != null) _fetchThemes();
                  if (_difficultyError != null) _fetchDifficulties();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemesSection() {
    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.gamepad,
                color: TuuurTheme.brandPurple,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thèmes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez un ou plusieurs thèmes (${_selectedThemeIds.length} sélectionné${_selectedThemeIds.length > 1 ? 's' : ''})',
            style: const TextStyle(color: TuuurTheme.brandGray, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_themes.isEmpty)
            const Text(
              'Aucun thème disponible.',
              style: TextStyle(color: TuuurTheme.brandGray),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _themes.asMap().entries.map((entry) {
                final index = entry.key;
                final theme = entry.value;
                final themeId = theme.id;

                if (themeId == null) return const SizedBox.shrink();

                return CategoryButton(
                      text: theme.name,
                      icon: _iconForTheme(theme),
                      selected: _selectedThemeIds.contains(themeId),
                      onTap: _isHost ? () => _toggleTheme(themeId) : () {},
                    )
                    .animate(delay: (100 * index).ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDifficultiesSection() {
    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.gaugeHigh,
                color: TuuurTheme.brandPurple,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Difficultés',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez une ou plusieurs difficultés (${_selectedDifficultyIds.length} sélectionnée${_selectedDifficultyIds.length > 1 ? 's' : ''})',
            style: const TextStyle(color: TuuurTheme.brandGray, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_difficulties.isEmpty)
            const Text(
              'Aucune difficulté disponible.',
              style: TextStyle(color: TuuurTheme.brandGray),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _difficulties.map((difficulty) {
                final diffId = difficulty.id;

                if (diffId == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CategoryButton(
                    text: TuuurTheme.labelForDifficulty(diffId),
                    icon: TuuurTheme.iconForDifficulty(id: diffId),
                    selected: _selectedDifficultyIds.contains(diffId),
                    customColor: TuuurTheme.colorForDifficulty(id: diffId),
                    onTap: _isHost ? () => _toggleDifficulty(diffId) : () {},
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.gear,
                size: 18,
                color: TuuurTheme.brandLightGray,
              ),
              const SizedBox(width: 10),
              const Text(
                'Paramètres généraux',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nombre de questions
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nombre de questions',
                style: TextStyle(
                  color: TuuurTheme.brandLightGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: TuuurStyles.pill,
                  child: Text(
                    '$_questionCount questions',
                    style: const TextStyle(
                      color: TuuurTheme.brandLightGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _questionCount.toDouble(),
                min: 5,
                max: 20,
                divisions: 3, // 5, 10, 15, 20
                label: '$_questionCount',
                onChanged: _isHost
                    ? (value) {
                        setState(() {
                          _questionCount = value.round();
                        });
                      }
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Score à chaque question
          InkWell(
            onTap: _isHost
                ? () {
                    setState(() {
                      _scoreEachRound = !_scoreEachRound;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TuuurTheme.brandPurple.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Score à chaque question',
                          style: TextStyle(
                            color: TuuurTheme.brandLightGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _scoreEachRound
                              ? 'Les scores seront affichés après chaque question'
                              : 'Les scores ne seront affichés qu\'à la fin',
                          style: const TextStyle(
                            color: TuuurTheme.brandGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _scoreEachRound,
                    onChanged: _isHost
                        ? (value) {
                            setState(() {
                              _scoreEachRound = value;
                            });
                          }
                        : null,
                    activeThumbColor: TuuurTheme.brandGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;

        return Row(
          mainAxisAlignment: narrow
              ? MainAxisAlignment.center
              : MainAxisAlignment.end,
          children: [
            if (narrow) ...[
              Expanded(
                child: GamingButtonSecondary(
                  text: 'Annuler',
                  onPressed: widget.onBack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GamingButtonPrimary(
                  text: _saving ? 'Sauvegarde...' : 'Sauvegarder',
                  onPressed: (_saving || !_isHost) ? null : _saveSettings,
                ),
              ),
            ] else ...[
              GamingButtonSecondary(text: 'Annuler', onPressed: widget.onBack),
              const SizedBox(width: 12),
              GamingButtonPrimary(
                text: _saving ? 'Sauvegarde...' : 'Sauvegarder',
                onPressed: (_saving || !_isHost) ? null : _saveSettings,
              ),
            ],
          ],
        );
      },
    );
  }
}
