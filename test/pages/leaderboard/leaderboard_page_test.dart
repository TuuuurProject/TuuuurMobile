import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth/auth_models.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_ranking_models.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_rest_api_service.dart';
import 'package:tuuuur_flutter/pages/leaderboard/leaderboard_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Secure-storage mock (pour AuthStore)
// ─────────────────────────────────────────────────────────────────────────────

const MethodChannel _kSecureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);
final Map<String, String> _kSecureStore = {};

void _setupSecureStorageMock() {
  _kSecureStorageChannel.setMockMethodCallHandler((MethodCall call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
    switch (call.method) {
      case 'write':
        final key = args['key'] as String?;
        final value = args['value'] as String?;
        if (key != null && value != null) _kSecureStore[key] = value;
        return null;
      case 'read':
        return _kSecureStore[args['key']];
      case 'delete':
        _kSecureStore.remove(args['key'] as String? ?? '');
        return null;
      case 'deleteAll':
        _kSecureStore.clear();
        return null;
      case 'readAll':
        return Map<String, String>.from(_kSecureStore);
      case 'containsKey':
        final key = args['key'] as String?;
        return key != null && _kSecureStore.containsKey(key);
      default:
        return null;
    }
  });
}

Future<void> _signIn(String userId, {String nick = 'Moi'}) async {
  await AuthStore.instance.signInWithSession(
    AuthSessionDto(
      user: UserDto(id: userId, nickName: nick, email: '$userId@test.com'),
      token: AuthTokenDto(token: 'tok'),
      isGoogleUser: false,
      raw: const {},
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake API + factories
// ─────────────────────────────────────────────────────────────────────────────

class FakeRankedApi extends RankedRestApiService {
  FakeRankedApi() : super(apiClient: ApiClient(baseUrl: 'http://localhost:1'));

  ApiResponse<RankingPageDto>? response;
  ApiResponse<RankingPageDto> Function(int page, int size)? handler;
  Future<void>? delay;
  final List<int> requestedPages = [];

  @override
  Future<ApiResponse<RankingPageDto>> getRanking({
    int page = 1,
    int size = 50,
  }) async {
    requestedPages.add(page);
    if (delay != null) await delay;
    if (handler != null) return handler!(page, size);
    return response ?? ApiResponse.ok(_ranking(), statusCode: 200);
  }
}

RankingUser _user(int rank, {String? id, String? name, int? elo}) => RankingUser(
  id: id ?? 'u$rank',
  nickName: name ?? 'Player$rank',
  globalElo: elo ?? (2000 - rank * 10),
  userRanking: 0, // l'API renvoie null par joueur
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

Future<void> _pump(
  WidgetTester tester,
  FakeRankedApi api, {
  Size size = const Size(900, 1800),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(home: LeaderboardPage(rankingApiOverride: api)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  tester.takeException();
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_setupSecureStorageMock);
  tearDownAll(() => _kSecureStorageChannel.setMockMethodCallHandler(null));

  setUp(() async {
    _kSecureStore.clear();
    await AuthStore.instance.signOut();
  });
  tearDown(() async {
    _kSecureStore.clear();
    await AuthStore.instance.signOut();
  });

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

      expect(find.text('Player1'), findsOneWidget); // podium 1er
      expect(api.requestedPages.length, 2);

      await _finish(tester);
    });

    testWidgets('podium top 3 + liste du reste avec ELO', (tester) async {
      final api = FakeRankedApi()
        ..response = ApiResponse.ok(_ranking(count: 6), statusCode: 200);

      await _pump(tester, api);
      await _settle(tester);

      // Podium (top 3)
      expect(find.text('Player1'), findsOneWidget);
      expect(find.text('Player2'), findsOneWidget);
      expect(find.text('Player3'), findsOneWidget);

      // Liste (rangs 4-6)
      expect(find.text('Player4'), findsOneWidget);
      expect(find.text('Player6'), findsOneWidget);

      // ELO du 4e (2000 - 4*10 = 1960) affiché au format "1960 ELO".
      expect(find.text('1960 ELO'), findsOneWidget);

      // Pagination toujours visible.
      expect(find.text('Page 1 / 1'), findsOneWidget);

      await _finish(tester);
    });

    testWidgets('2 joueurs → podium #1 #2 (rangs par position)', (tester) async {
      final api = FakeRankedApi()
        ..response = ApiResponse.ok(
          const RankingPageDto(
            users: [
              RankingUser(
                id: 'a',
                nickName: 'Alice',
                globalElo: 1020,
                userRanking: 0,
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

      // Les deux joueurs apparaissent (triés par ELO : Alice 1020 > Bob 980).
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('1020 ELO'), findsOneWidget);
      expect(find.text('Page 1 / 1'), findsOneWidget);

      await _finish(tester);
    });

    testWidgets('aucun joueur → état vide', (tester) async {
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

    testWidgets('utilisateur courant présent → badge "Vous"', (tester) async {
      await _signIn('u2', nick: 'Player2');

      final api = FakeRankedApi()
        ..response = ApiResponse.ok(_ranking(count: 6), statusCode: 200);

      await _pump(tester, api);
      await _settle(tester);

      // Le joueur connecté (id u2) est mis en avant.
      expect(find.text('Vous'), findsWidgets);

      await _finish(tester);
    });

    testWidgets('utilisateur courant hors page → épinglé en bas', (
      tester,
    ) async {
      await _signIn('zzz', nick: 'MoiTest');

      final api = FakeRankedApi()
        ..response = ApiResponse.ok(
          _ranking(count: 6, userRanking: 99, userElo: 1234),
          statusCode: 200,
        );

      await _pump(tester, api);
      await _settle(tester);

      // Séparateur + ligne épinglée avec mon pseudo, mon rang et mon ELO.
      expect(find.text('···'), findsOneWidget);
      expect(find.text('MoiTest'), findsOneWidget);
      expect(find.text('Vous'), findsWidgets);
      expect(find.text('1234 ELO'), findsOneWidget);
      expect(find.text('99'), findsOneWidget); // rang épinglé

      await _finish(tester);
    });
  });
}
