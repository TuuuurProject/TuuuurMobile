import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/group/group_models.dart' hide Theme;
import 'package:tuuuur_flutter/pages/group/group_lobby_page.dart';
import 'package:tuuuur_flutter/pages/group/group_mode_page.dart';
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

Future<void> pumpAnimations(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Sets up a lobby page as host with the given [party] already in the store.
Future<({FakeGroupCoordinator coord, GroupStore store})> pumpLobbyPage(
  WidgetTester tester, {
  required GroupParty party,
  required String currentUserId,
  Size size = const Size(800, 800),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final ws = FakeGroupWebSocketService();
  final store = GroupStore(webSocketService: ws);
  final coord = FakeGroupCoordinator(groupStore: store, ws: ws);

  // Put the party into the store
  store.initializeParty(party, currentUserId: currentUserId);

  final lobby = GroupLobbyData(
    partyId: party.id,
    code: party.code,
    isHost: party.idUserHost == currentUserId,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: MyAuthStore(
        notifier: AuthStore.instance,
        child: GroupLobbyPage(
          lobby: lobby,
          onBack: () {},
          groupCoordinatorOverride: coord,
        ),
      ),
    ),
  );

  await tester.pump();
  return (coord: coord, store: store);
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

  group('GroupLobbyPage', () {
    testWidgets('vue hôte : affiche "Lancer la partie" et code', (tester) async {
      final party = makeGroupParty(
        code: '123456',
        hostUserId: 'user-1',
      );
      await pumpLobbyPage(tester, party: party, currentUserId: 'user-1');
      await pumpAnimations(tester);

      expect(find.text('Lancer la partie'), findsAtLeastNWidgets(1));
      expect(find.text('123456'), findsAtLeastNWidgets(1));

      await finishGroupTest(tester);
    });

    testWidgets('vue non-hôte : affiche le message d\'attente', (tester) async {
      final party = makeGroupParty(
        code: '654321',
        hostUserId: 'other-user',
        users: [
          PartyUser(
            idUser: 'other-user',
            idParty: 'p1',
            user: GroupUser(id: 'other-user', nickName: 'Host'),
          ),
          PartyUser(
            idUser: 'user-1',
            idParty: 'p1',
            user: GroupUser(id: 'user-1', nickName: 'Tester'),
          ),
        ],
      );
      await pumpLobbyPage(tester, party: party, currentUserId: 'user-1');
      await pumpAnimations(tester);

      expect(find.text('Lancer la partie'), findsNothing);
      expect(
        find.text('En attente que l\'hôte démarre la partie...'),
        findsOneWidget,
      );

      await finishGroupTest(tester);
    });

    testWidgets('affiche les informations de la partie', (tester) async {
      final party = makeGroupParty(
        code: 'AABB11',
        hostUserId: 'user-1',
        nbQuestions: 5,
      );
      await pumpLobbyPage(tester, party: party, currentUserId: 'user-1');
      await pumpAnimations(tester);

      expect(find.text('Infos de la partie'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
      expect(find.text('Rejoindre via code'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets('affiche la liste des joueurs', (tester) async {
      final party = makeGroupParty(
        hostUserId: 'user-1',
        users: [
          PartyUser(
            idUser: 'user-1',
            idParty: 'p1',
            user: GroupUser(id: 'user-1', nickName: 'Alice'),
          ),
          PartyUser(
            idUser: 'user-2',
            idParty: 'p1',
            user: GroupUser(id: 'user-2', nickName: 'Bob'),
          ),
        ],
      );
      await pumpLobbyPage(tester, party: party, currentUserId: 'user-1');
      await pumpAnimations(tester);

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Joueurs'), findsOneWidget);

      await finishGroupTest(tester);
    });

    testWidgets(
        'changement d\'état store → countdown → navigue vers GroupQuizPage',
        (tester) async {
      final party = makeGroupParty(
        code: '111222',
        hostUserId: 'user-1',
      );
      final (:coord, :store) =
          await pumpLobbyPage(tester, party: party, currentUserId: 'user-1');
      await pumpAnimations(tester);

      // Simulate WebSocket countdown event
      store.onCountdown(3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // GroupQuizPage should have been pushed — look for its countdown text
      expect(find.text('La question arrive dans...'), findsOneWidget);

      await finishGroupTest(tester);
    });
  });
}
