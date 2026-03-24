import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/solo/solo_api_service.dart';
import 'package:tuuuur_flutter/api/solo/solo_models.dart';
import 'package:tuuuur_flutter/pages/solo/solo_quiz_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 20),
  int maxSteps = 400,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timeout: widget not found: $finder');
}

Future<void> finishTest(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

enum FakeSoloMode {
  happyTwoQuestions,
  timerOneQuestion,
  unauthorizedOnCreate,
  reloadOnNext,
}

class FakeSoloApi extends SoloApi {
  FakeSoloApi(this.mode) : super(ApiClient(baseUrl: 'http://localhost'));

  final FakeSoloMode mode;

  int getSoloCalls = 0;
  int answerCalls = 0;
  int? lastAnswerId;

  static const int q1Correct = 11;
  static const int q1Wrong = 12;
  static const int q2Correct = 21;
  static const int q2Wrong = 22;

  @override
  Future<ApiResponse<SoloCreateResult>> createSolo({
    required List<int> themeIds,
    required List<int> difficultyIds,
    required int nbQuestions,
    Map<String, String>? headers,
  }) async {
    if (mode == FakeSoloMode.unauthorizedOnCreate) {
      return ApiResponse.err(
        statusCode: 401,
        message: 'Unauthorized',
        raw: null,
      );
    }
    return ApiResponse.ok(
      const SoloCreateResult(partyId: 'p1'),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<SoloPartyDto>> getSolo({
    required String partyId,
    Map<String, String>? headers,
  }) async {
    getSoloCalls++;

    switch (mode) {
      case FakeSoloMode.timerOneQuestion:
        return ApiResponse.ok(_partyInitialOne(), statusCode: 200);

      case FakeSoloMode.reloadOnNext:
        if (getSoloCalls == 1) {
          return ApiResponse.ok(_partyInitialTwo(), statusCode: 200);
        }
        return ApiResponse.ok(
          _partyAfterQ1Answered(withQ2Pending: true),
          statusCode: 200,
        );

      case FakeSoloMode.happyTwoQuestions:
      case FakeSoloMode.unauthorizedOnCreate:
        return ApiResponse.ok(_partyInitialTwo(), statusCode: 200);
    }
  }

  @override
  Future<ApiResponse<SoloPartyDto>> answerSolo({
    required String partyId,
    required int answerId,
    Map<String, String>? headers,
  }) async {
    answerCalls++;
    lastAnswerId = answerId;

    switch (mode) {
      case FakeSoloMode.timerOneQuestion:
        return ApiResponse.ok(
          _partyFinishedOne(answerId: answerId),
          statusCode: 200,
        );

      case FakeSoloMode.reloadOnNext:
        return ApiResponse.ok(
          _partyAfterQ1Answered(withQ2Pending: false),
          statusCode: 200,
        );

      case FakeSoloMode.happyTwoQuestions:
      case FakeSoloMode.unauthorizedOnCreate:
        if (answerCalls == 1) {
          return ApiResponse.ok(
            _partyAfterQ1Answered(withQ2Pending: true, q1AnswerId: answerId),
            statusCode: 200,
          );
        }
        return ApiResponse.ok(
          _partyFinishedTwo(q2AnswerId: answerId),
          statusCode: 200,
        );
    }
  }

  SoloPartyDto _partyInitialOne() {
    return SoloPartyDto(
      id: 'p1',
      finish: false,
      score: 0,
      nbQuestions: 1,
      partyQuestions: [
        _pq(
          partyQuestionId: 1001,
          order: 1,
          question: _q1(withValidity: false),
          user: null,
        ),
      ],
    );
  }

  SoloPartyDto _partyFinishedOne({required int answerId}) {
    final correct = answerId == q1Correct;
    final pts = correct ? 10 : 0;

    return SoloPartyDto(
      id: 'p1',
      finish: true,
      score: pts,
      nbQuestions: 1,
      partyQuestions: [
        _pq(
          partyQuestionId: 1001,
          order: 1,
          question: _q1(withValidity: true),
          user: _userAnswer(
            partyQuestionId: 1001,
            answerId: answerId,
            correct: correct,
            score: pts,
          ),
        ),
      ],
    );
  }

  SoloPartyDto _partyInitialTwo() {
    return SoloPartyDto(
      id: 'p1',
      finish: false,
      score: 0,
      nbQuestions: 2,
      partyQuestions: [
        _pq(
          partyQuestionId: 1001,
          order: 1,
          question: _q1(withValidity: false),
          user: null,
        ),
        _pq(
          partyQuestionId: 1002,
          order: 2,
          question: _q2(withValidity: false),
          user: null,
        ),
      ],
    );
  }

  SoloPartyDto _partyAfterQ1Answered({
    required bool withQ2Pending,
    int q1AnswerId = q1Correct,
  }) {
    final q1IsCorrect = q1AnswerId == q1Correct;
    final pts1 = q1IsCorrect ? 10 : 0;

    final pqs = <SoloPartyQuestionDto>[
      _pq(
        partyQuestionId: 1001,
        order: 1,
        question: _q1(withValidity: true),
        user: _userAnswer(
          partyQuestionId: 1001,
          answerId: q1AnswerId,
          correct: q1IsCorrect,
          score: pts1,
        ),
      ),
    ];

    if (withQ2Pending) {
      pqs.add(
        _pq(
          partyQuestionId: 1002,
          order: 2,
          question: _q2(withValidity: false),
          user: null,
        ),
      );
    }

    return SoloPartyDto(
      id: 'p1',
      finish: false,
      score: pts1,
      nbQuestions: 2,
      partyQuestions: pqs,
    );
  }

  SoloPartyDto _partyFinishedTwo({required int q2AnswerId}) {
    const pts1 = 10;

    final q2IsCorrect = q2AnswerId == q2Correct;
    final pts2 = q2IsCorrect ? 7 : 0;

    return SoloPartyDto(
      id: 'p1',
      finish: true,
      score: pts1 + pts2,
      nbQuestions: 2,
      partyQuestions: [
        _pq(
          partyQuestionId: 1001,
          order: 1,
          question: _q1(withValidity: true),
          user: _userAnswer(
            partyQuestionId: 1001,
            answerId: q1Correct,
            correct: true,
            score: pts1,
          ),
        ),
        _pq(
          partyQuestionId: 1002,
          order: 2,
          question: _q2(withValidity: true),
          user: _userAnswer(
            partyQuestionId: 1002,
            answerId: q2AnswerId,
            correct: q2IsCorrect,
            score: pts2,
          ),
        ),
      ],
    );
  }

  SoloPartyQuestionDto _pq({
    required int partyQuestionId,
    required int order,
    required SoloQuestionDto question,
    required SoloUserPartyQuestionDto? user,
  }) {
    return SoloPartyQuestionDto(
      id: partyQuestionId,
      questionId: question.id,
      partyId: 'p1',
      order: order,
      question: question,
      userAnswer: user,
    );
  }

  SoloUserPartyQuestionDto _userAnswer({
    required int partyQuestionId,
    required int answerId,
    required bool correct,
    required int score,
  }) {
    return SoloUserPartyQuestionDto(
      id: 9000 + partyQuestionId,
      partyQuestionId: partyQuestionId,
      userId: 1,
      dtPresentedAt: DateTime.now().subtract(const Duration(seconds: 3)),
      dtAnsweredAt: DateTime.now(),
      answerId: answerId,
      correct: correct,
      score: score,
      answersOrderRaw: null,
    );
  }

  SoloQuestionDto _q1({required bool withValidity}) {
    return SoloQuestionDto(
      id: 501,
      label: 'Q1: capitale de la France ?',
      difficultyId: 1,
      difficultyLabel: 'Facile',
      answers: [
        SoloAnswerDto(
          id: q1Correct,
          questionId: 501,
          value: 'Paris',
          valid: withValidity ? true : null,
        ),
        SoloAnswerDto(
          id: q1Wrong,
          questionId: 501,
          value: 'Lyon',
          valid: withValidity ? false : null,
        ),
      ],
    );
  }

  SoloQuestionDto _q2({required bool withValidity}) {
    return SoloQuestionDto(
      id: 502,
      label: 'Q2: 2 + 2 = ?',
      difficultyId: 1,
      difficultyLabel: 'Facile',
      answers: [
        SoloAnswerDto(
          id: q2Correct,
          questionId: 502,
          value: '4',
          valid: withValidity ? true : null,
        ),
        SoloAnswerDto(
          id: q2Wrong,
          questionId: 502,
          value: '5',
          valid: withValidity ? false : null,
        ),
      ],
    );
  }
}

Future<void> pumpSoloQuizPage(
  WidgetTester tester, {
  required SoloApi api,
  int questions = 2,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyAuthStore(
        notifier: AuthStore.instance,
        child: SoloQuizPage(
          categories: const ['1'],
          questions: questions,
          difficulties: const [1],
          soloApiOverride: api,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final Map<String, String> secureStore = <String, String>{};

  setUpAll(() async {
    secureStorageChannel.setMockMethodCallHandler((MethodCall call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'write':
          final key = args['key'] as String?;
          final value = args['value'] as String?;
          if (key != null && value != null) secureStore[key] = value;
          return null;
        case 'read':
          final key = args['key'] as String?;
          return key == null ? null : secureStore[key];
        case 'delete':
          final key = args['key'] as String?;
          if (key != null) secureStore.remove(key);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(secureStore);
        case 'containsKey':
          final key = args['key'] as String?;
          return key != null && secureStore.containsKey(key);
        default:
          return null;
      }
    });
  });

  tearDownAll(() async {
    secureStorageChannel.setMockMethodCallHandler(null);
  });

  setUp(() async {
    secureStore.clear();
    await AuthStore.instance.signOut();
  });

  tearDown(() async {
    secureStore.clear();
    await AuthStore.instance.signOut();
  });

  group('SoloQuizPage', () {
    testWidgets('happy path: Q1 correct -> Suivant -> Q2 wrong -> Terminer', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      final api = FakeSoloApi(FakeSoloMode.happyTwoQuestions);

      await pumpSoloQuizPage(tester, api: api, questions: 2);

      await pumpUntilFound(tester, find.text('Paris'));
      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('Lyon'), findsOneWidget);
      expect(find.textContaining('Score: 0'), findsOneWidget);
      expect(find.textContaining('Question'), findsWidgets);

      expect(find.text('Passer'), findsOneWidget);
      expect(find.text('Suivant'), findsNothing);

      await tester.tap(find.text('Paris'));
      await tester.pump();

      await pumpUntilFound(tester, find.textContaining('Correct +'));
      expect(find.textContaining('Correct +'), findsOneWidget);

      expect(find.text('Suivant'), findsOneWidget);
      expect(find.text('Passer'), findsNothing);

      await tester.tap(find.text('Suivant'));
      await tester.pump();

      await pumpUntilFound(tester, find.text('4'));
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.text('5'));
      await tester.pump();

      await pumpUntilFound(tester, find.text('Mauvaise réponse'));
      expect(find.text('Mauvaise réponse'), findsOneWidget);

      expect(find.text('Terminer'), findsOneWidget);

      await tester.tap(find.text('Terminer'));
      await tester.pump();

      await pumpUntilFound(tester, find.text('Terminé !'));
      expect(find.text('Terminé !'), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('timer: expiration -> auto-submit answerId=0 -> Terminer', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      final api = FakeSoloApi(FakeSoloMode.timerOneQuestion);

      await pumpSoloQuizPage(tester, api: api, questions: 1);

      await pumpUntilFound(tester, find.text('Paris'));
      expect(find.text('Passer'), findsOneWidget);

      await tester.pump(const Duration(seconds: 16));
      await tester.pump();

      expect(api.lastAnswerId, 0);

      await pumpUntilFound(tester, find.text('Mauvaise réponse'));
      expect(find.text('Mauvaise réponse'), findsOneWidget);
      expect(find.text('Terminer'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('createSolo 401 -> carte erreur + bouton "Se connecter"', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      final api = FakeSoloApi(FakeSoloMode.unauthorizedOnCreate);

      await pumpSoloQuizPage(tester, api: api, questions: 2);

      await pumpUntilFound(tester, find.text('Erreur'));
      expect(find.text('Erreur'), findsOneWidget);
      expect(find.text('↻ Réessayer'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets(
      'si answerSolo ne renvoie pas la prochaine question -> "Suivant" déclenche _reloadParty()',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 800));
        addTearDown(() async => tester.binding.setSurfaceSize(null));

        final api = FakeSoloApi(FakeSoloMode.reloadOnNext);

        await pumpSoloQuizPage(tester, api: api, questions: 2);

        await pumpUntilFound(tester, find.text('Paris'));

        await tester.tap(find.text('Paris'));
        await tester.pump();

        await pumpUntilFound(tester, find.textContaining('Correct +'));
        expect(find.text('Suivant'), findsOneWidget);

        final beforeCalls = api.getSoloCalls;

        await tester.tap(find.text('Suivant'));
        await tester.pump();

        await pumpUntilFound(tester, find.text('4'));
        expect(find.text('4'), findsOneWidget);

        expect(api.getSoloCalls, greaterThan(beforeCalls));

        await finishTest(tester);
      },
    );
  });
}
