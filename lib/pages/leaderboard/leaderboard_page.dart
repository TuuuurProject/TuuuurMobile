import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/api_module.dart';
import '../../api/ranked/ranked_ranking_models.dart';
import '../../api/ranked/ranked_rest_api_service.dart';
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

  /// Les joueurs visibles sur la page courante.
  List<RankingUser> get _users => _data?.users ?? const [];

  int get _currentPage => _data?.currentPage ?? _page;

  /// Le podium apparaît sur la première page dès qu'il y a au moins un joueur
  /// (1 à 3 joueurs selon le nombre disponible).
  bool get _showPodium => _currentPage <= 1 && _users.isNotEmpty;

  List<RankingUser> get _podium =>
      _showPodium ? _users.take(3).toList() : const [];
  List<RankingUser> get _rest =>
      _showPodium ? _users.skip(3).toList() : _users;

  /// L'API ne fournit pas de rang par joueur ici (`userRanking` est null pour
  /// chaque user) : on le calcule donc à partir de la position dans la liste.
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
            const SizedBox(height: 32),
            if (_users.isEmpty)
              _buildEmptyState()
            else ...[
              if (_showPodium) ...[
                _buildPodium(),
                const SizedBox(height: 32),
              ],
              if (_rest.isNotEmpty) _buildLeaderboardList(),
            ],
            const SizedBox(height: 24),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final myRank = _data?.userRanking ?? 0;
    final myElo = _data?.userElo ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;

        final badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: TuuurTheme.brandOrange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TuuurTheme.brandOrange.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Text(
            myRank > 0
                ? 'Ton rang : #$myRank • $myElo ELO'
                : '${_data?.totalUsers ?? 0} joueurs classés',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TuuurTheme.brandOrange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Classement',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
              const SizedBox(height: 12),
              badge,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                '🏆 Classement Gaming',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: TuuurTheme.brandLightGray,
                ),
              ),
            ),
            const SizedBox(width: 12),
            badge,
          ],
        );
      },
    );
  }

  Widget _buildPodium() {
    final podium = _podium;
    final first = podium.isNotEmpty ? podium[0] : null;
    final second = podium.length > 1 ? podium[1] : null;
    final third = podium.length > 2 ? podium[2] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (second != null) Expanded(child: _buildPodiumCard(second, 2)),
              const SizedBox(width: 16),
              if (first != null) Expanded(child: _buildPodiumCard(first, 1)),
              const SizedBox(width: 16),
              if (third != null) Expanded(child: _buildPodiumCard(third, 3)),
            ],
          );
        }
        return Column(
          children: [
            if (first != null) _buildPodiumCard(first, 1),
            const SizedBox(height: 16),
            Row(
              children: [
                if (second != null)
                  Expanded(child: _buildPodiumCard(second, 2)),
                const SizedBox(width: 16),
                if (third != null)
                  Expanded(child: _buildPodiumCard(third, 3)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPodiumCard(RankingUser player, int rank) {
    final isFirst = rank == 1;
    final isSecond = rank == 2;

    final Color borderColor = isFirst
        ? TuuurTheme.brandYellow
        : isSecond
        ? TuuurTheme.brandOrange
        : TuuurTheme.brandGray;

    final String medal = isFirst
        ? '⭐'
        : isSecond
        ? '🔥'
        : '🥉';

    final double avatarSize = isFirst
        ? 80
        : isSecond
        ? 64
        : 56;
    final double titleSize = isFirst
        ? 24
        : isSecond
        ? 20
        : 18;

    return GamingCard(
      child: Column(
        children: [
          Container(
                width: isFirst ? 48 : (isSecond ? 32 : 28),
                height: isFirst ? 48 : (isSecond ? 32 : 28),
                margin: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Icon(
                    FontAwesomeIcons.trophy,
                    color: borderColor,
                    size: isFirst ? 32 : (isSecond ? 24 : 20),
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 4000.ms),

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isFirst ? 4 : 2,
                  ),
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
                top: -4,
                right: -4,
                child: Container(
                  width: isFirst ? 32 : 24,
                  height: isFirst ? 32 : 24,
                  decoration: BoxDecoration(
                    color: borderColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: TuuurTheme.brandDark, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: isFirst ? TuuurTheme.brandDark : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isFirst ? 16 : 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            '#$rank ${player.displayName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: TuuurTheme.brandLightGray,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor.withOpacity(0.4), width: 1),
            ),
            child: Text(
              '$medal ${player.globalElo} ELO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: borderColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const GamingCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Aucun joueur classé pour le moment.',
            style: TextStyle(color: TuuurTheme.brandGray),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList() {
    final rest = _rest;
    final baseIndex = _showPodium ? _podium.length : 0;

    return GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: TuuurTheme.brandPurple.withOpacity(0.2),
                ),
                child: const Center(
                  child: Text('📊', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Classement Complet',
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
          Container(height: 1, color: TuuurTheme.brandPurple.withOpacity(0.2)),
          const SizedBox(height: 16),

          ...rest.asMap().entries.map(
            (e) => _buildPlayerRow(e.value, _displayRank(baseIndex + e.key)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(RankingUser player, int rank) {
    final isTopTen = rank > 0 && rank <= 10;
    final isTopFive = rank > 0 && rank <= 5;

    final accent = isTopFive
        ? TuuurTheme.brandGreen
        : isTopTen
        ? TuuurTheme.brandOrange
        : TuuurTheme.brandPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 32,
            child: Center(
              child: Text(
                '#$rank',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isTopTen
                      ? TuuurTheme.brandPurple
                      : TuuurTheme.brandGray,
                ),
              ),
            ),
          ),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: TuuurTheme.brandPurple.withOpacity(0.3),
                width: 1,
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
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTopFive
                      ? 'Champion actuel'
                      : isTopTen
                      ? 'Challenger'
                      : 'Joueur confirmé',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: accent),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.4), width: 1),
            ),
            child: Text(
              '⚡ ${player.globalElo}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          disabledColor: TuuurTheme.brandGray.withOpacity(0.4),
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
          disabledColor: TuuurTheme.brandGray.withOpacity(0.4),
          tooltip: 'Page suivante',
        ),
      ],
    );
  }
}
