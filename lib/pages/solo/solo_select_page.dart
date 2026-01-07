import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/navigation_header.dart';
import '../../navigation/app_router.dart';

import '../../api/api_client.dart' as api;
import '../../api/theme_api_service.dart';
import '../../api/difficulty_api_service.dart';
import '../../stores/auth_store.dart';

typedef ThemesFetcher = Future<api.ApiResponse<List<dynamic>>> Function({
  Map<String, String>? headers,
});

typedef DifficultiesFetcher = Future<api.ApiResponse<List<dynamic>>> Function({
  Map<String, String>? headers,
});

class _DifficultyItem {
  final int id;
  final String label;
  const _DifficultyItem({required this.id, required this.label});
}

class SoloSelectPage extends StatefulWidget {
  final ThemesFetcher? fetchThemes;
  final DifficultiesFetcher? fetchDifficulties;

  final ThemeApi? themeApiOverride;
  final DifficultyApi? difficultyApiOverride;

  const SoloSelectPage({
    super.key,
    this.fetchThemes,
    this.fetchDifficulties,
    this.themeApiOverride,
    this.difficultyApiOverride,
  });

  @override
  State<SoloSelectPage> createState() => _SoloSelectPageState();
}

class _SoloSelectPageState extends State<SoloSelectPage> {
  // Sélections utilisateur
  final Set<String> _selectedCategories = {};
  int _questionCount = 10;

  // Thèmes
  List<QuizCategory> _categories = [];
  bool _loadingThemes = false;
  String? _loadError;
  bool _unauthorized = false;

  // Difficultés
  List<_DifficultyItem> _difficulties = [];
  bool _loadingDifficulties = false;
  String? _difficultyError;
  bool _difficultyUnauthorized = false;
  int? _selectedDifficultyId; // sélection unique

  // Signature d'état d'auth
  String? _lastAuthSignature;

  ThemeApi get _themeApi => widget.themeApiOverride ?? themeApi;
  DifficultyApi get _difficultyApi => widget.difficultyApiOverride ?? difficultyApi;

  @override
  void initState() {
    super.initState();
  }

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

      _fetchThemes(headers: headers);
      _fetchDifficulties(headers: headers);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // THEMES
  // ---------------------------------------------------------------------------

  Future<void> _fetchThemes({Map<String, String>? headers}) async {
    setState(() {
      _loadingThemes = true;
      _loadError = null;
      _unauthorized = false;
    });

    try {
      final res = await _themesFetcher(headers: headers);
      if (!mounted) return;

      if (!res.ok) {
        setState(() {
          _loadingThemes = false;
          _unauthorized = res.statusCode == 401;
          _loadError = res.message ??
              (_unauthorized
                  ? 'Session expirée ou non authentifié.'
                  : 'Impossible de charger les thèmes.');
        });
        return;
      }

      final items = res.data ?? const <dynamic>[];

      final mapped = items.map((t) {
        final key = _mString(t, 'key');
        final id = _mInt(t, 'id');
        final name = _mString(t, 'name');
        final icon = _mString(t, 'icon');

        return QuizCategory(
          id: (key.isNotEmpty ? key : (id?.toString() ?? 'theme_${t.hashCode}'))
              .toLowerCase(),
          name: name,
          icon: _iconForTheme(icon: icon, name: name),
        );
      }).toList();

      mapped.sort((a, b) {
        int p(String n) =>
            n.toLowerCase().contains('général') || n.toLowerCase().contains('general') ? 0 : 1;
        final pa = p(a.name), pb = p(b.name);
        return pa != pb ? (pa - pb) : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      setState(() {
        _categories = mapped;
        _loadingThemes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingThemes = false;
        _loadError = 'Erreur réseau: $e';
      });
    }
  }

  IconData _iconForTheme({String? icon, required String name}) {
    final code = (icon ?? '').toLowerCase().trim();

    // Mapping direct basé sur Theme_THM.Icon
    switch (code) {
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
    final n = name.toLowerCase();
    if (n.contains('général') || n.contains('general')) {
      return FontAwesomeIcons.wandMagicSparkles;
    }
    if (n.contains('histoire') || n.contains('history')) {
      return FontAwesomeIcons.buildingColumns;
    }
    if (n.contains('science')) return FontAwesomeIcons.flask;
    if (n.contains('sport')) return FontAwesomeIcons.medal;
    if (n.contains('musique') || n.contains('music')) {
      return FontAwesomeIcons.music;
    }
    if (n.contains('cinéma') || n.contains('cinema') || n.contains('film')) {
      return FontAwesomeIcons.film;
    }
    if (n.contains('art')) return FontAwesomeIcons.palette;
    if (n.contains('géographie') ||
        n.contains('geo') ||
        n.contains('geographie')) {
      return FontAwesomeIcons.globe;
    }
    if (n.contains('tech') ||
        n.contains('informatique') ||
        n.contains('technologie')) {
      return FontAwesomeIcons.laptopCode;
    }
    if (n.contains('jeu') ||
        n.contains('gaming') ||
        n.contains('vidéo') ||
        n.contains('video')) {
      return FontAwesomeIcons.gamepad;
    }

    return FontAwesomeIcons.shapes;
  }

  // ---------------------------------------------------------------------------
  // DIFFICULTÉS
  // ---------------------------------------------------------------------------

  Future<void> _fetchDifficulties({Map<String, String>? headers}) async {
    setState(() {
      _loadingDifficulties = true;
      _difficultyError = null;
      _difficultyUnauthorized = false;
    });

    final res = await _difficultiesFetcher(headers: headers);
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

    final items = res.data ?? const <dynamic>[];

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
        final def = _difficulties.firstWhere(
          (d) => d.id == 2,
          orElse: () => _difficulties.first,
        );
        _selectedDifficultyId = def.id;
      }
    });
  }

