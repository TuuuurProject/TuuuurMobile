import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
import '../../api/auth_api_service.dart' as api_auth;
import '../../api/history_api_service.dart' as api_hist;

class ProfilePage extends StatefulWidget {
  final api_auth.AuthApi? authApi;
  final api_hist.HistoryApi? historyApi;

  const ProfilePage({
    super.key,
    this.authApi,
    this.historyApi,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  api_auth.AuthApi get _authApi => widget.authApi ?? api_auth.authApi;
  api_hist.HistoryApi get _historyApi => widget.historyApi ?? api_hist.historyApi;

  bool _loading = false;
  String? _nickName;
  String? _email;
  String? _avatar; // valeur renvoyée par l’API (url, base64, data-uri…)
  int? _userId;

  Uint8List? _avatarBytes; // bytes à afficher (aperçu local OU décodage base64 serveur)
  final _picker = ImagePicker();

  bool _fetched = false;

  // --- Historique ---
  bool _historyLoading = false;
  String? _historyError;
  List<api_hist.HistoryMatchDto> _historyMatches = [];
  int _historyTotalMatches = 0;
  int? _historyAvgPercent;
  String _historySelectedFilter = 'all';

  static const int _historyPageSize = 10;
  int _historyCurrentPage = 1;
  int _historyTotalPages = 1;

  String get _fallbackAvatarUrl {
    final seed = Uri.encodeComponent(_nickName ?? 'player');
    return 'https://api.dicebear.com/9.x/adventurer-neutral/svg?seed=$seed';
  }

  List<api_hist.HistoryMatchDto> get _visibleHistoryMatches {
    var list = List<api_hist.HistoryMatchDto>.from(_historyMatches);

    if (_historySelectedFilter == 'solo') {
      list = list
          .where((m) => (m.partyType?.label ?? '').toLowerCase() == 'solo')
          .toList();
    }

    // Plus récente -> plus ancienne
    list.sort((a, b) {
      final adt = a.dt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bdt = b.dt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bdt.compareTo(adt); // desc
    });

    return list;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
        appBar: const NavigationHeader(
          showBack: true,
        ),
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
              if (!isAuthenticated) ...[
                _notConnectedCard(),
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

    setState(() => _loading = true);

    final res = await _authApi.me(headers: store.authHeaders);

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok && res.data != null) {
      final u = res.data!;
      final val = u.avatar;
      final decoded = _decodeBase64Image(val);

      setState(() {
        _nickName = u.nickName;
        _email = u.email;
        _avatar = val;
        _userId = u.id;
        _avatarBytes = decoded ?? _avatarBytes;
      });

      await _fetchHistory();
    } else if (res.statusCode == 401) {
      await store.signOut();
      if (!mounted) return;
      _showToast('Session expirée. Veuillez vous reconnecter.');
    } else {
      _showToast(res.message ?? 'Impossible de charger le profil.');
    }
  }

  Future<void> _fetchHistory({int page = 1}) async {
    final store = MyAuthStore.of(context);
    if (!store.isAuthenticated) return;

    setState(() {
      _historyLoading = true;
      _historyError = null;
    });

    final res = await _historyApi.getHistory(
      headers: store.authHeaders,
      page: page,
      size: _historyPageSize,
    );

    if (!mounted) return;

    if (!res.ok || res.data == null) {
      setState(() {
        _historyLoading = false;
        _historyError = res.message ?? 'Impossible de charger l’historique.';
        _historyMatches = [];
        _historyTotalMatches = 0;
        _historyAvgPercent = null;
        _historyCurrentPage = 1;
        _historyTotalPages = 1;
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
      _historyAvgPercent = avgPercent;
      _historyCurrentPage = historyPage.currentPage ?? page;
      _historyTotalPages = historyPage.totalPages ?? 1;
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

      if (!mounted) return;
      final store = MyAuthStore.of(context);

      setState(() => _loading = true);

      final res = await _authApi.updateAvatarBase64(
        base64: base64Str,
        headers: store.authHeaders,
      );

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

    final res = await _authApi.deleteMe(headers: store.authHeaders);

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
      _historyTotalPages = 1;
    });

    _showToast('Déconnecté.', color: TuuurTheme.brandGreen);
    context.go('/'); // Retour à l’accueil
  }

  Future<void> _changeHistoryPage(int page) async {
    if (page < 1 || page > _historyTotalPages || _historyLoading) return;
    await _fetchHistory(page: page);
  }

  // -----------------------------
  // Helpers / formatting
  // -----------------------------

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

  Color _difficultyBaseColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('facile')) return TuuurTheme.brandGreen;
    if (lower.contains('moyen')) return TuuurTheme.brandOrange;
    if (lower.contains('difficile')) return Colors.deepOrange;
    if (lower.contains('hardcore')) return Colors.redAccent;
    return TuuurTheme.brandGray;
  }

  void _showToast(String message, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // -----------------------------
  // UI helpers
  // -----------------------------

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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 4),
          ],
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
    );
  }

  Widget _buildDifficultyPill(String label) {
    final color = _difficultyBaseColor(label);
    return _pill(
      label: label,
      bgColor: color.withOpacity(0.2),
      borderColor: color.withOpacity(0.4),
      textColor: color,
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
          ),
        ],
      ),
    );
  }

  Widget _historySection() {
    final matches = _visibleHistoryMatches;

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
                '${_historyTotalMatches} Partie${_historyTotalMatches > 1 ? 's' : ''}',
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
              child: CircularProgressIndicator(
                color: TuuurTheme.brandPurple,
              ),
            ),
          ] else if (_historyError != null) ...[
            Text(
              _historyError!,
              style: const TextStyle(
                color: TuuurTheme.brandOrange,
              ),
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
    final textColor =
        selected ? TuuurTheme.brandPurple : TuuurTheme.brandGray;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          _historySelectedFilter = value;
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

  Widget _buildHistoryList(List<api_hist.HistoryMatchDto> matches) {
    if (matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.inbox,
              size: 32,
              color: TuuurTheme.brandGray,
            ),
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

  Widget _buildHistoryItem(api_hist.HistoryMatchDto match) {
    final percent = match.percent;
    final baseColor = _colorForPercent(percent);
    final bgScore = baseColor.withOpacity(0.2);
    final dt = match.dt;
    final dateLabel = dt != null ? _formatRelative(dt) : '';

    final diffLabel = match.partyDifficulty.isNotEmpty
        ? match.partyDifficulty.first.difficulty?.label
        : null;

    return Opacity(
      opacity: _historyLoading ? 0.6 : 1,
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
                  colors: [
                    bgScore,
                    baseColor.withOpacity(0.05),
                  ],
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
                  // Ligne titre + badges + date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
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
                                bgColor: TuuurTheme.brandOrange
                                    .withOpacity(0.15),
                                borderColor: TuuurTheme.brandOrange
                                    .withOpacity(0.4),
                                textColor: TuuurTheme.brandOrange,
                                icon: FontAwesomeIcons.hourglassHalf,
                              )
                            else
                              _pill(
                                label: 'Terminer',
                                bgColor:
                                    TuuurTheme.brandGreen.withOpacity(0.15),
                                borderColor:
                                    TuuurTheme.brandGreen.withOpacity(0.4),
                                textColor: TuuurTheme.brandGreen,
                                icon: FontAwesomeIcons.check,
                              ),
                            if (diffLabel != null && diffLabel.isNotEmpty)
                              _buildDifficultyPill(diffLabel),
                          ],
                        ),
                      ),
                      if (dateLabel.isNotEmpty)
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: TuuurTheme.brandGray,
                          ),
                          textAlign: TextAlign.right,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

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

                  // Ligne thèmes
                  if (match.partyTheme.isNotEmpty)
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
                        ...match.partyTheme.map((pt) {
                          final label = pt.theme?.label ?? '';
                          if (label.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return _pill(
                            label: label,
                            bgColor: TuuurTheme.brandPurple.withOpacity(0.1),
                            borderColor:
                                TuuurTheme.brandPurple.withOpacity(0.3),
                            textColor: TuuurTheme.brandPurple,
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPagination() {
    if (_historyTotalPages <= 1 || _historyTotalMatches == 0) {
      return const SizedBox.shrink();
    }

    final start = (_historyCurrentPage - 1) * _historyPageSize + 1;
    var end = _historyCurrentPage * _historyPageSize;
    if (end > _historyTotalMatches) end = _historyTotalMatches;

    final isFirstPage = _historyCurrentPage <= 1;
    final isLastPage = _historyCurrentPage >= _historyTotalPages;

    return Column(
      children: [
        Text(
          'Affichage de $start à $end sur $_historyTotalMatches '
          'partie${_historyTotalMatches > 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 12,
            color: TuuurTheme.brandGray,
          ),
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
              onPressed: (!isFirstPage && !_historyLoading)
                  ? () => _changeHistoryPage(1)
                  : null,
              icon: const Icon(
                FontAwesomeIcons.anglesLeft,
                size: 12,
              ),
              tooltip: 'Première page',
              visualDensity: VisualDensity.compact,
            ),
            TextButton.icon(
              onPressed: (!isFirstPage && !_historyLoading)
                  ? () => _changeHistoryPage(_historyCurrentPage - 1)
                  : null,
              icon: const Icon(
                FontAwesomeIcons.chevronLeft,
                size: 12,
              ),
              label: const Text(
                '',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              onPressed: (!isLastPage && !_historyLoading)
                  ? () => _changeHistoryPage(_historyCurrentPage + 1)
                  : null,
              icon: const Icon(
                FontAwesomeIcons.chevronRight,
                size: 12,
              ),
              label: const Text(
                '',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
            IconButton(
              onPressed: (!isLastPage && !_historyLoading)
                  ? () => _changeHistoryPage(_historyTotalPages)
                  : null,
              icon: const Icon(
                FontAwesomeIcons.anglesRight,
                size: 12,
              ),
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
                child: const Text(
                  '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
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
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GamingButtonPrimary(
                text: 'Changer le pseudo',
                icon: FontAwesomeIcons.penToSquare,
                onPressed: () async {
                  final updatedUsername = await context.push<String>(
                    '/change-nickname',
                  );

                  if (!mounted || updatedUsername == null) return;

                  setState(() {
                    _nickName = updatedUsername;
                  });
                },
              ),
              const SizedBox(height: 12),
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
}

class _Avatar extends StatelessWidget {
  final String avatarUrl; // utilisé si bytes null ET pas de base64
  final Uint8List? bytes; // priorité d’affichage
  final String? base64OrDataUri; // si présent, tentative de décodage interne

  const _Avatar({
    required this.avatarUrl,
    this.bytes,
    this.base64OrDataUri,
  });

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: img,
      ),
    );
  }
}
