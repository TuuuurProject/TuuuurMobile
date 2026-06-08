import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_quiz_view.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_models.dart';
import 'package:tuuuur_flutter/widgets/gaming_widgets.dart';

class MockRankedStore extends Mock implements RankedStore {}

void main() {
  late MockRankedStore mockRankedStore;

  setUp(() {
    mockRankedStore = MockRankedStore();

    when(() => mockRankedStore.state).thenReturn(RankedGameState.questionActive);
    when(() => mockRankedStore.opponent).thenReturn(const RankedUser(id: '1', nickName: 'P1', isGoogleUser: false, globalElo: 100));
    when(() => mockRankedStore.currentScores).thenReturn([]);
    
    when(() => mockRankedStore.countdownValue).thenReturn(10);
    when(() => mockRankedStore.myAnswerId).thenReturn(null);
    when(() => mockRankedStore.hasAnswered).thenReturn(false);
    when(() => mockRankedStore.opponentHasAnswered).thenReturn(false);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<RankedStore>.value(
      value: mockRankedStore,
      child: const MaterialApp(
        home: Scaffold(
          body: RankedQuizView(),
        ),
      ),
    );
  }

  testWidgets('RankedQuizView renders correctly in active state', (WidgetTester tester) async {
    when(() => mockRankedStore.currentQuestion).thenReturn(const RankedQuestion(
      score: 100, currentIndex: 0, multiplier: 1.0, 
      question: RankedQuestionBase(id: 1, label: 'Q1', answer: [
        RankedAnswerOption(id: 1, label: 'A1', valid: true),
      ], idDifficulty: 1)
    ));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(RankedQuizView), findsOneWidget);
    expect(find.text('Q1'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays "Réponse envoyée" when answered during active state', (WidgetTester tester) async {
    when(() => mockRankedStore.state).thenReturn(RankedGameState.questionActive);
    when(() => mockRankedStore.hasAnswered).thenReturn(true);
    when(() => mockRankedStore.currentQuestion).thenReturn(const RankedQuestion(
      score: 100, currentIndex: 0, multiplier: 1.0, 
      question: RankedQuestionBase(id: 1, label: 'Q1', answer: [], idDifficulty: 1)
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    
    expect(find.textContaining('Réponse envoyée'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays Correct during reveal when answer is correct', (WidgetTester tester) async {
    when(() => mockRankedStore.state).thenReturn(RankedGameState.answerReveal);
    when(() => mockRankedStore.myAnswerId).thenReturn(1);
    when(() => mockRankedStore.currentQuestion).thenReturn(const RankedQuestion(
      score: 100, currentIndex: 0, multiplier: 1.0, 
      question: RankedQuestionBase(id: 1, label: 'Q1', answer: [
        RankedAnswerOption(id: 1, label: 'A1', valid: true),
      ], idDifficulty: 1)
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    
    expect(find.textContaining('Correct'), findsOneWidget);
    expect(find.byType(BadgeSuccess), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays Mauvaise réponse during reveal when answer is incorrect', (WidgetTester tester) async {
    when(() => mockRankedStore.state).thenReturn(RankedGameState.answerReveal);
    when(() => mockRankedStore.myAnswerId).thenReturn(2);
    when(() => mockRankedStore.currentQuestion).thenReturn(const RankedQuestion(
      score: 100, currentIndex: 0, multiplier: 1.0, 
      question: RankedQuestionBase(id: 1, label: 'Q1', answer: [
        RankedAnswerOption(id: 2, label: 'A2', valid: false),
      ], idDifficulty: 1)
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    
    expect(find.textContaining('Mauvaise réponse'), findsOneWidget);
    expect(find.byType(BadgeWarning), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays Aucune réponse donnée during reveal when id is null', (WidgetTester tester) async {
    when(() => mockRankedStore.state).thenReturn(RankedGameState.answerReveal);
    when(() => mockRankedStore.myAnswerId).thenReturn(null);
    when(() => mockRankedStore.currentQuestion).thenReturn(const RankedQuestion(
      score: 100, currentIndex: 0, multiplier: 1.0, 
      question: RankedQuestionBase(id: 1, label: 'Q1', answer: [], idDifficulty: 1)
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    
    expect(find.textContaining('Aucune réponse donnée'), findsOneWidget);
    expect(find.byType(BadgeWarning), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays countdown correctly', (WidgetTester tester) async {
    when(() => mockRankedStore.state).thenReturn(RankedGameState.countdown);
    when(() => mockRankedStore.countdownValue).thenReturn(7);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('7'), findsOneWidget);
    expect(find.textContaining('Prochaine question'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
