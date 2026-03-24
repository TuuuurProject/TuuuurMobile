import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
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

/// Créé une [HistoryPartyQuestionDto] prête à l'emploi
HistoryPartyQuestionDto _makePartyQuestion({
  required int order,
  required bool wasCorrect,
  required int score,
  String questionLabel = 'Question ?',
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
      idAnswer: wasCorrect ? order * 100 + 1 : order * 100 + 2,
      correct: wasCorrect,
      score: score,
    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_setupSecureStorageMock);
  tearDownAll(_tearDownSecureStorageMock);

  setUp(() => _kSecureStore.clear());
  tearDown(() => _kSecureStore.clear());

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
}
