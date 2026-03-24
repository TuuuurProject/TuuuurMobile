import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_quiz_view.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_models.dart';

class MockRankedStore extends Mock implements RankedStore {}

void main() {
  late MockRankedStore mockRankedStore;

  setUp(() {
    mockRankedStore = MockRankedStore();

    when(() => mockRankedStore.state).thenReturn(RankedGameState.questionActive);
    when(() => mockRankedStore.opponent).thenReturn(const RankedUser(id: '1', nickName: 'P1', isGoogleUser: false, globalElo: 100));
    when(() => mockRankedStore.currentScores).thenReturn([]);
    when(() => mockRankedStore.currentQuestion).thenReturn(const RankedQuestion(score: 100, currentIndex: 0, multiplier: 1.0, question: RankedQuestionBase(id: 1, label: 'Q1', answer: [], idDifficulty: 1)));
    when(() => mockRankedStore.countdownValue).thenReturn(10);
    when(() => mockRankedStore.myAnswerId).thenReturn(null);
    when(() => mockRankedStore.hasAnswered).thenReturn(false);
    when(() => mockRankedStore.opponentHasAnswered).thenReturn(false);
  });

  testWidgets('RankedQuizView renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<RankedStore>.value(
        value: mockRankedStore,
        child: const MaterialApp(
          home: Scaffold(
            body: RankedQuizView(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(RankedQuizView), findsOneWidget);
  });
}
