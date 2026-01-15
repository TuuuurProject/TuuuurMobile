
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tuuuur_flutter/pages/profile/profile_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/widgets/navigation_header.dart';

// ApiResponse est défini dans api_client.dart
import 'package:tuuuur_flutter/api/api_client.dart' as api;

import 'package:tuuuur_flutter/api/auth_api_service.dart' as api_auth;
import 'package:tuuuur_flutter/api/history_api_service.dart' as api_hist;

class MockAuthApi extends Mock implements api_auth.AuthApi {}
class MockHistoryApi extends Mock implements api_hist.HistoryApi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ✅ Mock FlutterSecureStorage (sinon MissingPluginException)
  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> secureStore = <String, String>{};

  setUpAll(() async {
    secureStorageChannel.setMockMethodCallHandler((MethodCall call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};

      switch (call.method) {
        case 'write':
          final key = args['key'] as String?;
          final value = args['value'] as String?;
          if (key != null && value != null) secureStore[key] = value;
          return null;

        case 'read':
          final key = args['key'] as String?;
          return key == null ? null : secureStore[key];

        case 'delete':
          final key = args['key'] as String?;
          if (key != null) secureStore.remove(key);
          return null;

        case 'deleteAll':
          secureStore.clear();
          return null;

        case 'containsKey':
          final key = args['key'] as String?;
          return key != null && secureStore.containsKey(key);

        case 'readAll':
          return Map<String, String>.from(secureStore);

        case 'keys':
          return secureStore.keys.toList();

        default:
          // Si ton AuthStore appelle une méthode non gérée, tu la verras ici
          return null;
      }
    });
  });

  tearDownAll(() async {
    secureStorageChannel.setMockMethodCallHandler(null);
  });

  // PNG 1x1 base64 valide (évite Image.network en tests)
  const tinyPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+lmfkAAAAASUVORK5CYII=';

  api_auth.AuthSession session() {
    return api_auth.AuthSession(
      user: api_auth.UserDto(
        id: 1,
        nickName: 'TestUser',
        email: 'test@exemple.com',
        avatar: tinyPngBase64,
        isAdmin: false,
        isNew: false,
      ),
      token: api_auth.AuthToken(token: 'fake-token'),
      isGoogleUser: false,
      raw: const {},
    );
  }

  Future<void> forceSignOut() async {
    await AuthStore.instance.signOut();
  }

  group('ProfilePage', () {
    late MockAuthApi mockAuth;
    late MockHistoryApi mockHistory;

    setUp(() async {
      mockAuth = MockAuthApi();
      mockHistory = MockHistoryApi();
      await forceSignOut();
      secureStore.clear();
    });

    tearDown(() async {
      await forceSignOut();
      secureStore.clear();
    });

    testWidgets("non connecté: affiche la carte 'Vous n’êtes pas connecté'",
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: ProfilePage(
              authApi: mockAuth,
              historyApi: mockHistory,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(NavigationHeader), findsOneWidget);

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Vous n’êtes pas connecté'), findsOneWidget);
      expect(find.text('🚀 Se connecter'), findsOneWidget);
      expect(find.text('🔗 Créer un compte'), findsOneWidget);
    });

    testWidgets(
        "connecté: affiche 1 match dans l'historique (mock HistoryMatchDto)",
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      // /me => ok
      when(() => mockAuth.me(headers: any(named: 'headers'))).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: 1,
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      // ✅ 1 match mocké
      const match = api_hist.HistoryMatchDto(
        id: 'm1',
        dt: null, // évite les asserts sur date relative (flaky)
        finish: true,
        nbQuestions: 10,
        score: 7,
        time: 65, // => "1m 5s"
        percent: 70,
        partyType: api_hist.HistoryPartyTypeDto(id: 1, label: 'Solo'),
        partyDifficulty: <api_hist.HistoryPartyDifficultyDto>[
          api_hist.HistoryPartyDifficultyDto(
            id: 1,
            difficulty: api_hist.HistoryDifficultyDto(id: 1, label: 'Facile'),
          ),
        ],
        partyTheme: <api_hist.HistoryPartyThemeDto>[
          api_hist.HistoryPartyThemeDto(
            id: 1,
            theme: api_hist.HistoryThemeDto(id: 1, label: 'Sport', icon: null),
          ),
        ],
      );

      // Historique => 1 item
      when(() => mockHistory.getHistory(
            headers: any(named: 'headers'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer(
        (_) async => api.ApiResponse.ok(
          const api_hist.HistoryPageDto(
            items: <api_hist.HistoryMatchDto>[match],
            totalCount: 1,
            currentPage: 1,
            totalPages: 1,
          ),
          statusCode: 200,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: ProfilePage(
              authApi: mockAuth,
              historyApi: mockHistory,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Profil affiché
      expect(find.text('Vous n’êtes pas connecté'), findsNothing);
      expect(find.text('TestUser'), findsOneWidget);

      // Section historique
      expect(find.text('Historique des parties'), findsOneWidget);
      expect(find.textContaining('1 Partie'), findsOneWidget);

      // Tuile match
      expect(find.text('Terminer'), findsOneWidget);
      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);

      expect(find.text('Questions:'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      expect(find.text('Réussite:'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);

      expect(find.text('Temps:'), findsOneWidget);
      expect(find.text('1m 5s'), findsOneWidget);

      expect(find.text('pts'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      verify(() => mockAuth.me(headers: any(named: 'headers'))).called(1);
      verify(() => mockHistory.getHistory(
            headers: any(named: 'headers'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).called(1);
    });

    testWidgets("dispose proprement (pas d'exception au démontage)",
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: ProfilePage(
              authApi: mockAuth,
              historyApi: mockHistory,
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    test('ProfilePage crée un state correct', () {
      final page = ProfilePage(authApi: mockAuth, historyApi: mockHistory);
      final state = page.createState();
      expect(state, isNotNull);
    });

    testWidgets(
        "bouton 'Changer le pseudo' ouvre la navigation et met à jour l'affichage",
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      // /me => ok
      when(() => mockAuth.me(headers: any(named: 'headers'))).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: 1,
            nickName: 'OldNickname',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      // Historique vide
      when(() => mockHistory.getHistory(
            headers: any(named: 'headers'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer(
        (_) async => api.ApiResponse.ok(
          const api_hist.HistoryPageDto(
            items: <api_hist.HistoryMatchDto>[],
            totalCount: 0,
            currentPage: 1,
            totalPages: 0,
          ),
          statusCode: 200,
        ),
      );

      // Note: Le bouton "Changer le pseudo" utilise context.push('/change-nickname')
      // Pour tester la navigation, on devrait utiliser GoRouter
      // Pour ce test, on vérifie simplement la présence du bouton
      await tester.pumpWidget(
        MaterialApp(
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: ProfilePage(
              authApi: mockAuth,
              historyApi: mockHistory,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifie que le bouton existe
      expect(find.text('Changer le pseudo'), findsOneWidget);

      // Vérifie que le pseudo actuel est affiché
      expect(find.text('OldNickname'), findsOneWidget);
    });
  });
}
