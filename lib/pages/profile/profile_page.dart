import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../../stores/auth_store.dart';
import '../../navigation/app_router.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';
import '../../api/api_config.dart';
import '../../api/api_module.dart';
import '../../api/auth/auth_api_service.dart' as api_auth;
import '../../api/other/history_api_service.dart' as api_hist;
import '../../api/other/history_models.dart' as models_hist;

class ProfilePage extends StatefulWidget {
  final api_auth.AuthApi? authApi;
  final api_hist.HistoryApi? historyApi;

  const ProfilePage({super.key, this.authApi, this.historyApi});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  api_auth.AuthApi get _authApi => widget.authApi ?? ApiModule.instance.authApi;
  api_hist.HistoryApi get _historyApi =>
      widget.historyApi ?? ApiModule.instance.historyApi;

  bool _loading = false;
  String? _nickName;
  String? _email;
  String? _avatar; // valeur renvoyée par l’API (url, base64, data-uri…)
  int? _userId;
  bool _serverError = false;
  String? _serverErrorMessage;

  Uint8List?
  _avatarBytes; // bytes à afficher (aperçu local OU décodage base64 serveur)
  final _picker = ImagePicker();

  bool _fetched = false;
  bool _wasAuthenticated = false;

  // --- Édition inline du pseudo ---
  bool _isEditingNickname = false;
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSavingNickname = false;

  // --- Historique ---
  bool _historyLoading = false;
  String? _historyError;
  List<models_hist.HistoryMatchDto> _historyMatches = [];
  int _historyTotalMatches = 0;
  int? _historyAvgPercent;
  String _historySelectedFilter = 'all';

  static const int _historyPageSize = 10;
  static const double _difficultyPillWidth = 78;
  static const double _difficultyPillHeight = 22;

  static const double _moreThemesPillWidth = 44;
  static const double _moreThemesPillHeight = 22;
  int _historyCurrentPage = 1;

  String get _fallbackAvatarUrl {
    final seed = Uri.encodeComponent(_nickName ?? 'player');
    return 'https://api.dicebear.com/9.x/adventurer-neutral/svg?seed=$seed';
  }

  List<models_hist.HistoryMatchDto> get _visibleHistoryMatches {
    var list = List<models_hist.HistoryMatchDto>.from(_historyMatches);

    if (_historySelectedFilter == 'solo') {
      list = list
          .where((m) => (m.partyType?.label ?? '').toLowerCase() == 'solo')
          .toList();
    } else if (_historySelectedFilter == 'group') {
      list = list
          .where(
            (m) =>
                (m.partyType?.label ?? '').toLowerCase().contains('group') ||
                (m.partyType?.label ?? '').toLowerCase().contains('groupe'),
          )
          .toList();
    }

    // Plus récente -> plus ancienne
    list.sort((a, b) {
      final adt = a.dt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bdt = b.dt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bdt.compareTo(adt);
    });

    return list;
  }

  int get _historyTotalPages {
    final filtered = _visibleHistoryMatches;
    if (filtered.isEmpty) return 1;
    return (filtered.length / _historyPageSize).ceil();
  }

  List<models_hist.HistoryMatchDto> get _paginatedHistoryMatches {
    final filtered = _visibleHistoryMatches;
    final start = (_historyCurrentPage - 1) * _historyPageSize;
    final end = start + _historyPageSize;

    if (start >= filtered.length) return [];
    if (end >= filtered.length) return filtered.sublist(start);
    return filtered.sublist(start, end);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final store = MyAuthStore.of(context);
    final isAuthenticated = store.isAuthenticated;

    // Si l'utilisateur vient de se connecter, on recharge les données
    if (isAuthenticated && !_wasAuthenticated) {
      _fetched = false;
    }

    _wasAuthenticated = isAuthenticated;
    _fetchMeOnce();
  }

