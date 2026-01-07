// group_create_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/group_api_service.dart';
import '../../api/theme_api_service.dart';
import '../../api/difficulty_api_service.dart';
import '../../stores/auth_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/navigation_header.dart';

class QuizCategory {
  final int id;
  final String name;
  final IconData icon;

  const QuizCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class _DifficultyItem {
  final int id;
  final String label;
  const _DifficultyItem({required this.id, required this.label});
}

class GroupCreatePage extends StatefulWidget {
  final VoidCallback onBack;

  final void Function({
    required String partyId,
    required String code,
    required List<String> categories,
    required List<int> themeIds,
    required List<int> difficultyIds,
    required int questions,
    required bool shuffle,
    String? specifics,
  }) onCreated;

  /// Injection (tests)
  final GroupApi? groupApiOverride;
  final ThemeApi? themeApiOverride;
  final DifficultyApi? difficultyApiOverride;

  const GroupCreatePage({
    super.key,
    required this.onBack,
    required this.onCreated,
    this.groupApiOverride,
    this.themeApiOverride,
    this.difficultyApiOverride,
  });

  @override
  State<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  GroupApi get _groupApi => widget.groupApiOverride ?? groupApi;
  ThemeApi get _themeApi => widget.themeApiOverride ?? themeApi;
  DifficultyApi get _difficultyApi => widget.difficultyApiOverride ?? difficultyApi;

  // Sélections utilisateur
  final Set<int> _selectedThemeIds = <int>{};
  int _questionCount = 10;

  // Thèmes
  List<QuizCategory> _categories = const [];
  bool _loadingThemes = false;
  String? _themesError;
  bool _themesUnauthorized = false;

  // Difficultés
  List<_DifficultyItem> _difficulties = const [];
  bool _loadingDifficulties = false;
  String? _difficultyError;
  bool _difficultyUnauthorized = false;
  int? _selectedDifficultyId;

  // Submission
  bool _submitting = false;

  // Pour éviter de re-fetch en boucle sur didChangeDependencies
  String? _lastAuthSignature;

  // Champs conservés (mais retirés de l’UI) pour compat signature onCreated
  bool shuffle = true;
  String specifics = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final store = MyAuthStore.of(context);
    final sig = store.isAuthenticated
        ? (store.authHeaders['Authorization'] ?? 'auth')
        : 'anon';

    if (sig != _lastAuthSignature) {
      _lastAuthSignature = sig;
      final headers = store.isAuthenticated ? store.authHeaders : null;

      _loadThemes(headers: headers);
      _loadDifficulties(headers: headers);
    }
  }

  // --------------------------
  // Helpers
  // --------------------------

