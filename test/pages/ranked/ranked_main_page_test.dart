import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_main_page.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_join_view.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_matchmaking_view.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_duel_intro_view.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_quiz_view.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_results_view.dart';
import 'package:tuuuur_flutter/stores/ranked_coordinator.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_websocket_service.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_models.dart';

class MockRankedWebSocketService extends Mock implements RankedWebSocketService {}
class MockRankedStore extends Mock implements RankedStore {}
class MockRankedCoordinator extends Mock implements RankedCoordinator {}

void main() {
  testWidgets('RankedMainContent loads and displays correctly depending on Store state', (WidgetTester tester) async {
    final mockStore = MockRankedStore();
    // Simulate idle state which should show RankedJoinView
    when(() => mockStore.state).thenReturn(RankedGameState.idle);

    // Some mock values just in case RankedJoinView needs them
    when(() => mockStore.isConnected).thenReturn(true);
    when(() => mockStore.isWinner).thenReturn(null);
    when(() => mockStore.eloDelta).thenReturn(null);
    when(() => mockStore.hasAnswered).thenReturn(false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<RankedStore>.value(
            value: mockStore,
            child: const RankedMainContent(),
          ),
        ),
      ),
    );

    // Initial state is idle, so it should display Scaffold and the RankedJoinView
    expect(find.byType(Scaffold), findsWidgets);

    // Wait for animations and clear
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  Widget _buildAppWithStore(MockRankedStore store) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<RankedStore>.value(
          value: store,
          child: const RankedMainContent(),
        ),
      ),
    );
  }

  testWidgets('displays RankedMatchmakingView when state is searching', (WidgetTester tester) async {
    final mockStore = MockRankedStore();
    when(() => mockStore.state).thenReturn(RankedGameState.searching);
    await tester.pumpWidget(_buildAppWithStore(mockStore));
    expect(find.byType(RankedMatchmakingView), findsOneWidget);
    // Libère les timers d'animation avant la fin du test
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays RankedDuelIntroView when state is matchFound', (WidgetTester tester) async {
    final mockStore = MockRankedStore();
    when(() => mockStore.state).thenReturn(RankedGameState.matchFound);
    when(() => mockStore.opponent).thenReturn(const RankedUser(id: '1', nickName: 'Bob', globalElo: 100)); // Provide opponent
    await tester.pumpWidget(_buildAppWithStore(mockStore));
    expect(find.byType(RankedDuelIntroView), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays RankedQuizView when state is countdown', (WidgetTester tester) async {
    final mockStore = MockRankedStore();
    when(() => mockStore.state).thenReturn(RankedGameState.countdown);
    when(() => mockStore.hasAnswered).thenReturn(false);
    when(() => mockStore.currentScores).thenReturn([]);
    when(() => mockStore.opponent).thenReturn(null);
    when(() => mockStore.countdownValue).thenReturn(5);
    await tester.pumpWidget(_buildAppWithStore(mockStore));
    expect(find.byType(RankedQuizView), findsOneWidget);
    // Libère les timers d'animation avant la fin du test
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays RankedQuizView when state is questionActive', (WidgetTester tester) async {
    final mockStore = MockRankedStore();
    when(() => mockStore.state).thenReturn(RankedGameState.questionActive);
    when(() => mockStore.hasAnswered).thenReturn(false);
    when(() => mockStore.currentScores).thenReturn([]);
    when(() => mockStore.opponent).thenReturn(null);
    await tester.pumpWidget(_buildAppWithStore(mockStore));
    expect(find.byType(RankedQuizView), findsOneWidget);
    // Libère les timers d'animation avant la fin du test
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays RankedQuizView when state is answerReveal', (WidgetTester tester) async {
    final mockStore = MockRankedStore();
    when(() => mockStore.state).thenReturn(RankedGameState.answerReveal);
    when(() => mockStore.hasAnswered).thenReturn(false);
    when(() => mockStore.currentScores).thenReturn([]);
    when(() => mockStore.opponent).thenReturn(null);
    when(() => mockStore.myAnswerId).thenReturn(null);
    await tester.pumpWidget(_buildAppWithStore(mockStore));
    expect(find.byType(RankedQuizView), findsOneWidget);
    // Libère les timers d'animation avant la fin du test
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays RankedQuizView when state is scoreDisplay', (WidgetTester tester) async {
    final mockStore = MockRankedStore();
    when(() => mockStore.state).thenReturn(RankedGameState.scoreDisplay);
    when(() => mockStore.hasAnswered).thenReturn(false);
    when(() => mockStore.currentScores).thenReturn([]);
    when(() => mockStore.opponent).thenReturn(null);
    await tester.pumpWidget(_buildAppWithStore(mockStore));
    expect(find.byType(RankedQuizView), findsOneWidget);
    // Libère les timers d'animation avant la fin du test
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays RankedResultsView when state is finished', (WidgetTester tester) async {
    final mockStore = MockRankedStore();
    when(() => mockStore.state).thenReturn(RankedGameState.finished);
    when(() => mockStore.isWinner).thenReturn(true);
    when(() => mockStore.eloDelta).thenReturn(25);
    when(() => mockStore.finalScores).thenReturn([]);
    when(() => mockStore.currentScores).thenReturn([]);
    when(() => mockStore.opponent).thenReturn(null);
    when(() => mockStore.questionsHistory).thenReturn([]);

    await tester.pumpWidget(_buildAppWithStore(mockStore));
    expect(find.byType(RankedResultsView), findsOneWidget);
    // Libère les timers d'animation avant la fin du test
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('displays error view and can clear error', (WidgetTester tester) async {
    final mockStore = MockRankedStore();
    when(() => mockStore.state).thenReturn(RankedGameState.error);
    when(() => mockStore.errorMessage).thenReturn('Test Error');

    await tester.pumpWidget(_buildAppWithStore(mockStore));

    expect(find.textContaining('Erreur'), findsOneWidget);
    expect(find.textContaining('Test Error'), findsOneWidget);
    
    final button = find.widgetWithText(ElevatedButton, 'Retour');
    expect(button, findsOneWidget);

    when(() => mockStore.clearError()).thenAnswer((_) {});
    await tester.tap(button);
    await tester.pumpAndSettle();

    verify(() => mockStore.clearError()).called(1);
  });
}