  @override
  Widget build(BuildContext context) {
    final store = MyAuthStore.of(context);
    final isAuthenticated = store.isAuthenticated;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goBack();
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: const NavigationHeader(showBack: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.user,
                    color: TuuurTheme.brandLightGray,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Profil',
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
              const SizedBox(height: 24),
              if (!isAuthenticated || _serverError) ...[
                _serverError
                    ? _serverErrorCard(_serverErrorMessage)
                    : _notConnectedCard(),
              ] else ...[
                if (_loading && _nickName == null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: TuuurStyles.gamingCard,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: TuuurTheme.brandPurple,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      _profileCard(),
                      const SizedBox(height: 24),
                      _historySection(),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // Async : profil / historique / actions
  // -----------------------------

  Future<void> _fetchMeOnce() async {
    if (_fetched) return;
    _fetched = true;

    final store = MyAuthStore.of(context);
    if (!store.isAuthenticated) return;

    setState(() {
      _loading = true;
      _serverError = false;
      _serverErrorMessage = null;
    });
    final res = await _authApi.me();

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok && res.data != null) {
      final u = res.data!;
      final val = u.avatar;
      final decoded = _decodeBase64Image(val);

      setState(() {
        _nickName = u.nickName;
        _avatar = val;
        _avatarBytes = decoded ?? _avatarBytes;
      });

      await _fetchHistory();
    } else {
      if (res.statusCode == 401) {
        await store.signOut();
        if (!mounted) return;
        _showToast(
          'Session expirée. Veuillez vous reconnecter.',
          color: TuuurTheme.brandOrange,
        );
      } else {
        setState(() {
          _serverError = true;
          _serverErrorMessage =
              res.message ?? 'Impossible de charger le profil.';
          _fetched = false; // permet retry
        });
      }
    }
  }

  Future<void> _fetchHistory() async {
    final store = MyAuthStore.of(context);
    if (!store.isAuthenticated) return;

    setState(() {
      _historyLoading = true;
      _historyError = null;
    });

    // Charger toutes les parties (on met un size très grand)
    final res = await _historyApi.getHistory(page: 1, size: 1000);

    if (!mounted) return;

    if (!res.ok || res.data == null) {
      if (res.statusCode == 401) {
        await store.signOut();
        if (!mounted) return;
        _showToast(
          'Session expirée. Veuillez vous reconnecter.',
          color: TuuurTheme.brandOrange,
        );
      }

      setState(() {
        _historyLoading = false;
        _historyError = res.message ?? 'Impossible de charger l’historique.';
        _historyMatches = [];
        _historyTotalMatches = 0;
        _historyAvgPercent = null;
        _historyCurrentPage = 1;
      });
      return;
    }

    final historyPage = res.data!;
    final matches = historyPage.items;

    final finished = matches.where((m) => m.finish).toList();
    final withPercent = finished.where((m) => m.percent != null).toList();

    int? avgPercent;
    if (withPercent.isNotEmpty) {
      var total = 0;
      for (final m in withPercent) {
        total += m.percent ?? 0;
      }
      avgPercent = (total / withPercent.length).round();
    }

    setState(() {
      _historyLoading = false;
      _historyError = null;
      _historyMatches = matches;
      _historyTotalMatches = historyPage.totalCount ?? matches.length;
      _historyCurrentPage = 1;
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      setState(() => _avatarBytes = bytes);

      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';

      if (!mounted) return;

      setState(() => _loading = true);

      final res = await _authApi.updateAvatarBase64(base64: dataUri);

      if (!mounted) return;
      setState(() => _loading = false);

      if (res.ok) {
        _showToast('Avatar mis à jour ✅', color: TuuurTheme.brandGreen);
        _fetched = false;
        await _fetchMeOnce();
      } else {
        _showToast(res.message ?? 'Échec de la mise à jour de l’avatar.');
      }
    } catch (e) {
      _showToast('Erreur avatar : $e');
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TuuurTheme.brandDarkGray,
        title: const Text(
          'Supprimer le compte',
          style: TextStyle(color: TuuurTheme.brandLightGray),
        ),
        content: const Text(
          'Cette action est irréversible. Confirmer ?',
          style: TextStyle(color: TuuurTheme.brandGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          GamingButtonSecondary(
            text: 'Supprimer',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (!mounted) return;
    final store = MyAuthStore.of(context);
    setState(() => _loading = true);

    final res = await _authApi.deleteMe();

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok) {
      await store.signOut();
      if (!mounted) return;
      _showToast('Compte supprimé.', color: TuuurTheme.brandGreen);
      context.go('/');
    } else {
      _showToast(res.message ?? 'Suppression impossible.');
    }
  }

  Future<void> _signOut() async {
    final store = MyAuthStore.of(context);
    await store.signOut();

    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: ApiConfig.googleWebClientId,
    );

    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }

    if (!mounted) return;

    // Nettoie l’état local pour éviter un vieux rendu
    setState(() {
      _nickName = null;
      _email = null;
      _avatar = null;
      _userId = null;
      _avatarBytes = null;
      _fetched = false;

      _historyLoading = false;
      _historyError = null;
      _historyMatches = [];
      _historyTotalMatches = 0;
      _historyAvgPercent = null;
      _historySelectedFilter = 'all';
      _historyCurrentPage = 1;
    });

    _showToast('Déconnecté.', color: TuuurTheme.brandGreen);
    context.go('/'); // Retour à l’accueil
  }

  void _changeHistoryPage(int page) {
    if (page < 1 || page > _historyTotalPages) return;
    setState(() {
      _historyCurrentPage = page;
    });
  }

  // -----------------------------
  // Édition du pseudo
  // -----------------------------

  void _startEditingNickname() {
    _nicknameController.text = _nickName ?? '';
    setState(() {
      _isEditingNickname = true;
    });
  }

  void _cancelEditingNickname() {
    setState(() {
      _isEditingNickname = false;
      _nicknameController.clear();
    });
  }

  Future<void> _saveNickname() async {
    final newNickname = _nicknameController.text.trim();

    if (newNickname.isEmpty) {
      _showToast('Le pseudo ne peut pas être vide.');
      return;
    }

    if (newNickname == _nickName) {
      _cancelEditingNickname();
      return;
    }

    setState(() => _isSavingNickname = true);

    try {
      final res = await _authApi.updateNickname(nickname: newNickname);

      if (!mounted) return;

      setState(() => _isSavingNickname = false);

      if (res.ok) {
        setState(() {
          _nickName = newNickname;
          _isEditingNickname = false;
        });
        _nicknameController.clear();
        _showToast('Pseudo mis à jour ✅', color: TuuurTheme.brandGreen);
      } else {
        _showToast(res.message ?? 'Échec de la mise à jour du pseudo.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingNickname = false);
      _showToast('Erreur : $e');
    }
  }

  // -----------------------------
  // Helpers / formatting
  // -----------------------------

  void _showAllThemesSheet(List<String> themes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TuuurTheme.brandDarkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.tags,
                    size: 16,
                    color: TuuurTheme.brandPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thèmes (${themes.length})',
                    style: const TextStyle(
                      color: TuuurTheme.brandLightGray,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: themes
                    .map(
                      (t) => _pill(
                        label: t,
                        bgColor: TuuurTheme.brandPurple.withOpacity(0.1),
                        borderColor: TuuurTheme.brandPurple.withOpacity(0.3),
                        textColor: TuuurTheme.brandPurple,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Uint8List? _decodeBase64Image(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      var raw = value.trim();
      final comma = raw.indexOf(',');
      if (raw.startsWith('data:image') && comma != -1) {
        raw = raw.substring(comma + 1);
      }
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  String _formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return "À l'instant";
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours} h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} j';
    } else {
      final d = dt.toLocal();
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year.toString();
      return '$day/$month/$year';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final rem = seconds % 60;
    if (rem > 0) return '${minutes}m ${rem}s';
    return '${minutes}m';
  }

  Color _colorForPercent(int? percent) {
    if (percent == null) return TuuurTheme.brandGray;
    if (percent >= 80) return TuuurTheme.brandGreen;
    if (percent >= 60) return TuuurTheme.brandCyan;
    if (percent >= 40) return TuuurTheme.brandOrange;
    return Colors.redAccent;
  }

  Color _difficultyBaseColor(int id) {
    return TuuurTheme.colorForDifficulty(id: id);
  }

  void _showToast(String message, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // -----------------------------
  // UI helpers
  // -----------------------------

  Widget _serverErrorCard(String? message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: TuuurStyles.gamingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Impossible de charger le profil',
            style: TextStyle(
              color: TuuurTheme.brandLightGray,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message ?? 'Erreur réseau / serveur.',
            style: const TextStyle(color: TuuurTheme.brandOrange),
          ),
          const SizedBox(height: 20),

          // 1) Retry
          GamingButtonPrimary(
            text: 'Réessayer',
            icon: FontAwesomeIcons.rotateRight,
            onPressed: () async {
              setState(() {
                _serverError = false;
                _serverErrorMessage = null;
                _fetched = false;
              });
              await _fetchMeOnce();
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _statsPill(String text, {IconData? icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    IconData? icon,
    double? width,
    double? height,
  }) {
    final bounded =
        width != null; // si width est fourni, on centre et on gère ellipsis

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: bounded
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: textColor),
              const SizedBox(width: 4),
            ],
            if (bounded)
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              )
            else
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyPill(int id, {double? width}) {
    final label = TuuurTheme.labelForDifficulty(id);
    final color = _difficultyBaseColor(id);

    return _pill(
      label: label,
      bgColor: color.withOpacity(0.2),
      borderColor: color.withOpacity(0.4),
      textColor: color,
      width: width, // <= largeur dynamique
      height: _difficultyPillHeight, // hauteur fixe
    );
  }

  Widget _buildDifficultiesGrid(List<int> diffIds) {
    if (diffIds.isEmpty) return const SizedBox.shrink();

    const double hSpacing = 8;
    const double vSpacing = 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Forcer 2 colonnes quel que soit l'écran
        final itemWidth = (constraints.maxWidth - hSpacing) / 2;

        return Wrap(
          spacing: hSpacing,
          runSpacing: vSpacing, // espace vertical entre lignes
          children: diffIds
              .map(
                (id) => SizedBox(
                  width: itemWidth,
                  height: _difficultyPillHeight,
                  child: _buildDifficultyPill(id, width: itemWidth),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // -----------------------------
  // UI sections
  // -----------------------------

  Widget _notConnectedCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: TuuurStyles.gamingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vous n’êtes pas connecté',
            style: TextStyle(
              color: TuuurTheme.brandLightGray,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: GamingButtonPrimary(
                  text: 'Se connecter',
                  icon: FontAwesomeIcons.rightToBracket,
                  onPressed: () =>
                      context.push('/login', extra: {'returnTo': '/profile'}),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GamingButtonSecondary(
                  text: 'Créer un compte',
                  icon: FontAwesomeIcons.userPlus,
                  onPressed: () => context.push(
                    '/register',
                    extra: {'returnTo': '/profile'},
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historySection() {
    final allFilteredMatches = _visibleHistoryMatches;
    final matches = _paginatedHistoryMatches;
    final visibleCount = allFilteredMatches.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: TuuurStyles.gamingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.clockRotateLeft,
                      color: TuuurTheme.brandPurple,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Historique des parties',
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
              ),
              const SizedBox(width: 8),
              _statsPill(
                '$visibleCount Partie${visibleCount > 1 ? 's' : ''}',
                icon: FontAwesomeIcons.gamepad,
                color: TuuurTheme.brandPurple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHistoryFilters(),
          const SizedBox(height: 16),
          if (_historyLoading) ...[
            const Center(
              child: CircularProgressIndicator(color: TuuurTheme.brandPurple),
            ),
          ] else if (_historyError != null) ...[
            Text(
              _historyError!,
              style: const TextStyle(color: TuuurTheme.brandOrange),
            ),
          ] else ...[
            _buildHistoryList(matches),
            if (_historyTotalPages > 1 && _historyTotalMatches > 0) ...[
              const SizedBox(height: 16),
              _buildHistoryPagination(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Toutes', 'all'),
          const SizedBox(width: 8),
          _filterChip('Solo', 'solo'),
          const SizedBox(width: 8),
          _filterChip('Groupe', 'group'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _historySelectedFilter == value;

    final bg = selected
        ? TuuurTheme.brandPurple.withOpacity(0.3)
        : TuuurTheme.brandDarkGray.withOpacity(0.5);
    final border = selected
        ? TuuurTheme.brandPurple
        : TuuurTheme.brandGray.withOpacity(0.3);
    final textColor = selected ? TuuurTheme.brandPurple : TuuurTheme.brandGray;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          _historySelectedFilter = value;
          _historyCurrentPage =
              1; // Reset à la page 1 lors du changement de filtre
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<models_hist.HistoryMatchDto> matches) {
    if (matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(FontAwesomeIcons.inbox, size: 32, color: TuuurTheme.brandGray),
            SizedBox(height: 8),
            Text(
              'Aucune partie trouvée',
              style: TextStyle(color: TuuurTheme.brandGray),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildHistoryItem(match);
      },
    );
  }

  Widget _buildHistoryItem(models_hist.HistoryMatchDto match) {
    final percent = match.percent;
    final baseColor = _colorForPercent(percent);
    final bgScore = baseColor.withOpacity(0.2);
    final dt = match.dt;
    final dateLabel = dt != null ? _formatRelative(dt) : '';

    // Récupérer toutes les difficultés et les trier par id
    final sortedDifficulties = List<models_hist.HistoryPartyDifficultyDto>.from(
      match.partyDifficulty,
    )..sort((a, b) => (a.difficulty?.id ?? 0).compareTo(b.difficulty?.id ?? 0));

    final diffIds = sortedDifficulties
        .where((pd) => pd.difficulty?.id != null)
        .map((pd) => pd.difficulty!.id!)
        .toList();

    final themeLabels =
        (match.partyTheme.toList()..sort(
              (a, b) => (a.theme?.label ?? '').compareTo(b.theme?.label ?? ''),
            ))
            .map((pt) => (pt.theme?.label ?? '').trim())
            .where((label) => label.isNotEmpty)
            .toList();

    final visibleThemes = themeLabels.take(2).toList();
    final extraThemesCount = themeLabels.length - visibleThemes.length;

    return Opacity(
      opacity: _historyLoading ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _historyLoading
              ? null
              : () {
                  final type = (match.partyType?.label ?? '').toLowerCase();
                  final isSolo = type == 'solo';
                  context.goHistoryQuiz(match.id, isSolo: isSolo);
                },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TuuurTheme.brandDarkGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TuuurTheme.brandPurple.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge score
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [bgScore, baseColor.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: baseColor, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (match.score ?? 0).toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: baseColor,
                        ),
                      ),
                      Text(
                        'pts',
                        style: TextStyle(
                          fontSize: 10,
                          color: baseColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Infos principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP ROW: titre + statut à gauche / date en haut à droite
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // important
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  match.partyType?.label ?? 'Partie',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TuuurTheme.brandLightGray,
                                  ),
                                ),
                                if (!match.finish)
                                  _pill(
                                    label: 'En cours',
                                    bgColor: TuuurTheme.brandOrange.withOpacity(
                                      0.15,
                                    ),
                                    borderColor: TuuurTheme.brandOrange
                                        .withOpacity(0.4),
                                    textColor: TuuurTheme.brandOrange,
                                    icon: FontAwesomeIcons.hourglassHalf,
                                  )
                                else
                                  _pill(
                                    label: 'Terminer',
                                    bgColor: TuuurTheme.brandGreen.withOpacity(
                                      0.15,
                                    ),
                                    borderColor: TuuurTheme.brandGreen
                                        .withOpacity(0.4),
                                    textColor: TuuurTheme.brandGreen,
                                    icon: FontAwesomeIcons.check,
                                  ),
                              ],
                            ),
                          ),

                          if (dateLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Text(
                                  dateLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: TuuurTheme.brandGray,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Plus d'espace entre le titre et les difficultés
                      if (diffIds.isNotEmpty) ...[
                        const SizedBox(
                          height: 12,
                        ), // + d'espace par rapport au titre
                        _buildDifficultiesGrid(diffIds),
                      ],

                      const SizedBox(height: 10),

                      // Ligne stats (questions, % réussite, temps)
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                FontAwesomeIcons.circleQuestion,
                                size: 12,
                                color: TuuurTheme.brandPurple,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Questions:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TuuurTheme.brandGray,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (match.nbQuestions ?? 0).toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: TuuurTheme.brandLightGray,
                                ),
                              ),
                            ],
                          ),
                          if (percent != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  FontAwesomeIcons.percent,
                                  size: 12,
                                  color: TuuurTheme.brandPurple,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Réussite:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: TuuurTheme.brandGray,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$percent%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: baseColor,
                                  ),
                                ),
                              ],
                            ),
                          if (match.time != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  FontAwesomeIcons.clock,
                                  size: 12,
                                  color: TuuurTheme.brandOrange,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Temps:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: TuuurTheme.brandGray,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(match.time!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: TuuurTheme.brandLightGray,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Ligne thèmes (max 2 + "+N")
                      if (themeLabels.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(
                              FontAwesomeIcons.tags,
                              size: 11,
                              color: TuuurTheme.brandPurple,
                            ),

                            ...visibleThemes.map((label) {
                              return _pill(
                                label: label,
                                bgColor: TuuurTheme.brandPurple.withOpacity(
                                  0.1,
                                ),
                                borderColor: TuuurTheme.brandPurple.withOpacity(
                                  0.3,
                                ),
                                textColor: TuuurTheme.brandPurple,
                              );
                            }),

                            if (extraThemesCount > 0)
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                child: _pill(
                                  label: '+$extraThemesCount',
                                  bgColor: TuuurTheme.brandPurple.withOpacity(
                                    0.18,
                                  ),
                                  borderColor: TuuurTheme.brandPurple
                                      .withOpacity(0.35),
                                  textColor: TuuurTheme.brandLightGray,
                                  width: _moreThemesPillWidth,
                                  height: _moreThemesPillHeight,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryPagination() {
    final totalVisible = _visibleHistoryMatches.length;
    if (_historyTotalPages <= 1 || totalVisible == 0) {
      return const SizedBox.shrink();
    }

    final start = (_historyCurrentPage - 1) * _historyPageSize + 1;
    var end = _historyCurrentPage * _historyPageSize;
    if (end > totalVisible) end = totalVisible;

    final isFirstPage = _historyCurrentPage <= 1;
    final isLastPage = _historyCurrentPage >= _historyTotalPages;

    return Column(
      children: [
        Text(
          'Affichage de $start à $end sur $totalVisible '
          'partie${totalVisible > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12, color: TuuurTheme.brandGray),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            IconButton(
              onPressed: !isFirstPage ? () => _changeHistoryPage(1) : null,
              icon: const Icon(FontAwesomeIcons.anglesLeft, size: 12),
              tooltip: 'Première page',
              visualDensity: VisualDensity.compact,
            ),
            TextButton.icon(
              onPressed: !isFirstPage
                  ? () => _changeHistoryPage(_historyCurrentPage - 1)
                  : null,
              icon: const Icon(FontAwesomeIcons.chevronLeft, size: 12),
              label: const Text('', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
            Text(
              'Page $_historyCurrentPage / $_historyTotalPages',
              style: const TextStyle(
                fontSize: 12,
                color: TuuurTheme.brandLightGray,
              ),
            ),
            TextButton.icon(
              onPressed: !isLastPage
                  ? () => _changeHistoryPage(_historyCurrentPage + 1)
                  : null,
              icon: const Icon(FontAwesomeIcons.chevronRight, size: 12),
              label: const Text('', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
            IconButton(
              onPressed: !isLastPage
                  ? () => _changeHistoryPage(_historyTotalPages)
                  : null,
              icon: const Icon(FontAwesomeIcons.anglesRight, size: 12),
              tooltip: 'Dernière page',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _profileCard() {
    final name = _nickName ?? 'Joueur';
    final avatarUrl = (_avatar != null && _avatar!.startsWith('http'))
        ? _avatar!
        : _fallbackAvatarUrl;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: TuuurStyles.gamingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: _Avatar(
                  avatarUrl: avatarUrl,
                  bytes: _avatarBytes,
                  base64OrDataUri: _avatar,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _isEditingNickname
                    ? _buildNicknameEditor()
                    : _buildNicknameDisplay(name),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GamingButtonPrimary(
                text: 'Changer le mot de passe',
                icon: FontAwesomeIcons.key,
                onPressed: () => context.push('/change-password'),
              ),
              const SizedBox(height: 12),
              GamingButtonSecondary(
                text: 'Se déconnecter',
                icon: FontAwesomeIcons.rightFromBracket,
                onPressed: _signOut,
              ),
              const SizedBox(height: 12),
              GamingButtonSecondary(
                text: 'Supprimer mon compte',
                icon: FontAwesomeIcons.trash,
                onPressed: _deleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameDisplay(String name) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: name));
            },
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: TuuurTheme.brandLightGray,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(
            FontAwesomeIcons.pencil,
            size: 18,
            color: TuuurTheme.brandPurple,
          ),
          onPressed: _startEditingNickname,
          tooltip: 'Modifier le pseudo',
        ),
      ],
    );
  }

  Widget _buildNicknameEditor() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: TextField(
            controller: _nicknameController,
            autofocus: true,
            enabled: !_isSavingNickname,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: TuuurTheme.brandPurple,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: TuuurTheme.brandPurple.withOpacity(0.5),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: TuuurTheme.brandPurple,
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (_) => _saveNickname(),
          ),
        ),
        const SizedBox(width: 8),
        if (_isSavingNickname)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TuuurTheme.brandPurple,
            ),
          )
        else ...[
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.check,
              size: 18,
              color: TuuurTheme.brandGreen,
            ),
            onPressed: _saveNickname,
            tooltip: 'Valider',
          ),
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.xmark,
              size: 18,
              color: Colors.redAccent,
            ),
            onPressed: _cancelEditingNickname,
            tooltip: 'Annuler',
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String avatarUrl; // utilisé si bytes null ET pas de base64
  final Uint8List? bytes; // priorité d’affichage
  final String? base64OrDataUri; // si présent, tentative de décodage interne

  const _Avatar({required this.avatarUrl, this.bytes, this.base64OrDataUri});

  Uint8List? _decode(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      var raw = s.trim();
      final comma = raw.indexOf(',');
      if (raw.startsWith('data:image') && comma != -1) {
        raw = raw.substring(comma + 1);
      }
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget img;

    if (bytes != null) {
      img = Image.memory(bytes!, fit: BoxFit.cover, width: 60, height: 60);
    } else {
      final decoded = _decode(base64OrDataUri);
      if (decoded != null) {
        img = Image.memory(decoded, fit: BoxFit.cover, width: 60, height: 60);
      } else {
        img = Image.network(
          avatarUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: TuuurTheme.brandPurple.withOpacity(0.2),
            child: const Icon(
              Icons.person,
              color: TuuurTheme.brandPurple,
              size: 30,
            ),
          ),
        );
      }
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: TuuurTheme.brandPurple, width: 2),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(30), child: img),
    );
  }
}