  void _snack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? TuuurTheme.brandOrange,
      ),
    );
  }

  IconData _iconFromTheme(ThemeDto t) {
    final raw = (t.icon ?? '').toLowerCase().trim();

    if (raw.contains('music')) return FontAwesomeIcons.music;
    if (raw.contains('film') || raw.contains('cinema')) return FontAwesomeIcons.film;
    if (raw.contains('sport') || raw.contains('football')) return FontAwesomeIcons.football;
    if (raw.contains('history') || raw.contains('landmark')) return FontAwesomeIcons.landmark;
    if (raw.contains('science') || raw.contains('flask')) return FontAwesomeIcons.flask;
    if (raw.contains('art') || raw.contains('palette')) return FontAwesomeIcons.palette;
    if (raw.contains('geo') || raw.contains('earth')) return FontAwesomeIcons.earthAmericas;
    if (raw.contains('gamepad') || raw.contains('general') || raw.contains('globe')) {
      return FontAwesomeIcons.globe;
    }

    return FontAwesomeIcons.tags;
  }

  List<String> _selectedCategoryNames() {
    final map = {for (final c in _categories) c.id: c.name};
    return _selectedThemeIds.map((id) => map[id] ?? 'Theme #$id').toList();
  }

  // --------------------------
  // Fetch THEMES
  // --------------------------

  Future<void> _loadThemes({Map<String, String>? headers}) async {
    setState(() {
      _loadingThemes = true;
      _themesError = null;
      _themesUnauthorized = false;
    });

    try {
      final res = await _themeApi.getThemes(headers: headers);
      if (!mounted) return;

      if (!res.ok) {
        setState(() {
          _loadingThemes = false;
          _themesUnauthorized = res.statusCode == 401;
          _themesError = res.message ??
              (_themesUnauthorized
                  ? 'Session expirée ou non authentifié.'
                  : 'Impossible de charger les thèmes.');
        });
        return;
      }

      final items = res.data ?? const <ThemeDto>[];

      final built = <QuizCategory>[];
      for (final t in items) {
        final id = t.id;
        if (id == null) continue;
        built.add(
          QuizCategory(
            id: id,
            name: t.name,
            icon: _iconFromTheme(t),
          ),
        );
      }

      built.sort((a, b) {
        int p(String n) =>
            n.toLowerCase().contains('général') || n.toLowerCase().contains('general') ? 0 : 1;
        final pa = p(a.name), pb = p(b.name);
        return pa != pb ? (pa - pb) : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      setState(() {
        _categories = built;
        _loadingThemes = false;

        // sélection par défaut (comme avant) : le premier thème s’il existe
        _selectedThemeIds.clear();
        if (built.isNotEmpty) {
          _selectedThemeIds.add(built.first.id);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingThemes = false;
        _themesError = 'Erreur réseau: $e';
      });
    }
  }

  // --------------------------
  // Fetch DIFFICULTIES
  // --------------------------

  Future<void> _loadDifficulties({Map<String, String>? headers}) async {
    setState(() {
      _loadingDifficulties = true;
      _difficultyError = null;
      _difficultyUnauthorized = false;
    });

    try {
      final res = await _difficultyApi.getDifficulties(headers: headers);
      if (!mounted) return;

      if (!res.ok) {
        setState(() {
          _loadingDifficulties = false;
          _difficultyUnauthorized = res.statusCode == 401;
          _difficultyError = res.message ??
              (_difficultyUnauthorized
                  ? 'Session expirée ou non authentifié.'
                  : 'Impossible de charger les difficultés.');
        });
        return;
      }

      final items = (res.data ?? const <dynamic>[]) as List<dynamic>;

      final mapped = <_DifficultyItem>[];
      for (final d in items) {
        final id = _mInt(d, 'id');
        final label = _mString(d, 'label');
        if (id != null && label.isNotEmpty) {
          mapped.add(_DifficultyItem(id: id, label: label));
        }
      }

      setState(() {
        _difficulties = mapped;
        _loadingDifficulties = false;

        if (_selectedDifficultyId == null && _difficulties.isNotEmpty) {
          // default: 2 si existe, sinon premier
          final def = _difficulties.firstWhere(
            (d) => d.id == 2,
            orElse: () => _difficulties.first,
          );
          _selectedDifficultyId = def.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDifficulties = false;
        _difficultyError = 'Erreur réseau: $e';
      });
    }
  }

  String _selectedDifficultyLabel() {
    if (_selectedDifficultyId == null) return '—';
    final match = _difficulties.where((d) => d.id == _selectedDifficultyId).toList(growable: false);
    return match.isNotEmpty ? match.first.label : '—';
  }

  // --------------------------
  // UI actions
  // --------------------------

  void _toggleTheme(int themeId) {
    if (_submitting) return;

    setState(() {
      if (_selectedThemeIds.contains(themeId)) {
        // on garde au moins 1 sélection
        if (_selectedThemeIds.length > 1) _selectedThemeIds.remove(themeId);
      } else {
        _selectedThemeIds.add(themeId);
      }
    });
  }

  // --------------------------
  // Create flow
  // --------------------------

  Future<void> createRoom() async {
    if (_submitting) return;

    if (_loadingThemes || _loadingDifficulties) {
      _snack('Chargement en cours…');
      return;
    }
    if (_categories.isEmpty || _selectedThemeIds.isEmpty) {
      _snack('Veuillez sélectionner au moins une catégorie.');
      return;
    }
    if (_selectedDifficultyId == null) {
      _snack('Veuillez choisir une difficulté.');
      return;
    }

    setState(() {
      _submitting = true;
      // on ne reset pas les erreurs UI ici, elles sont gérées par leurs sections
    });

    try {
      final store = MyAuthStore.of(context);
      final headers = store.isAuthenticated ? store.authHeaders : null;

      final themeIds = _selectedThemeIds.toList();
      final difficultyIds = <int>[_selectedDifficultyId!];

      // 1) create lobby
      final createRes = await _groupApi.createGroup(headers: headers);
      if (!mounted) return;

      if (!createRes.ok) {
        setState(() => _submitting = false);
        _snack(
          createRes.message ?? 'Impossible de créer la partie.',
          color: TuuurTheme.brandOrange,
        );
        return;
      }

      final party = createRes.data!;
      final partyId = party.partyId;
      final lobbyCode = party.code;

      setState(() => _submitting = false);

      widget.onCreated(
        partyId: partyId,
        code: lobbyCode,
        categories: _selectedCategoryNames(),
        themeIds: themeIds,
        difficultyIds: difficultyIds,
        questions: _questionCount,
        shuffle: shuffle,
        specifics: specifics.isNotEmpty ? specifics : null,
      );

    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack('Erreur: $e', color: TuuurTheme.brandOrange);
    }
  }

  // --------------------------
  // BUILD
  // --------------------------

  @override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // on gère le retour via le bouton "Retour"
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      widget.onBack();
    },
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          if (_loadingThemes)
            const GamingCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: TuuurTheme.brandPurple),
                      SizedBox(height: 12),
                      Text(
                        'Chargement des thèmes…',
                        style: TextStyle(color: TuuurTheme.brandGray),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_themesError != null)
            _buildThemesErrorCard()
          else
            Column(
              children: [
                _buildCategoriesSection(),
                const SizedBox(height: 24),
                _buildSettingsSection(),
              ],
            ),

          const SizedBox(height: 32),

          _buildFooter(),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GamingButtonGhost(
              text: 'Retour',
              onPressed: _submitting ? null : widget.onBack,
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;

        final title = const Text(
          'Créer une partie',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: TuuurTheme.brandLightGray,
          ),
        );

        final status = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: TuuurStyles.pill,
          child: Text(
            _submitting
                ? 'Création…'
                : (_loadingThemes || _loadingDifficulties)
                    ? 'Chargement…'
                    : 'Paramètres → API',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: TuuurTheme.brandGray, fontSize: 12),
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.users, color: TuuurTheme.brandPurple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: title),
                ],
              ),
              const SizedBox(height: 12),
              status,
            ],
          ).animate().fadeIn().slideX(begin: -0.2);
        }

        return Row(
          children: [
            const FaIcon(FontAwesomeIcons.users, color: TuuurTheme.brandPurple, size: 28),
            const SizedBox(width: 12),
            Expanded(child: title),
            const SizedBox(width: 12),
            status,
          ],
        ).animate().fadeIn().slideX(begin: -0.2);
      },
    );
  }

  Widget _buildThemesErrorCard() {
    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thèmes',
            style: TextStyle(
              color: TuuurTheme.brandLightGray,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _themesError ?? 'Erreur inconnue',
            style: const TextStyle(color: TuuurTheme.brandOrange),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GamingButtonSecondary(
                text: '↻ Réessayer',
                onPressed: _submitting
                    ? null
                    : () {
                        final store = MyAuthStore.of(context);
                        _loadThemes(headers: store.isAuthenticated ? store.authHeaders : null);
                      },
              ),
              if (_themesUnauthorized)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: TuuurStyles.pill,
                  child: const Text(
                    '401',
                    style: TextStyle(color: TuuurTheme.brandOrange, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
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
                  'Catégories',
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
          const Text(
            'Choisissez une ou plusieurs catégories pour votre aventure.',
            style: TextStyle(color: TuuurTheme.brandGray, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (_categories.isEmpty)
            const Text(
              'Aucun thème disponible.',
              style: TextStyle(color: TuuurTheme.brandGray),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                return CategoryButton(
                  text: category.name,
                  icon: category.icon,
                   selected: _selectedThemeIds.contains(category.id),
                  onTap: () => setState(() => _toggleTheme(category.id)),
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

  Widget _buildSettingsSection() {
    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Paramètres',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ),
          const SizedBox(height: 16),

          // QUESTIONS
          _buildSettingItem(
            'Nombre de questions',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                    activeTrackColor: TuuurTheme.brandPurple,
                    thumbColor: TuuurTheme.brandPurple,
                  ),
                  child: Slider(
                    value: _questionCount.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: (20 - 5) ~/ 5, // step de 5
                    label: '$_questionCount',
                    onChanged: _submitting
                        ? null
                        : (value) {
                            setState(() {
                              // valeur entière, step 5 via divisions
                              _questionCount = value.round();
                            });
                          },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // DIFFICULTY
          _buildDifficultySection(),
        ],
      ),
    );
  }

  Widget _buildDifficultySection() {
    if (_loadingDifficulties) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Difficulté',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text('Chargement des difficultés…', style: TextStyle(color: TuuurTheme.brandGray)),
        ],
      );
    }

    if (_difficultyError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Difficulté',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(_difficultyError!, style: const TextStyle(color: TuuurTheme.brandOrange, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GamingButtonSecondary(
                text: '↻ Réessayer',
                onPressed: _submitting
                    ? null
                    : () {
                        final store = MyAuthStore.of(context);
                        _loadDifficulties(headers: store.isAuthenticated ? store.authHeaders : null);
                      },
              ),
              if (_difficultyUnauthorized)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: TuuurStyles.pill,
                  child: const Text(
                    '401',
                    style: TextStyle(color: TuuurTheme.brandOrange, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    if (_difficulties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difficulté',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: TuuurTheme.brandLightGray,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _difficulties.map((d) {
            final selected = d.id == _selectedDifficultyId;
            return CategoryButton(
              text: d.label,
              selected: selected,
              onTap: () => setState(() => _selectedDifficultyId = d.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélection: ${_selectedDifficultyLabel()}',
          style: const TextStyle(color: TuuurTheme.brandGray, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String label, Widget trailing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TuuurTheme.brandLightGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        trailing,
      ],
    );
  }

  Widget _buildFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final veryNarrow = constraints.maxWidth < 320;
        final primaryText = veryNarrow ? 'Créer' : 'Créer la partie';

        return Align(
          alignment: narrow ? Alignment.center : Alignment.centerRight,
          child: SizedBox(
            width: narrow ? double.infinity : null,
            child: GamingButtonPrimary(
              text: _submitting ? 'Création…' : primaryText,
              icon: FontAwesomeIcons.rocket,
              onPressed: _submitting ? null : createRoom,
            ),
          ),
        );
      },
    );
  }

  // Helpers parsing (compat si API renvoie Map ou DTO)
  String _mString(dynamic obj, String key) {
    if (obj is Map) return obj[key]?.toString() ?? '';
    try {
      final o = obj as dynamic;
      switch (key) {
        case 'label':
          return o.label?.toString() ?? '';
        case 'name':
          return o.name?.toString() ?? '';
        case 'icon':
          return o.icon?.toString() ?? '';
      }
    } catch (_) {}
    return '';
  }

  int? _mInt(dynamic obj, String key) {
    dynamic v;
    if (obj is Map) {
      v = obj[key];
    } else {
      try {
        final o = obj as dynamic;
        if (key == 'id') v = o.id;
      } catch (_) {}
    }
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
