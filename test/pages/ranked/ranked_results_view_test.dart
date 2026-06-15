import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_models.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_results_view.dart';

class MockRankedStore extends Mock implements RankedStore {}
class MockAuthStore extends Mock implements AuthStore {}

void main() {
  late MockRankedStore mockRankedStore;
  late MockAuthStore mockAuthStore;

  setUp(() {
    mockRankedStore = MockRankedStore();
    mockAuthStore = MockAuthStore();

    final userMe = const RankedUser(id: "1", nickName: "Me", globalElo: 1500);
    final userOpponent = const RankedUser(id: "2", nickName: "Opponent", globalElo: 1500);

    when(() => mockAuthStore.user).thenReturn(null);
    when(() => mockRankedStore.isWinner).thenReturn(true);
    when(() => mockRankedStore.eloDelta).thenReturn(25);
    when(() => mockRankedStore.finalScores).thenReturn([
      RankedUserScore(score: 100, user: userMe),
      RankedUserScore(score: 50, user: userOpponent)
    ]);
    when(() => mockRankedStore.opponent).thenReturn(null);
    when(() => mockRankedStore.questionsHistory).thenReturn([]);
  });

  testWidgets('RankedResultsView renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RankedStore>.value(value: mockRankedStore),
          ChangeNotifierProvider<AuthStore>.value(value: mockAuthStore),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: RankedResultsView(),
          ),
        ),
      ),
    );

    // La carte récap a une animation infinie (icône qui pulse) → on ne peut pas
    // utiliser pumpAndSettle ici. On pompe quelques frames puis on vérifie.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(RankedResultsView), findsOneWidget);

    // Nettoie l'arbre + purge les timers d'animation avant la fin du test.
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