  String _selectedDifficultyLabel() {
    if (_selectedDifficultyId == null) return '—';
    final match = _difficulties.where((d) => d.id == _selectedDifficultyId).toList(growable: false);
    return match.isNotEmpty ? match.first.label : '—';
  }

  // ---------------------------------------------------------------------------
  // LOGIQUE
  // ---------------------------------------------------------------------------

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  void _startQuiz() {
    if (_selectedCategories.isEmpty) {
      ToastManager.show(
        context: context,
        message: 'Veuillez sélectionner au moins une catégorie',
        backgroundColor: TuuurTheme.brandOrange.withOpacity(0.9),
      );
      return;
    }

    if (_selectedDifficultyId == null) {
      ToastManager.show(
        context: context,
        message: 'Veuillez choisir une difficulté',
        backgroundColor: TuuurTheme.brandOrange.withOpacity(0.9),
      );
      return;
    }

    GamingModal.show(
      context: context,
      title: 'Démarrer le quiz',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfirmationRow(
            FontAwesomeIcons.bullseye,
            'Catégories:',
            _selectedCategories
                .map(
                  (id) => _categories.firstWhere(
                    (c) => c.id == id,
                    orElse: () => QuizCategory(
                      id: id,
                      name: id,
                      icon: FontAwesomeIcons.shapes,
                    ),
                  ).name,
                )
                .join(', '),
          ),
          const SizedBox(height: 12),
          _buildConfirmationRow(
            FontAwesomeIcons.listOl,
            'Questions:',
            '$_questionCount',
          ),
          const SizedBox(height: 12),
          _buildConfirmationRow(
            FontAwesomeIcons.gaugeHigh,
            'Difficulté:',
            _selectedDifficultyLabel(),
          ),
        ],
      ),
      onConfirm: () {
        Navigator.of(context).pop();

        // La partie solo est réellement créée dans SoloQuizPage via soloApi.
        context.goSoloQuiz(
          categories: _selectedCategories.toList(),
          questions: _questionCount,
          difficulty: _selectedDifficultyId!,
        );
      },
    );
  }

  Widget _buildConfirmationRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(icon, color: TuuurTheme.brandPurple, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: TuuurTheme.brandLightGray,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: TuuurTheme.brandGray),
          ),
        ),
      ],
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
            _loadError ?? 'Erreur inconnue',
            style: const TextStyle(color: TuuurTheme.brandOrange),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GamingButtonSecondary(
                text: '↻ Réessayer',
                onPressed: () {
                  final store = MyAuthStore.of(context);
                  _fetchThemes(
                    headers: store.isAuthenticated ? store.authHeaders : null,
                  );
                },
              ),
              if (_unauthorized)
                GamingButtonPrimary(
                  text: 'Se connecter',
                  onPressed: () => context.goLogin(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goBack();
      },
      child: Scaffold(
        appBar: const NavigationHeader(
          showBack: true,
        ),
        body: SingleChildScrollView(
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
                          CircularProgressIndicator(
                            color: TuuurTheme.brandPurple,
                          ),
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
              else if (_loadError != null)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;

        if (narrow) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.bullseye,
                    color: TuuurTheme.brandPurple,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mode Solo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: TuuurTheme.brandLightGray,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
          );
        }

        return const Row(
          children: [
            FaIcon(
              FontAwesomeIcons.bullseye,
              color: TuuurTheme.brandPurple,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mode Solo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
        );
      },
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
                  selected: _selectedCategories.contains(category.id),
                  onTap: () => _toggleCategory(category.id),
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
          const Row(
            children: [
              Expanded(
                child: Text(
                  '⚙️ Paramètres',
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
          const SizedBox(height: 16),
          _buildSettingItem(
            'Nombre de questions',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: Slider(
                    value: _questionCount.toDouble(),
                    min: 5,
                    max: 100,
                    // de 5 en 5
                    divisions: (100 - 5) ~/ 5, // 19 divisions
                    label: '$_questionCount',
                    onChanged: (value) {
                      setState(() {
                        _questionCount = value
                            .round(); // valeur entière, step 5 grâce à divisions
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          Text(
            'Chargement des difficultés…',
            style: TextStyle(color: TuuurTheme.brandGray),
          ),
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
          Text(
            _difficultyError!,
            style: const TextStyle(
              color: TuuurTheme.brandOrange,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GamingButtonSecondary(
                text: '↻ Réessayer',
                onPressed: () {
                  final store = MyAuthStore.of(context);
                  _fetchDifficulties(
                    headers: store.isAuthenticated ? store.authHeaders : null,
                  );
                },
              ),
              if (_difficultyUnauthorized)
                GamingButtonPrimary(
                  text: 'Se connecter',
                  onPressed: () => context.goLogin(),
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
          spacing: 8,
          runSpacing: 8,
          children: _difficulties.map((d) {
            final selected = d.id == _selectedDifficultyId;
            return CategoryButton(
              text: d.label,
              selected: selected,
              onTap: () {
                setState(() {
                  _selectedDifficultyId = d.id;
                });
              },
            );
          }).toList(),
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
        final primaryText = veryNarrow ? 'Jouer' : 'Commencer l\'aventure';

        return Align(
          alignment: narrow ? Alignment.center : Alignment.centerRight,
          child: SizedBox(
            width: narrow ? double.infinity : null,
            child: GamingButtonPrimary(
              text: primaryText,
              icon: FontAwesomeIcons.rocket,
              onPressed: _startQuiz,
            ),
          ),
        );
      },
    );
  }

  ThemesFetcher get _themesFetcher =>
      widget.fetchThemes ??
      ({headers}) async {
        final res = await _themeApi.getThemes(headers: headers);
        if (!res.ok) {
          return api.ApiResponse.err(
            message: res.message,
            statusCode: res.statusCode,
            raw: res.raw,
          );
        }
        return api.ApiResponse.ok(
          List<dynamic>.from(res.data ?? const []),
          statusCode: res.statusCode,
        );
      };

  DifficultiesFetcher get _difficultiesFetcher =>
      widget.fetchDifficulties ??
      ({headers}) async {
        final res = await _difficultyApi.getDifficulties(headers: headers);
        if (!res.ok) {
          return api.ApiResponse.err(
            message: res.message,
            statusCode: res.statusCode,
            raw: res.raw,
          );
        }
        return api.ApiResponse.ok(
          List<dynamic>.from(res.data ?? const []),
          statusCode: res.statusCode,
        );
      };

  String _mString(dynamic obj, String key) {
    if (obj is Map) return obj[key]?.toString() ?? '';
    try {
      final o = obj as dynamic;
      switch (key) {
        case 'key':
          return o.key?.toString() ?? '';
        case 'name':
          return o.name?.toString() ?? '';
        case 'icon':
          return o.icon?.toString() ?? '';
        case 'label':
          return o.label?.toString() ?? '';
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

class QuizCategory {
  final String id;
  final String name;
  final IconData icon;

  QuizCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}
