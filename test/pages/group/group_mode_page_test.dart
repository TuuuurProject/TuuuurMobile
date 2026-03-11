import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/group/group_api_service.dart';
import 'package:tuuuur_flutter/pages/group/group_mode_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/stores/group_store.dart';

import 'group_test_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Pumps through animations without using pumpAndSettle (avoids infinite-
/// animation hang from flutter_animate's shimmer / CountdownWidget).
Future<void> pumpAnimations(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> finishGroupTest(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pumps the [GroupModePage] inside a [MaterialApp] with a fake coordinator.
Future<({FakeGroupCoordinator coord, GroupStore store, FakeGroupWebSocketService ws})>
    pumpModePage(WidgetTester tester, {Size size = const Size(800, 700)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final ws = FakeGroupWebSocketService();
  final store = GroupStore(webSocketService: ws);
  final coord = FakeGroupCoordinator(groupStore: store, ws: ws);
  final fakeApi = GroupApi(ApiClient(baseUrl: 'http://localhost:1'));

  await tester.pumpWidget(
    MaterialApp(
      // Use builder so ALL routes (including pushed ones) inherit MyAuthStore
      builder: (ctx, child) => MyAuthStore(
        notifier: AuthStore.instance,
        child: child!,
      ),
      home: GroupModePage(
        groupApiOverride: fakeApi,
        groupCoordinatorOverride: coord,
      ),
    ),
  );

  await tester.pump();
  return (coord: coord, store: store, ws: ws);
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

  group('GroupModePage', () {
    testWidgets('affiche les deux cartes de mode', (tester) async {
      await pumpModePage(tester);
      await pumpAnimations(tester);

      expect(find.text('Créer une partie'), findsOneWidget);
      expect(find.text('Rejoindre une partie'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets('affiche le titre "Mode Groupe"', (tester) async {
      await pumpModePage(tester);
      await pumpAnimations(tester);

      expect(find.text('Mode Groupe'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets('tapper "Rejoindre une partie" affiche le formulaire join',
        (tester) async {
      await pumpModePage(tester);
      await pumpAnimations(tester);

      await tester.tap(find.text('Rejoindre une partie'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // GroupJoinPage is shown inline (step = join), title appears
      expect(find.text('Rejoindre une partie'), findsWidgets);
      // The code input field should be visible
      expect(
        find.byWidgetPredicate((w) => w is TextField),
        findsOneWidget,
      );

      await finishGroupTest(tester);
    });

    testWidgets(
        'tapper "Créer une partie" → succès → navigue vers GroupLobbyPage',
        (tester) async {
      final (:coord, :store, :ws) = await pumpModePage(tester);
      await pumpAnimations(tester);

      await tester.tap(find.text('Créer une partie'));
      await tester.pump(); // start async
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // After a successful create, the lobby is navigated to.
      // The store should have a party.
      expect(store.currentParty, isNotNull);
      // The code should match what the fake coordinator returns.
      expect(store.currentParty!.code, '123456');

      await finishGroupTest(tester);
    });

    testWidgets(
        'tapper "Créer une partie" → échec → affiche snack-bar d\'erreur',
        (tester) async {
      final (:coord, :store, :ws) = await pumpModePage(tester);
      await pumpAnimations(tester);

      coord.createSuccess = false;

      await tester.tap(find.text('Créer une partie'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Impossible de créer la partie.'),
        findsOneWidget,
      );

      await finishGroupTest(tester);
    });
  });
}
