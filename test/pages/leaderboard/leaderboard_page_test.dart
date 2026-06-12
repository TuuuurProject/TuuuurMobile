import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_ranking_models.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_rest_api_service.dart';
import 'package:tuuuur_flutter/pages/leaderboard/leaderboard_page.dart';
import 'package:tuuuur_flutter/widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake API
// ─────────────────────────────────────────────────────────────────────────────

class FakeRankedApi extends RankedRestApiService {
  FakeRankedApi() : super(apiClient: ApiClient(baseUrl: 'http://localhost:1'));

  ApiResponse<RankingPageDto>? response;
  ApiResponse<RankingPageDto> Function(int page, int size)? handler;
  Future<void>? delay;
  bool throwError = false;
  final List<int> requestedPages = [];

  @override
  Future<ApiResponse<RankingPageDto>> getRanking({
    int page = 1,
    int size = 50,
  }) async {
    requestedPages.add(page);
    if (delay != null) await delay;
    if (throwError) throw Exception('net');
    if (handler != null) return handler!(page, size);
    return response ?? ApiResponse.ok(_ranking(), statusCode: 200);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Factories
// ─────────────────────────────────────────────────────────────────────────────

RankingUser _user(int rank, {String? name, int? elo}) => RankingUser(
  id: 'u$rank',
  nickName: name ?? 'Player$rank',
  globalElo: elo ?? (2000 - rank * 10),
  userRanking: rank,
);

RankingPageDto _ranking({
  int count = 6,
  int currentPage = 1,
  int totalPages = 1,
  int totalUsers = 6,
  int userRanking = 0,
  int userElo = 0,
}) {
  final startRank = (currentPage - 1) * 50 + 1;
  return RankingPageDto(
    users: List.generate(count, (i) => _user(startRank + i)),
    userRanking: userRanking,
    userElo: userElo,
    currentPage: currentPage,
    totalPages: totalPages,
    totalUsers: totalUsers,
    userTier: 0,
    userDivision: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _pump(
  WidgetTester tester,
  FakeRankedApi api, {
  Size size = const Size(900, 1600),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(home: LeaderboardPage(rankingApiOverride: api)),
  );
  await tester.pump(); // initState → _load()
  await tester.pump(const Duration(milliseconds: 50)); // future résolu
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  tester.takeException(); // ignore overflow/anim
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('LeaderboardPage', () {
    testWidgets('affiche un loader pendant le chargement', (tester) async {
      final blocker = Completer<void>();
      final api = FakeRankedApi()..delay = blocker.future;

      await _pump(tester, api);

      expect(find.byType(GamingLoadingIndicator), findsOneWidget);

      blocker.complete();
      await _settle(tester);
      await _finish(tester);
    });

    testWidgets('erreur API → message + bouton Réessayer relance', (
      tester,
    ) async {
      final api = FakeRankedApi();
      api.handler = (page, size) {
        if (api.requestedPages.length == 1) {
          return ApiResponse.err(message: 'Boom', statusCode: 500);
        }
        return ApiResponse.ok(_ranking(), statusCode: 200);
      };

      await _pump(tester, api);
      await _settle(tester);

      expect(find.text('Boom'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await _settle(tester);

      // 2e appel réussit → le classement s'affiche.
      expect(find.text('Classement Complet'), findsOneWidget);
      expect(api.requestedPages.length, 2);

      await _finish(tester);
    });

    testWidgets('données : podium top 3 + liste du reste', (tester) async {
      final api = FakeRankedApi()
        ..response = ApiResponse.ok(_ranking(count: 6), statusCode: 200);

      await _pump(tester, api);
      await _settle(tester);

      // Podium
      expect(find.text('#1 Player1'), findsOneWidget);
      expect(find.text('#2 Player2'), findsOneWidget);
      expect(find.text('#3 Player3'), findsOneWidget);

      // Liste (rangs 4-6)
      expect(find.text('Classement Complet'), findsOneWidget);
      expect(find.text('#4'), findsOneWidget);
      expect(find.text('#5'), findsOneWidget);
      expect(find.text('#6'), findsOneWidget);
      expect(find.text('Player4'), findsOneWidget);

      // Badge ELO du 4e (globalElo = 2000 - 4*10 = 1960)
      expect(find.text('⚡ 1960'), findsOneWidget);

      // Pagination toujours visible, même sur une seule page.
      expect(find.text('Page 1 / 1'), findsOneWidget);

      await _finish(tester);
    });

    testWidgets(
      '2 joueurs (userRanking null) → rangs par position, podium #1 #2',
      (tester) async {
        final api = FakeRankedApi()
          ..response = ApiResponse.ok(
            const RankingPageDto(
              users: [
                RankingUser(
                  id: 'a',
                  nickName: 'Alice',
                  globalElo: 1020,
                  userRanking: 0, // l'API renvoie null → 0
                ),
                RankingUser(
                  id: 'b',
                  nickName: 'Bob',
                  globalElo: 980,
                  userRanking: 0,
                ),
              ],
              userRanking: 1,
              userElo: 1020,
              currentPage: 1,
              totalPages: 1,
              totalUsers: 2,
              userTier: 2,
              userDivision: 2,
            ),
            statusCode: 200,
          );

        await _pump(tester, api);
        await _settle(tester);

        // Rangs calculés par position malgré userRanking null.
        expect(find.text('#1 Alice'), findsOneWidget);
        expect(find.text('#2 Bob'), findsOneWidget);
        // Tout le monde sur le podium → pas de carte "Classement Complet".
        expect(find.text('Classement Complet'), findsNothing);
        // Plus de #0.
        expect(find.text('#0 Alice'), findsNothing);
        expect(find.text('Page 1 / 1'), findsOneWidget);

        await _finish(tester);
      },
    );

    testWidgets('header affiche le rang du joueur courant', (tester) async {
      final api = FakeRankedApi()
        ..response = ApiResponse.ok(
          _ranking(count: 6, userRanking: 12, userElo: 1480),
          statusCode: 200,
        );

      await _pump(tester, api);
      await _settle(tester);

      expect(find.text('Ton rang : #12 • 1480 ELO'), findsOneWidget);

      await _finish(tester);
    });

    testWidgets('aucun joueur → message vide', (tester) async {
      final api = FakeRankedApi()
        ..response = ApiResponse.ok(
          _ranking(count: 0, totalUsers: 0),
          statusCode: 200,
        );

      await _pump(tester, api);
      await _settle(tester);

      expect(find.text('Aucun joueur classé pour le moment.'), findsOneWidget);

      await _finish(tester);
    });

    testWidgets('pagination : passe à la page suivante', (tester) async {
      final api = FakeRankedApi();
      api.handler = (page, size) => ApiResponse.ok(
        _ranking(count: 6, currentPage: page, totalPages: 3, totalUsers: 150),
        statusCode: 200,
      );

      await _pump(tester, api);
      await _settle(tester);

      expect(find.text('Page 1 / 3'), findsOneWidget);

      await tester.tap(find.byIcon(FontAwesomeIcons.chevronRight));
      await _settle(tester);

      expect(find.text('Page 2 / 3'), findsOneWidget);
      expect(api.requestedPages, contains(2));

      await _finish(tester);
    });
  });
}
