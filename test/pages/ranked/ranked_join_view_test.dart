import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';
import 'package:tuuuur_flutter/pages/ranked/ranked_join_view.dart';

class MockRankedStore extends Mock implements RankedStore {}

void main() {
  late MockRankedStore mockRankedStore;

  setUp(() {
    mockRankedStore = MockRankedStore();
    // No specific properties to mock for RankedJoinView
  });

  testWidgets('RankedJoinView renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<RankedStore>.value(
        value: mockRankedStore,
        child: const MaterialApp(
          home: Scaffold(
            body: RankedJoinView(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(RankedJoinView), findsOneWidget);
  });
}
