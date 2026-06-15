import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/api_module.dart';
import '../../api/ranked/ranked_ranking_models.dart';
import '../../api/ranked/ranked_rest_api_service.dart';
import '../../stores/auth_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/gaming_widgets.dart';
import '../../widgets/navigation_header.dart';
import '../../navigation/app_router.dart';

class LeaderboardPage extends StatefulWidget {
  /// Point d'injection pour les tests — null = ApiModule.instance.rankedApi.
  final RankedRestApiService? rankingApiOverride;

  const LeaderboardPage({super.key, this.rankingApiOverride});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  static const int _pageSize = 50;

  bool _loading = true;
  String? _error;
  RankingPageDto? _data;
  int _page = 1;

  RankedRestApiService get _api =>
      widget.rankingApiOverride ?? ApiModule.instance.rankedApi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? page}) async {
    final target = page ?? _page;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.getRanking(page: target, size: _pageSize);
      if (!mounted) return;

      if (res.ok && res.data != null) {
        setState(() {
          _data = res.data;
          _page = res.data!.currentPage <= 0 ? target : res.data!.currentPage;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.message ?? 'Impossible de charger le classement.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur: $e';
        _loading = false;
      });
    }
  }

  // ─── Données dérivées ──────────────────────────────────────────────────────

  String? get _currentUserId {
    final id = AuthStore.instance.user?.id;
    return (id != null && id.isNotEmpty) ? id : null;
  }

  bool _isCurrentUser(RankingUser p) => p.id == _currentUserId;

  int get _currentPage => _data?.currentPage ?? _page;

  /// Joueurs de la page, triés par ELO décroissant (comme le site web).
  List<RankingUser> get _sorted {
    final users = List<RankingUser>.from(_data?.users ?? const []);
    users.sort((a, b) => b.globalElo.compareTo(a.globalElo));
    return users;
  }

  bool get _showPodium => _currentPage <= 1 && _sorted.isNotEmpty;

  /// Rang affiché = position dans le classement (l'API renvoie userRanking null
  /// par joueur), décalé selon la page.
  int _displayRank(int indexInPage) =>
      (_currentPage - 1) * _pageSize + indexInPage + 1;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goBack();
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: const NavigationHeader(),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const Center(child: GamingLoadingIndicator());
    }

    if (_error != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: TuuurTheme.brandOrange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: TuuurTheme.brandLightGray,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              GamingButtonPrimary(
                text: 'Réessayer',
                icon: FontAwesomeIcons.rotateRight,
                onPressed: () => _load(),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = _sorted;
    final rest = _showPodium ? sorted.skip(3).toList() : sorted;
    final baseIndex = _showPodium ? (sorted.length < 3 ? sorted.length : 3) : 0;

    return RefreshIndicator(
      color: TuuurTheme.brandPurple,
      onRefresh: () => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            GamingCard(
              child: sorted.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showPodium) ...[
                          _buildPodium(sorted),
                          const SizedBox(height: 8),
                        ],
                        ...rest.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildPlayerRow(
                              e.value,
                              _displayRank(baseIndex + e.key),
                            ),
                          ),
                        ),
                        ..._buildPinnedCurrentUser(),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        FaIcon(FontAwesomeIcons.trophy, color: TuuurTheme.brandYellow, size: 24),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Classement Global',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: TuuurTheme.brandLightGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.trophy,
            size: 40,
            color: TuuurTheme.brandGray,
          ),
          SizedBox(height: 12),
          Text(
            'Aucun joueur classé pour le moment.',
            style: TextStyle(color: TuuurTheme.brandGray),
          ),
        ],
      ),
    );
  }

  // ─── Podium ────────────────────────────────────────────────────────────────

  Widget _buildPodium(List<RankingUser> sorted) {
    final first = sorted.isNotEmpty ? sorted[0] : null;
    final second = sorted.length > 1 ? sorted[1] : null;
    final third = sorted.length > 2 ? sorted[2] : null;

    if (first != null && second == null && third == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: _buildPodiumPlace(
            first,
            1,
            avatarSize: 76,
            barHeight: 120,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second != null
              ? _buildPodiumPlace(second, 2, avatarSize: 56, barHeight: 88)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: first != null
              ? _buildPodiumPlace(first, 1, avatarSize: 72, barHeight: 120)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: third != null
              ? _buildPodiumPlace(third, 3, avatarSize: 52, barHeight: 70)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPodiumPlace(
    RankingUser player,
    int rank, {
    required double avatarSize,
    required double barHeight,
  }) {
    final isMe = _isCurrentUser(player);
    final rankColor = rank == 1
        ? TuuurTheme.brandYellow
        : rank == 2
        ? TuuurTheme.brandGray
        : TuuurTheme.brandOrange;
    final borderColor = isMe ? TuuurTheme.brandPurple : rankColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1)
          const FaIcon(
            FontAwesomeIcons.crown,
            size: 18,
            color: TuuurTheme.brandYellow,
          )
        else
          const SizedBox(height: 18),
        const SizedBox(height: 6),

        // Avatar + badge de rang
        SizedBox(
          width: avatarSize,
          height: avatarSize + 8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: rank == 1 ? 4 : 3),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AvatarWidget(
                    avatarBase64: player.avatar,
                    fallbackText: player.displayName,
                    size: avatarSize,
                  ),
                ),
              ),
              Positioned(
                bottom: -6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: rankColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: TuuurTheme.brandDark, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank == 1 ? TuuurTheme.brandDark : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (isMe) ...[
          _buildYouChip(),
          const SizedBox(height: 4),
        ],

        Text(
          player.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: rank == 1 ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: isMe ? TuuurTheme.brandPurple : TuuurTheme.brandLightGray,
          ),
        ),
        const SizedBox(height: 2),
        _buildEloText(
          player.globalElo,
          color: rankColor,
          size: rank == 1 ? 22 : 18,
        ),
        const SizedBox(height: 8),

        // Marche du podium
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                rankColor.withOpacity(0.30),
                rankColor.withOpacity(0.08),
              ],
            ),
            border: Border.all(color: rankColor.withOpacity(0.35), width: 2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildEloText(int elo, {required Color color, double size = 18}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$elo',
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          TextSpan(
            text: ' ELO',
            style: TextStyle(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildYouChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: TuuurTheme.brandPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Vous',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─── Lignes du classement (rang 4+) ─────────────────────────────────────────

  Widget _buildPlayerRow(RankingUser player, int rank) {
    final isMe = _isCurrentUser(player);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isMe
            ? TuuurTheme.brandPurple.withOpacity(0.10)
            : TuuurTheme.brandDarkGray.withOpacity(0.20),
        border: Border.all(
          color: isMe
              ? TuuurTheme.brandPurple.withOpacity(0.60)
              : TuuurTheme.brandPurple.withOpacity(0.10),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isMe ? TuuurTheme.brandPurple : TuuurTheme.brandGray,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isMe
                    ? TuuurTheme.brandPurple
                    : TuuurTheme.brandPurple.withOpacity(0.3),
                width: isMe ? 2 : 1,
              ),
            ),
            child: ClipOval(
              child: AvatarWidget(
                avatarBase64: player.avatar,
                fallbackText: player.displayName,
                size: 40,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isMe
                    ? TuuurTheme.brandPurple
                    : TuuurTheme.brandLightGray,
              ),
            ),
          ),
          if (isMe) ...[const SizedBox(width: 8), _buildYouChip()],
          const SizedBox(width: 10),
          _buildEloText(player.globalElo, color: TuuurTheme.brandPurple, size: 18),
        ],
      ),
    );
  }

  /// Épingle l'utilisateur courant en bas s'il n'est pas dans la page affichée.
  List<Widget> _buildPinnedCurrentUser() {
    final me = _currentUserId;
    final data = _data;
    if (me == null || data == null) return const [];
    if (_sorted.any((p) => p.id == me)) return const [];

    final user = AuthStore.instance.user;
    final rankLabel = data.userRanking > 0 ? '${data.userRanking}' : '—';

    return [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            '···',
            style: TextStyle(
              color: TuuurTheme.brandGray,
              fontSize: 18,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: TuuurTheme.brandPurple.withOpacity(0.10),
          border: Border.all(color: TuuurTheme.brandPurple.withOpacity(0.60)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                rankLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: TuuurTheme.brandPurple,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: TuuurTheme.brandPurple, width: 2),
              ),
              child: ClipOval(
                child: AvatarWidget(
                  avatarBase64: user?.avatar,
                  fallbackText: user?.nickName ?? '?',
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user?.nickName ?? 'Vous',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandPurple,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildYouChip(),
            const SizedBox(width: 10),
            _buildEloText(
              data.userElo,
              color: TuuurTheme.brandPurple,
              size: 18,
            ),
          ],
        ),
      ),
    ];
  }

  // ─── Pagination ──────────────────────────────────────────────────────────

  Widget _buildPagination() {
    final current = _data?.currentPage ?? _page;
    final total = _data?.totalPages ?? 1;
    final canPrev = current > 1 && !_loading;
    final canNext = current < total && !_loading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: canPrev ? () => _load(page: current - 1) : null,
          icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 14),
          color: TuuurTheme.brandPurple,
          disabledColor: TuuurTheme.brandGray.withOpacity(0.35),
          tooltip: 'Page précédente',
        ),
        Text(
          'Page $current / $total',
          style: const TextStyle(
            color: TuuurTheme.brandLightGray,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: canNext ? () => _load(page: current + 1) : null,
          icon: const FaIcon(FontAwesomeIcons.chevronRight, size: 14),
          color: TuuurTheme.brandPurple,
          disabledColor: TuuurTheme.brandGray.withOpacity(0.35),
          tooltip: 'Page suivante',
        ),
      ],
    );
  }
}
