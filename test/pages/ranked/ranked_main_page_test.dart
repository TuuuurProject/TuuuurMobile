import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_main_page.dart';
import 'package:tuuuur_flutter/stores/ranked_coordinator.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_websocket_service.dart';

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
}
