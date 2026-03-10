import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/group/group_models.dart' hide Theme;
import 'package:tuuuur_flutter/pages/group/group_results_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';

import 'group_test_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> pumpAnimations(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // Consume any pending FlutterError from the known production-code bug:
  // _buildPodiumSlot uses BoxDecoration(borderRadius + non-uniform Border)
  // which fires a paint-time assertion in Flutter debug mode.
  tester.takeException();
}

Future<void> finishGroupTest(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> pumpResultsPage(
  WidgetTester tester, {
  required List<UserScore> finalScores,
  required String currentUserId,
  String partyCode = '123456',
  List<QuestionHistory> questionsHistory = const [],
  Size size = const Size(800, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: MyAuthStore(
        notifier: AuthStore.instance,
        child: GroupResultsPage(
          finalScores: finalScores,
          currentUserId: currentUserId,
          partyCode: partyCode,
          questionsHistory: questionsHistory,
        ),
      ),
    ),
  );

  await tester.pump();
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

  group('GroupResultsPage', () {
    testWidgets('affiche le titre "Partie terminée !"', (tester) async {
      await pumpResultsPage(
        tester,
        finalScores: [
          makeUserScore(userId: 'user-2', nickName: 'Winner', score: 200),
          makeUserScore(userId: 'user-1', nickName: 'Tester', score: 100),
        ],
        currentUserId: 'user-1',
      );
      await pumpAnimations(tester);

      expect(find.text('Partie terminée !'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets('affiche le podium avec un joueur', (tester) async {
      await pumpResultsPage(
        tester,
        finalScores: [
          makeUserScore(userId: 'user-1', nickName: 'Solo', score: 50),
        ],
        currentUserId: 'user-1',
      );
      await pumpAnimations(tester);

      expect(find.text('Podium'), findsOneWidget);
      expect(find.text('Solo'), findsOneWidget);
      expect(find.text('50 pts'), findsWidgets);

      await finishGroupTest(tester);
    });

    testWidgets('affiche le résumé de l\'utilisateur courant', (tester) async {
      // user-1 at rank 4 (not top 3) → shows "Votre résultat" not "Félicitations !"
      await pumpResultsPage(
        tester,
        finalScores: [
          makeUserScore(userId: 'u-a', nickName: 'First', score: 500),
          makeUserScore(userId: 'u-b', nickName: 'Second', score: 400),
          makeUserScore(userId: 'u-c', nickName: 'Third', score: 300),
          makeUserScore(userId: 'user-1', nickName: 'Tester', score: 150),
        ],
        currentUserId: 'user-1',
        questionsHistory: [
          makeQuestionHistory(wasCorrect: true, scoreGained: 10),
          makeQuestionHistory(wasCorrect: false, scoreGained: 0),
        ],
      );
      await pumpAnimations(tester);

      expect(find.text('Votre résultat'), findsOneWidget);
      expect(find.text('Classement'), findsOneWidget);
      expect(find.text('Score'), findsWidgets);

      await finishGroupTest(tester);
    });

    testWidgets(
        'utilisateur au top 3 → affiche "Félicitations !"', (tester) async {
      // Pump with a short timeout to avoid hanging on confetti animation
      await pumpResultsPage(
        tester,
        finalScores: [
          makeUserScore(userId: 'user-1', nickName: 'Tester', score: 300),
          makeUserScore(userId: 'user-2', nickName: 'Other', score: 100),
        ],
        currentUserId: 'user-1',
      );
      await pumpAnimations(tester);

      expect(find.text('Félicitations !'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets('affiche le classement complet avec 4+ joueurs', (tester) async {
      await pumpResultsPage(
        tester,
        finalScores: [
          makeUserScore(userId: 'u1', nickName: 'First', score: 400),
          makeUserScore(userId: 'u2', nickName: 'Second', score: 300),
          makeUserScore(userId: 'u3', nickName: 'Third', score: 200),
          makeUserScore(userId: 'user-1', nickName: 'Tester', score: 100),
        ],
        currentUserId: 'user-1',
      );
      await pumpAnimations(tester);

      expect(find.text('Classement complet'), findsOneWidget);
      expect(find.text('Tester'), findsWidgets);

      await finishGroupTest(tester);
    });

    testWidgets(
        'affiche le récapitulatif des questions quand historyPresent',
        (tester) async {
      await pumpResultsPage(
        tester,
        finalScores: [
          makeUserScore(userId: 'user-1', nickName: 'Tester', score: 10),
        ],
        currentUserId: 'user-1',
        questionsHistory: [
          makeQuestionHistory(
            wasCorrect: true,
            scoreGained: 10,
            questionLabel: 'Quelle est la capitale de la France ?',
          ),
          makeQuestionHistory(
            wasCorrect: false,
            scoreGained: 0,
            userAnswerId: 12,
            questionLabel: 'Combien font 2+2 ?',
          ),
        ],
      );
      await pumpAnimations(tester);

      expect(find.text('Récapitulatif des questions'), findsOneWidget);
      expect(
        find.text('Quelle est la capitale de la France ?'),
        findsWidgets,
      );

      await finishGroupTest(tester);
    });

    testWidgets('affiche le bouton "Retour au lobby"', (tester) async {
      await pumpResultsPage(
        tester,
        finalScores: [
          makeUserScore(userId: 'user-1', nickName: 'Tester', score: 50),
        ],
        currentUserId: 'user-1',
      );
      await pumpAnimations(tester);

      expect(find.text('Retour au lobby'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets(
        'pas de résumé utilisateur si userId absent des scores',
        (tester) async {
      await pumpResultsPage(
        tester,
        finalScores: [
          makeUserScore(userId: 'user-2', nickName: 'Other', score: 50),
        ],
        currentUserId: 'user-1',
      );
      await pumpAnimations(tester);

      // No personal summary card
      expect(find.text('Votre résultat'), findsNothing);
      expect(find.text('Félicitations !'), findsNothing);

      await finishGroupTest(tester);
    });
  });
}
