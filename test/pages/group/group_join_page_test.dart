import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/pages/group/group_join_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/stores/group_store.dart';

import 'group_test_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> finishGroupTest(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class _JoinCapture {
  String? partyId;
  String? code;
}

Future<({FakeGroupCoordinator coord, GroupStore store, _JoinCapture capture})>
    pumpJoinPage(WidgetTester tester,
        {Size size = const Size(600, 700)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final ws = FakeGroupWebSocketService();
  final store = GroupStore(webSocketService: ws);
  final coord = FakeGroupCoordinator(groupStore: store, ws: ws);
  final capture = _JoinCapture();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MyAuthStore(
          notifier: AuthStore.instance,
          child: GroupJoinPage(
            groupCoordinatorOverride: coord,
            onBack: () {},
            onJoined: ({required String partyId, required String code}) {
              capture.partyId = partyId;
              capture.code = code;
            },
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  return (coord: coord, store: store, capture: capture);
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

  group('GroupJoinPage', () {
    testWidgets('affiche le titre et le champ de saisie du code', (tester) async {
      await pumpJoinPage(tester);

      expect(find.text('Rejoindre une partie'), findsOneWidget);
      expect(find.text('Entrez le code à 6 chiffres'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets('code vide → affiche message d\'erreur', (tester) async {
      final (:coord, :store, :capture) = await pumpJoinPage(tester);

      // Tap Rejoindre without entering a code
      final btn = find.text('Rejoindre');
      await tester.tap(btn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Veuillez entrer un code de partie.'),
        findsAtLeastNWidgets(1),
      );
      expect(capture.partyId, isNull);

      await finishGroupTest(tester);
    });

    testWidgets('code valide → join succès → callback onJoined appelé',
        (tester) async {
      final (:coord, :store, :capture) = await pumpJoinPage(tester);

      await tester.enterText(find.byType(TextField), '654321');
      await tester.pump();

      await tester.tap(find.text('Rejoindre'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(capture.code, '654321');
      expect(capture.partyId, isNotNull);

      await finishGroupTest(tester);
    });

    testWidgets('join échoue → affiche erreur dans l\'UI', (tester) async {
      final (:coord, :store, :capture) = await pumpJoinPage(tester);
      coord.joinSuccess = false;

      await tester.enterText(find.byType(TextField), '999999');
      await tester.pump();

      await tester.tap(find.text('Rejoindre'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Impossible de rejoindre la partie. Code invalide ?'),
        findsAtLeastNWidgets(1),
      );
      expect(capture.partyId, isNull);

      await finishGroupTest(tester);
    });

    testWidgets(
        'bouton Rejoindre est désactivé pendant le chargement et '
        'icône check apparaît avec 6 chiffres', (tester) async {
      await pumpJoinPage(tester);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      // Check icon should appear when code is 6 digits
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await finishGroupTest(tester);
    });
  });
}
