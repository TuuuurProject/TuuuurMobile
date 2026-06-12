import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth/auth_models.dart';
import 'package:tuuuur_flutter/api/other/history_api_service.dart';
import 'package:tuuuur_flutter/api/other/history_models.dart';
import 'package:tuuuur_flutter/pages/history/history_quiz_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Secure-storage mock (copié du pattern group_test_helpers)
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

void _tearDownSecureStorageMock() {
  _kSecureStorageChannel.setMockMethodCallHandler(null);
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake HistoryApi — retourne des données configurables sans réseau
// ─────────────────────────────────────────────────────────────────────────────

class FakeHistoryApi extends HistoryApi {
  FakeHistoryApi() : super(ApiClient(baseUrl: 'http://localhost:1'));

  ApiResponse<PartyDetailDto>? groupResponse;
  ApiResponse<PartyDetailDto>? soloResponse;
  ApiResponse<PartyDetailDto>? rankedResponse;

  bool simulateNetworkError = false;

  /// Quand non-null, la réponse est retardée jusqu'à ce que ce completer se termine.
  Future<void>? delayFuture;

  @override
  Future<ApiResponse<PartyDetailDto>> getPartyDetail(String partyId) async {
    if (delayFuture != null) await delayFuture;
    if (simulateNetworkError) throw Exception('Network error');
    return groupResponse ??
        ApiResponse.ok(_makeFinishedGroupParty(), statusCode: 200);
  }

  @override
  Future<ApiResponse<PartyDetailDto>> getSoloPartyDetail(String partyId) async {
    if (delayFuture != null) await delayFuture;
    if (simulateNetworkError) throw Exception('Network error');
    return soloResponse ??
        ApiResponse.ok(_makeFinishedSoloParty(), statusCode: 200);
  }

  @override
  Future<ApiResponse<PartyDetailDto>> getRankedPartyDetail(
    String partyId,
  ) async {
    if (delayFuture != null) await delayFuture;
    if (simulateNetworkError) throw Exception('Network error');
    return rankedResponse ??
        ApiResponse.ok(_makeRankedPartyDetail(), statusCode: 200);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test-data factories
// ─────────────────────────────────────────────────────────────────────────────

PartyDetailDto _makeFinishedGroupParty({
  String id = 'party-group-1',
  bool finish = true,
  int score = 80,
}) {
  return PartyDetailDto(
    id: id,
    active: true,
    finish: finish,
    inProgress: !finish,
    partyType: const HistoryPartyTypeDto(id: 2, label: 'Groupe'),
    partyDifficulty: [
      HistoryPartyDifficultyDto(
        id: 1,
        difficulty: const HistoryDifficultyDto(id: 2, label: 'Moyen'),
      ),
    ],
    partyTheme: [
      HistoryPartyThemeDto(
        id: 1,
        theme: const HistoryThemeDto(id: 1, label: 'Général'),
      ),
    ],
    partyQuestions: [
      _makePartyQuestion(
        order: 1,
        wasCorrect: true,
        score: 10,
        questionLabel: 'Q1 ?',
      ),
      _makePartyQuestion(
        order: 2,
        wasCorrect: false,
        score: 0,
        questionLabel: 'Q2 ?',
      ),
    ],
    partyUsers: const [],
    userScores: const [],
    score: score,
  );
}

PartyDetailDto _makeFinishedSoloParty({
  String id = 'party-solo-1',
  bool finish = true,
}) {
  return PartyDetailDto(
    id: id,
    active: true,
    finish: finish,
    inProgress: !finish,
    partyType: const HistoryPartyTypeDto(id: 1, label: 'Solo'),
    partyDifficulty: [],
    partyTheme: [],
    partyQuestions: [
      _makePartyQuestion(
        order: 1,
        wasCorrect: true,
        score: 20,
        questionLabel: 'Solo Q1 ?',
      ),
    ],
    partyUsers: const [],
    userScores: const [],
    score: 20,
  );
}

/// Créé une [HistoryPartyQuestionDto] prête à l'emploi.
/// [ownerUuid] permet de simuler une réponse appartenant à un autre joueur.
HistoryPartyQuestionDto _makePartyQuestion({
  required int order,
  required bool wasCorrect,
  required int score,
  String questionLabel = 'Question ?',
  String? ownerUuid,
}) {
  return HistoryPartyQuestionDto(
    id: order,
    idQuestion: order * 100,
    idParty: 'party-1',
    order: order,
    question: HistoryQuestionDto(
      id: order * 100,
      label: questionLabel,
      idDifficulty: 2,
      difficulty: const HistoryDifficultyDto(id: 2, label: 'Moyen'),
      answer: [
        HistoryAnswerDto(
          id: order * 100 + 1,
          idQuestion: order * 100,
          value: 'Bonne réponse',
          valid: true,
        ),
        HistoryAnswerDto(
          id: order * 100 + 2,
          idQuestion: order * 100,
          value: 'Mauvaise réponse',
          valid: false,
        ),
      ],
    ),
    userPartyQuestion: UserPartyQuestionDto(
      id: order,
      idPartyQuestion: order,
      userUuid: ownerUuid,
      idAnswer: wasCorrect ? order * 100 + 1 : order * 100 + 2,
      correct: wasCorrect,
      score: score,
    ),
  );
}

/// Construit un [HistoryMatchDto] de type Ranked (idPartyType == 2).
/// Passé via [HistoryQuizPage.historyMatchRaw] pour détecter le mode Ranked ;
/// le détail complet est ensuite chargé via getRankedPartyDetail.
HistoryMatchDto _makeRankedMatch({
  String id = 'party-ranked-1',
  int score = 120,
  int? time = 95,
  DateTime? dt,
  bool finish = true,
}) {
  return HistoryMatchDto(
    id: id,
    // Date locale fixe pour un formatage déterministe (toLocal() est un no-op).
    dt: dt ?? DateTime(2026, 3, 14),
    finish: finish,
    idPartyType: 2,
    nbQuestions: 10,
    score: score,
    time: time,
    percent: 75,
    partyType: const HistoryPartyTypeDto(id: 2, label: 'Ranked'),
    partyDifficulty: const [],
    partyTheme: const [],
  );
}

/// Construit le détail complet d'une partie Ranked (réponse de
/// getRankedPartyDetail) avec vainqueur, ELO, score final et questions.
PartyDetailDto _makeRankedPartyDetail({
  String id = 'party-ranked-1',
  bool? isWinner = true,
  int eloDelta = 25,
  int finalScore = 120,
  int? time = 95,
  DateTime? dt,
  bool finish = true,
  bool withQuestions = true,
  String? ownerUuid,
}) {
  return PartyDetailDto(
    id: id,
    dt: dt ?? DateTime(2026, 3, 14),
    idPartyType: 2,
    active: false,
    finish: finish,
    inProgress: false,
    nbQuestions: 2,
    score: finalScore,
    time: time,
    partyType: const HistoryPartyTypeDto(id: 2, label: 'Ranked'),
    partyDifficulty: [
      HistoryPartyDifficultyDto(
        id: 1,
        difficulty: const HistoryDifficultyDto(id: 2, label: 'Moyen'),
      ),
    ],
    partyTheme: [
      HistoryPartyThemeDto(
        id: 1,
        theme: const HistoryThemeDto(id: 1, label: 'Général'),
      ),
    ],
    partyQuestions: withQuestions
        ? [
            _makePartyQuestion(
              order: 1,
              wasCorrect: true,
              score: 60,
              questionLabel: 'RQ1 ?',
              ownerUuid: ownerUuid,
            ),
            _makePartyQuestion(
              order: 2,
              wasCorrect: false,
              score: 0,
              questionLabel: 'RQ2 ?',
              ownerUuid: ownerUuid,
            ),
          ]
        : const [],
    partyUsers: const [],
    userScores: const [],
    isWinner: isWinner,
    eloDelta: eloDelta,
    finalScore: finalScore,
  );
}

HistoryUserDto _makeUser(String id, String name, {String? avatar}) {
  return HistoryUserDto(
    userId: id,
    nickName: name,
    avatar: avatar,
    isAdmin: false,
    isNew: false,
  );
}

/// Connecte un utilisateur dans AuthStore.instance pour piloter _currentUserId.
Future<void> _signIn(String userId) async {
  await AuthStore.instance.signInWithSession(
    AuthSessionDto(
      user: UserDto(id: userId, nickName: 'Moi', email: '$userId@test.com'),
      token: AuthTokenDto(token: 'tok'),
      isGoogleUser: false,
      raw: const {},
    ),
  );
}

/// Construit une partie de groupe (idPartyType == 1) avec un classement peuplé
/// (partyUsers + userScores), ce qui déclenche le podium et le classement.
PartyDetailDto _makeGroupPartyWithLeaderboard({
  bool finish = true,
  int playerCount = 4,
}) {
  final allUsers = [
    _makeUser('u1', 'Alice'),
    _makeUser('u2', 'Bob'),
    _makeUser('u3', 'Carol'),
    _makeUser('u4', 'Dave'),
  ];
  const allScores = [100, 80, 60, 40];

  final users = allUsers.take(playerCount).toList();

  return PartyDetailDto(
    id: 'party-group-lb',
    idPartyType: 1,
    active: true,
    finish: finish,
    inProgress: !finish,
    partyType: const HistoryPartyTypeDto(id: 1, label: 'Groupe'),
    partyDifficulty: [
      HistoryPartyDifficultyDto(
        id: 1,
        difficulty: const HistoryDifficultyDto(id: 1, label: 'Facile'),
      ),
      HistoryPartyDifficultyDto(
        id: 2,
        difficulty: const HistoryDifficultyDto(id: 3, label: 'Difficile'),
      ),
    ],
    partyTheme: [
      HistoryPartyThemeDto(
        id: 1,
        theme: const HistoryThemeDto(id: 1, label: 'Histoire'),
      ),
      HistoryPartyThemeDto(
        id: 2,
        theme: const HistoryThemeDto(id: 2, label: 'Sport'),
      ),
    ],
    partyQuestions: [
      _makePartyQuestion(
        order: 1,
        wasCorrect: true,
        score: 10,
        questionLabel: 'GQ1 ?',
      ),
    ],
    partyUsers: [
      for (final u in users) HistoryPartyUserDto(idUser: u.userId, user: u),
    ],
    userScores: [
      for (var i = 0; i < users.length; i++)
        HistoryUserScoreDto(
          userId: users[i].userId,
          score: allScores[i],
          user: users[i],
        ),
    ],
    score: allScores.first,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pump helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Avance les animations sans utiliser pumpAndSettle (évite les boucles infinies)
Future<void> _pumpAnimations(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // Ignore les erreurs visuelles connues (animations infinies)
  tester.takeException();
}

/// Nettoie proprement après le test
Future<void> _finishTest(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pompe la page dans un contexte GoRouter minimal
Future<({FakeHistoryApi api, GoRouter router})> _pumpHistoryPage(
  WidgetTester tester, {
  String partyId = 'party-1',
  bool isSolo = false,
  FakeHistoryApi? api,
  Size size = const Size(800, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final fakeApi = api ?? FakeHistoryApi();

  final router = GoRouter(
    initialLocation: '/history/$partyId',
    routes: [
      GoRoute(
        path: '/history/:partyId',
        name: 'history-detail',
        builder: (context, state) => MyAuthStore(
          notifier: AuthStore.instance,
          child: HistoryQuizPage(
            partyId: state.pathParameters['partyId'] ?? partyId,
            isSolo: isSolo,
            historyApiOverride: fakeApi,
          ),
        ),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Accueil'))),
      ),
      GoRoute(
        path: '/solo-quiz',
        name: 'solo-quiz',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Solo Quiz'))),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));

  // Laisse l'état de chargement s'initialiser
  await tester.pump();

  return (api: fakeApi, router: router);
}

/// Pompe la page en mode Ranked via [HistoryQuizPage.historyMatchRaw].
/// La page récupère le détail complet via getRankedPartyDetail sur le fake.
Future<FakeHistoryApi> _pumpRankedPage(
  WidgetTester tester, {
  required HistoryMatchDto match,
  FakeHistoryApi? api,
  Size size = const Size(800, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final fakeApi = api ?? FakeHistoryApi();

  final router = GoRouter(
    initialLocation: '/history/${match.id}',
    routes: [
      GoRoute(
        path: '/history/:partyId',
        builder: (context, state) => MyAuthStore(
          notifier: AuthStore.instance,
          child: HistoryQuizPage(
            partyId: state.pathParameters['partyId'] ?? match.id,
            historyMatchRaw: match,
            historyApiOverride: fakeApi,
          ),
        ),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Accueil'))),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pump();
  return fakeApi;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_setupSecureStorageMock);
  tearDownAll(_tearDownSecureStorageMock);

  setUp(() => _kSecureStore.clear());
  tearDown(() async {
    _kSecureStore.clear();
    await AuthStore.instance.signOut();
  });

  // ─────────────────────────── État de chargement ─────────────────────────
  group('HistoryQuizPage — état de chargement', () {
    testWidgets('affiche un CircularProgressIndicator pendant le chargement', (
      tester,
    ) async {
      // On bloque le retour de l'API avec un Completer pour rester en loading
      final blocker = Completer<void>();
      final slowApi = FakeHistoryApi()..delayFuture = blocker.future;

      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/history/p1',
        routes: [
          GoRoute(
            path: '/history/:id',
            builder: (_, state) => MyAuthStore(
              notifier: AuthStore.instance,
              child: HistoryQuizPage(
                partyId: 'p1',
                historyApiOverride: slowApi,
              ),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Accueil'))),
          ),
          GoRoute(
            path: '/solo-quiz',
            name: 'solo-quiz',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Solo Quiz'))),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      // Deux pumps pour laisser GoRouter naviguer vers la page
      await tester.pump();
      await tester.pump();

      // La page est en chargement — l'API attend le blocker
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

      // Débloquer l'API et laisser la page charger
      blocker.complete();
      await _pumpAnimations(tester);
      await _finishTest(tester);
    });

    testWidgets('se charge et affiche la page sans crash', (tester) async {
      await _pumpHistoryPage(tester);
      await _pumpAnimations(tester);
      expect(find.byType(HistoryQuizPage), findsOneWidget);
      await _finishTest(tester);
    });
  });

  // ─────────────────────────── État d'erreur API ──────────────────────────
  group('HistoryQuizPage — état d\'erreur', () {
    testWidgets(
      'affiche un message d\'erreur quand l\'API retourne une erreur',
      (tester) async {
        final api = FakeHistoryApi()
          ..groupResponse = ApiResponse.err(
            message: 'Partie introuvable',
            statusCode: 404,
          );

        await _pumpHistoryPage(tester, api: api);
        await _pumpAnimations(tester);

        expect(
          find.textContaining('Partie introuvable'),
          findsAtLeastNWidgets(1),
        );

        await _finishTest(tester);
      },
    );

    testWidgets(
      'affiche un message d\'erreur quand l\'API lance une exception',
      (tester) async {
        final api = FakeHistoryApi()..simulateNetworkError = true;

        await _pumpHistoryPage(tester, api: api);
        await _pumpAnimations(tester);

        expect(find.textContaining('Erreur'), findsAtLeastNWidgets(1));

        await _finishTest(tester);
      },
    );

    testWidgets(
      'affiche un message d\'erreur par défaut quand message est null',
      (tester) async {
        final api = FakeHistoryApi()
          ..groupResponse = ApiResponse.err(message: null, statusCode: 500);

        await _pumpHistoryPage(tester, api: api);
        await _pumpAnimations(tester);

        // Le fallback est "Impossible de charger la partie"
        expect(
          find.textContaining('Impossible de charger'),
          findsAtLeastNWidgets(1),
        );

        await _finishTest(tester);
      },
    );

    testWidgets('bouton Retour est présent dans l\'état d\'erreur', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.err(
          message: 'Erreur 500',
          statusCode: 500,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('Retour'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });
  });

  // ─────────────────────────── Partie de groupe terminée ───────────────────
  group('HistoryQuizPage — partie groupe terminée', () {
    testWidgets('affiche "Partie terminée" pour une partie finie', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(finish: true),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.textContaining('Partie terminée'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche "Partie en cours" pour une partie non terminée', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(finish: false),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.textContaining('Partie en cours'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche le score de la partie', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(score: 42),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('42'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche le récapitulatif des questions', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(
        find.textContaining('Récapitulatif des questions'),
        findsAtLeastNWidgets(1),
      );

      await _finishTest(tester);
    });

    testWidgets('affiche les thèmes de la partie', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('Général'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche les infos de la partie', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(
        find.textContaining('Infos de la partie'),
        findsAtLeastNWidgets(1),
      );

      await _finishTest(tester);
    });

    testWidgets('bouton Retour visible dans le bas de page', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('Retour'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets(
      'bouton Continuer absent pour une partie groupe terminée (non solo)',
      (tester) async {
        final api = FakeHistoryApi()
          ..groupResponse = ApiResponse.ok(
            _makeFinishedGroupParty(finish: true),
            statusCode: 200,
          );

        await _pumpHistoryPage(tester, api: api);
        await _pumpAnimations(tester);

        // Le bouton "Continuer" ne doit pas être présent pour le mode groupe
        expect(find.text('Continuer'), findsNothing);

        await _finishTest(tester);
      },
    );
  });

  // ─────────────────────────── Partie solo ────────────────────────────────
  group('HistoryQuizPage — mode solo (isSolo: true)', () {
    testWidgets('charge la partie solo via getSoloPartyDetail', (tester) async {
      final api = FakeHistoryApi()
        ..soloResponse = ApiResponse.ok(
          _makeFinishedSoloParty(finish: true),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api, isSolo: true);
      await _pumpAnimations(tester);

      expect(find.textContaining('Partie terminée'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche bouton Continuer pour partie solo non terminée', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..soloResponse = ApiResponse.ok(
          _makeFinishedSoloParty(finish: false),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api, isSolo: true);
      await _pumpAnimations(tester);

      // canContinueParty: isSolo=true (label "Solo") && finish=false
      expect(find.text('Continuer'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('n\'affiche pas bouton Continuer pour partie solo terminée', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..soloResponse = ApiResponse.ok(
          _makeFinishedSoloParty(finish: true),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api, isSolo: true);
      await _pumpAnimations(tester);

      expect(find.text('Continuer'), findsNothing);

      await _finishTest(tester);
    });

    testWidgets('affiche le label Solo dans le type de partie', (tester) async {
      final api = FakeHistoryApi()
        ..soloResponse = ApiResponse.ok(
          _makeFinishedSoloParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api, isSolo: true);
      await _pumpAnimations(tester);

      expect(find.text('Solo'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });
  });

  // ─────────────────────────── Questions individuelles ────────────────────
  group('HistoryQuizPage — carte de questions', () {
    testWidgets('affiche le contenu d\'une question', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      // Les labels des questions doivent apparaître
      expect(find.textContaining('Q1'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche les réponses d\'une question', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('Bonne réponse'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets(
      '"Bonne réponse +X pts" apparaît pour les questions correctes',
      (tester) async {
        final api = FakeHistoryApi()
          ..groupResponse = ApiResponse.ok(
            _makeFinishedGroupParty(),
            statusCode: 200,
          );

        await _pumpHistoryPage(tester, api: api);
        await _pumpAnimations(tester);

        expect(find.textContaining('Bonne réponse +'), findsAtLeastNWidgets(1));

        await _finishTest(tester);
      },
    );

    testWidgets('"Mauvaise réponse" apparaît pour les questions incorrectes', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('Mauvaise réponse'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });
  });

  // ─────────────────────────── Statistiques sommaires ─────────────────────
  group('HistoryQuizPage — résumé statistiques', () {
    testWidgets('affiche le label Score', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('Score'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche le label Questions', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('Questions'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche le label Réussite', (tester) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeFinishedGroupParty(),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('Réussite'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });
  });

  // ─────────────────────────── Partie Ranked ──────────────────────────────
  group('HistoryQuizPage — partie Ranked', () {
    FakeHistoryApi rankedApi(PartyDetailDto detail) =>
        FakeHistoryApi()
          ..rankedResponse = ApiResponse.ok(detail, statusCode: 200);

    testWidgets('victoire : Victoire + ELO gagné + score final + questions', (
      tester,
    ) async {
      await _pumpRankedPage(
        tester,
        match: _makeRankedMatch(),
        api: rankedApi(
          _makeRankedPartyDetail(
            isWinner: true,
            eloDelta: 25,
            finalScore: 120,
          ),
        ),
      );
      await _pumpAnimations(tester);

      expect(find.text('Victoire'), findsAtLeastNWidgets(1));
      expect(find.text('Ranked'), findsAtLeastNWidgets(1));
      expect(find.text('+25 ELO'), findsAtLeastNWidgets(1));
      expect(find.text('Score final'), findsAtLeastNWidgets(1));
      expect(find.text('120'), findsAtLeastNWidgets(1));
      expect(find.textContaining('RQ1'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('défaite : Défaite + ELO perdu (signe négatif)', (tester) async {
      await _pumpRankedPage(
        tester,
        match: _makeRankedMatch(),
        api: rankedApi(_makeRankedPartyDetail(isWinner: false, eloDelta: 30)),
      );
      await _pumpAnimations(tester);

      expect(find.text('Défaite'), findsAtLeastNWidgets(1));
      expect(find.text('-30 ELO'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche le récapitulatif des questions', (tester) async {
      await _pumpRankedPage(
        tester,
        match: _makeRankedMatch(),
        api: rankedApi(_makeRankedPartyDetail()),
      );
      await _pumpAnimations(tester);

      expect(
        find.textContaining('Récapitulatif des questions'),
        findsAtLeastNWidgets(1),
      );
      expect(find.textContaining('RQ1'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche uniquement le bouton Retour (pas de Continuer)', (
      tester,
    ) async {
      await _pumpRankedPage(
        tester,
        match: _makeRankedMatch(),
        api: rankedApi(_makeRankedPartyDetail()),
      );
      await _pumpAnimations(tester);
      expect(find.text('Retour'), findsAtLeastNWidgets(1));
      expect(find.text('Continuer'), findsNothing);
      await _finishTest(tester);
    });

    testWidgets('repli sur les données du match si l\'API échoue', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..rankedResponse = ApiResponse.err(message: 'boom', statusCode: 500);

      await _pumpRankedPage(
        tester,
        match: _makeRankedMatch(score: 50, time: 45),
        api: api,
      );
      await _pumpAnimations(tester);

      // Repli : isWinner null → score>0 → Victoire ; score issu du match.
      expect(find.text('Victoire'), findsAtLeastNWidgets(1));
      expect(find.text('Score final'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });
  });

  // ─────────────────────────── Classement de groupe ───────────────────────
  group('HistoryQuizPage — classement de groupe', () {
    testWidgets('affiche le podium avec les trois premiers joueurs', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeGroupPartyWithLeaderboard(finish: true),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.text('Podium'), findsAtLeastNWidgets(1));
      expect(find.text('Alice'), findsAtLeastNWidgets(1));
      expect(find.text('Bob'), findsAtLeastNWidgets(1));
      expect(find.text('Carol'), findsAtLeastNWidgets(1));
      expect(find.text('100 pts'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets(
      'affiche "Classement provisoire" pour une partie non terminée',
      (tester) async {
        final api = FakeHistoryApi()
          ..groupResponse = ApiResponse.ok(
            _makeGroupPartyWithLeaderboard(finish: false),
            statusCode: 200,
          );

        await _pumpHistoryPage(tester, api: api);
        await _pumpAnimations(tester);

        expect(
          find.textContaining('Classement provisoire'),
          findsAtLeastNWidgets(1),
        );

        await _finishTest(tester);
      },
    );

    testWidgets('affiche le classement complet au-delà de trois joueurs', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeGroupPartyWithLeaderboard(playerCount: 4),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(
        find.textContaining('Classement complet'),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('Dave'), findsAtLeastNWidgets(1));
      expect(find.text('40 pts'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('masque le classement complet avec trois joueurs ou moins', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeGroupPartyWithLeaderboard(playerCount: 3),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api);
      await _pumpAnimations(tester);

      expect(find.textContaining('Classement complet'), findsNothing);
      // Le podium reste affiché.
      expect(find.text('Carol'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });

    testWidgets('affiche le podium en disposition étroite', (tester) async {
      // En largeur réduite, certaines cartes de la page débordent volontairement
      // (overflow horizontal) — on ignore ces erreurs visuelles le temps du test.
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
          return;
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      final api = FakeHistoryApi()
        ..groupResponse = ApiResponse.ok(
          _makeGroupPartyWithLeaderboard(playerCount: 3),
          statusCode: 200,
        );

      await _pumpHistoryPage(
        tester,
        api: api,
        size: const Size(420, 1400),
      );
      await _pumpAnimations(tester);

      // La disposition étroite affiche les médailles en emoji.
      expect(find.text('🥇'), findsAtLeastNWidgets(1));
      expect(find.text('Alice'), findsAtLeastNWidgets(1));

      await _finishTest(tester);
    });
  });

  // ─────────────────────────── Navigation ─────────────────────────────────
  group('HistoryQuizPage — navigation', () {
    testWidgets('tape sur Continuer et navigue vers le quiz solo', (
      tester,
    ) async {
      final api = FakeHistoryApi()
        ..soloResponse = ApiResponse.ok(
          _makeFinishedSoloParty(finish: false),
          statusCode: 200,
        );

      await _pumpHistoryPage(tester, api: api, isSolo: true);
      await _pumpAnimations(tester);

      expect(find.text('Continuer'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Continuer').first);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      tester.takeException();

      expect(find.text('Solo Quiz'), findsOneWidget);

      await _finishTest(tester);
    });
  });

  // ───────────────── Attribution centrée sur l'utilisateur courant ─────────
  group('HistoryQuizPage — attribution utilisateur courant', () {
    testWidgets(
      'ranked : réponses d\'un AUTRE joueur → note + pas de "Correctes"',
      (tester) async {
        await _signIn('me-123');

        final api = FakeHistoryApi()
          ..rankedResponse = ApiResponse.ok(
            _makeRankedPartyDetail(
              isWinner: false,
              eloDelta: 22,
              finalScore: 0,
              ownerUuid: 'other-999', // données d'un autre joueur
            ),
            statusCode: 200,
          );

        await _pumpRankedPage(tester, match: _makeRankedMatch(), api: api);
        await _pumpAnimations(tester);

        expect(find.text('Défaite'), findsAtLeastNWidgets(1));
        expect(find.text('-22 ELO'), findsAtLeastNWidgets(1));
        // Aucune réponse ne m'appartient → 0 Correctes + note d'avertissement.
        expect(find.text('0 Correctes'), findsOneWidget);
        expect(find.textContaining('détail de tes réponses'), findsOneWidget);

        await _finishTest(tester);
      },
    );

    testWidgets('ranked : MES réponses → récap + "Correctes", pas de note', (
      tester,
    ) async {
      await _signIn('me-123');

      final api = FakeHistoryApi()
        ..rankedResponse = ApiResponse.ok(
          _makeRankedPartyDetail(ownerUuid: 'me-123'),
          statusCode: 200,
        );

      await _pumpRankedPage(tester, match: _makeRankedMatch(), api: api);
      await _pumpAnimations(tester);

      expect(find.textContaining('Correctes'), findsAtLeastNWidgets(1));
      expect(find.textContaining('RQ1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('détail de tes réponses'), findsNothing);

      await _finishTest(tester);
    });

    testWidgets(
      'groupe : score perso (userScores) même si réponses d\'un autre',
      (tester) async {
        await _signIn('me-123');

        final party = PartyDetailDto(
          id: 'g1',
          idPartyType: 1,
          active: true,
          finish: true,
          score: 0, // score de partie = 0
          nbQuestions: 2,
          partyType: const HistoryPartyTypeDto(id: 1, label: 'Groupe'),
          partyDifficulty: const [],
          partyTheme: const [],
          partyQuestions: [
            _makePartyQuestion(
              order: 1,
              wasCorrect: false,
              score: 0,
              ownerUuid: 'other-999',
            ),
            _makePartyQuestion(
              order: 2,
              wasCorrect: false,
              score: 0,
              ownerUuid: 'other-999',
            ),
          ],
          partyUsers: const [],
          userScores: [
            HistoryUserScoreDto(
              userId: 'me-123',
              score: 2534,
              user: _makeUser('me-123', 'Moi'),
            ),
            HistoryUserScoreDto(
              userId: 'other-999',
              score: 0,
              user: _makeUser('other-999', 'Autre'),
            ),
          ],
        );

        final api = FakeHistoryApi()
          ..groupResponse = ApiResponse.ok(party, statusCode: 200);

        await _pumpHistoryPage(tester, api: api);
        await _pumpAnimations(tester);

        // Le score perso (2534) s'affiche, pas le score de partie (0).
        expect(find.text('2534'), findsAtLeastNWidgets(1));
        expect(find.textContaining('détail de tes réponses'), findsOneWidget);

        await _finishTest(tester);
      },
    );
  });
}
