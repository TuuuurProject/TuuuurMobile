import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_duel_intro_view.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_models.dart';

class MockRankedStore extends Mock implements RankedStore {}

void main() {
  late MockRankedStore mockRankedStore;

  setUp(() {
    mockRankedStore = MockRankedStore();
    
    when(() => mockRankedStore.state).thenReturn(RankedGameState.matchFound);
    when(() => mockRankedStore.opponent).thenReturn(const RankedUser(id: 'xyz', nickName: 'S1mple', globalElo: 1000));
    when(() => mockRankedStore.countdownValue).thenReturn(3);
  });

  testWidgets('RankedDuelIntroView renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<RankedStore>.value(
        value: mockRankedStore,
        child: const MaterialApp(
          home: Scaffold(
            body: RankedDuelIntroView(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100)); // Clear pulse animations
    expect(find.byType(RankedDuelIntroView), findsOneWidget);
  });
}
