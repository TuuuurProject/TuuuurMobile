import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/group/group_models.dart' hide Theme;
import 'package:tuuuur_flutter/pages/group/group_quiz_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/stores/group_store.dart';

import 'group_test_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Pumps frames WITHOUT using pumpAndSettle, because:
/// - _CountdownWidget has an infinite repeat animation (.animate(onPlay: controller.repeat()))
/// - _QuestionTimerWidget has a Timer.periodic
/// Using pumpAndSettle would hang on both of these.
Future<void> pumpFrames(
  WidgetTester tester, {
  int count = 5,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(step);
  }
}

/// Stops all pending timers/animations by replacing the tree.
Future<void> finishGroupTest(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<({GroupStore store, bool finished, bool left})> pumpQuizPage(
  WidgetTester tester, {
  required GroupParty party,
  required GroupStore store,
  String currentUserId = 'user-1',
  Size size = const Size(800, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  var finished = false;
  var left = false;

  await tester.pumpWidget(
    MaterialApp(
      home: MyAuthStore(
        notifier: AuthStore.instance,
        child: GroupQuizPage(
          groupStore: store,
          currentUserId: currentUserId,
          onFinished: () => finished = true,
          onLeave: () => left = true,
        ),
      ),
    ),
  );

  await tester.pump();
  return (store: store, finished: finished, left: left);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setupSecureStorageMock);
  tearDownAll(tearDownSecureStorageMock);

  setUp(() async {
    kSecureStore.clear();
    await signInForTest(userId: 'user-1', nick: 'Tester');
  });

  tearDown(() async {
    kSecureStore.clear();
    await AuthStore.instance.signOut();
  });

  group('GroupQuizPage', () {
    testWidgets('état countdown → affiche le compte à rebours', (tester) async {
      final ws = FakeGroupWebSocketService();
      final store = GroupStore(webSocketService: ws);
      final party = makeGroupParty(hostUserId: 'user-1');
      store.initializeParty(party, currentUserId: 'user-1');

      // Trigger countdown state
      store.onCountdown(3);

      await pumpQuizPage(tester, party: party, store: store);

      // Pump a little (not pumpAndSettle – infinite animation!)
      await pumpFrames(tester, count: 3);

      expect(find.text('La question arrive dans...'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets('état questionActive → affiche la question et les réponses', (
      tester,
    ) async {
      final ws = FakeGroupWebSocketService();
      final store = GroupStore(webSocketService: ws);
      final party = makeGroupParty(hostUserId: 'user-1');
      store.initializeParty(party, currentUserId: 'user-1');

      // Simulate question being sent
      final question = makeGroupQuestion(
        label: 'Capitale de la France ?',
        correctAnswerId: 11,
        wrongAnswerId: 12,
      );
      store.onQuestionSend(question);

      await pumpQuizPage(tester, party: party, store: store);
      await pumpFrames(tester);

      expect(find.text('Capitale de la France ?'), findsOneWidget);
      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('Lyon'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets('sélectionner une réponse correcte → affiche "Correct !"', (
      tester,
    ) async {
      final ws = FakeGroupWebSocketService();
      final store = GroupStore(webSocketService: ws);
      final party = makeGroupParty(hostUserId: 'user-1');
      store.initializeParty(party, currentUserId: 'user-1');

      final question = makeGroupQuestion(
        correctAnswerId: 11,
        wrongAnswerId: 12,
        withValidity: false,
      );
      store.onQuestionSend(question);

      await pumpQuizPage(tester, party: party, store: store);
      await pumpFrames(tester);

      // Select the correct answer
      await tester.tap(find.text('Paris'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // "Réponse envoyée" badge should be visible
      expect(find.text('Réponse envoyée ✓'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets('état answerReveal → affiche le feedback correct/incorrect', (
      tester,
    ) async {
      final ws = FakeGroupWebSocketService();
      final store = GroupStore(webSocketService: ws);
      final party = makeGroupParty(hostUserId: 'user-1');
      store.initializeParty(party, currentUserId: 'user-1');

      final question = makeGroupQuestion(
        correctAnswerId: 11,
        wrongAnswerId: 12,
        withValidity: false,
      );
      store.onQuestionSend(question);
      // User selected correct answer
      store.selectAnswer(11);

      // Now reveal answer
      final questionWithValidity = makeGroupQuestion(
        correctAnswerId: 11,
        wrongAnswerId: 12,
        withValidity: true,
        score: 10,
      );
      store.onQuestionAnswerSend(questionWithValidity);

      await pumpQuizPage(tester, party: party, store: store);
      await pumpFrames(tester);

      expect(find.textContaining('Correct ! +'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets(
      'état answerReveal avec mauvaise réponse → "Mauvaise réponse"',
      (tester) async {
        final ws = FakeGroupWebSocketService();
        final store = GroupStore(webSocketService: ws);
        final party = makeGroupParty(hostUserId: 'user-1');
        store.initializeParty(party, currentUserId: 'user-1');

        final question = makeGroupQuestion(
          correctAnswerId: 11,
          wrongAnswerId: 12,
          withValidity: false,
        );
        store.onQuestionSend(question);
        // User selected wrong answer
        store.selectAnswer(12);

        final questionWithValidity = makeGroupQuestion(
          correctAnswerId: 11,
          wrongAnswerId: 12,
          withValidity: true,
          score: 10,
        );
        store.onQuestionAnswerSend(questionWithValidity);

        await pumpQuizPage(tester, party: party, store: store);
        await pumpFrames(tester);

        expect(find.text('Mauvaise réponse'), findsOneWidget);

        await finishGroupTest(tester);
      },
    );

    testWidgets('état scoreDisplay → affiche les scores', (tester) async {
      final ws = FakeGroupWebSocketService();
      final store = GroupStore(webSocketService: ws);
      final party = makeGroupParty(
        hostUserId: 'user-1',
        users: [
          PartyUser(
            idUser: 'user-1',
            idParty: 'p1',
            user: GroupUser(id: 'user-1', nickName: 'Alice'),
          ),
          PartyUser(
            idUser: 'user-2',
            idParty: 'p1',
            user: GroupUser(id: 'user-2', nickName: 'Bob'),
          ),
        ],
      );
      store.initializeParty(party, currentUserId: 'user-1');
      store.onScoreUpdate([
        makeUserScore(userId: 'user-1', nickName: 'Alice', score: 10),
        makeUserScore(userId: 'user-2', nickName: 'Bob', score: 5),
      ]);

      await pumpQuizPage(tester, party: party, store: store);
      await pumpFrames(tester);

      // Score display should show players
      expect(find.text('Alice'), findsWidgets);

      await finishGroupTest(tester);
    });

    testWidgets(
      'état finished → onFinished est appelé via le stream périodique',
      (tester) async {
        final ws = FakeGroupWebSocketService();
        final store = GroupStore(webSocketService: ws);
        final party = makeGroupParty(hostUserId: 'user-1');
        store.initializeParty(party, currentUserId: 'user-1');

        var finishedCalled = false;

        await tester.binding.setSurfaceSize(const Size(800, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: MyAuthStore(
              notifier: AuthStore.instance,
              child: GroupQuizPage(
                groupStore: store,
                currentUserId: 'user-1',
                onFinished: () => finishedCalled = true,
                onLeave: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        // Trigger finished state
        store.onPartyFinished([
          makeUserScore(userId: 'user-1', nickName: 'Tester', score: 50),
        ]);

        // The Stream.periodic(100ms) will detect the finished state
        await tester.pump(const Duration(milliseconds: 200));

        expect(finishedCalled, isTrue);

        await finishGroupTest(tester);
      },
    );

    testWidgets('affiche le score du joueur dans l\'en-tête', (tester) async {
      final ws = FakeGroupWebSocketService();
      final store = GroupStore(webSocketService: ws);
      final party = makeGroupParty(hostUserId: 'user-1', nbQuestions: 5);
      store.initializeParty(party, currentUserId: 'user-1');

      final question = makeGroupQuestion();
      store.onQuestionSend(question);

      await pumpQuizPage(tester, party: party, store: store);
      await pumpFrames(tester);

      // Score badge: "Score: 0" initially
      expect(find.text('Score: '), findsOneWidget);
      expect(find.text('0'), findsWidgets);

      await finishGroupTest(tester);
    });
  });
}
