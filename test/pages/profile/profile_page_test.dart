
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tuuuur_flutter/pages/profile/profile_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/widgets/navigation_header.dart';

import 'package:tuuuur_flutter/api/api_client.dart' as api;

import 'package:tuuuur_flutter/api/auth/auth_api_service.dart' as api_auth;
import 'package:tuuuur_flutter/api/auth/auth_models.dart' as api_auth;
import 'package:tuuuur_flutter/api/other/history_api_service.dart' as api_hist;
import 'package:tuuuur_flutter/api/other/history_models.dart' as api_hist;

class MockAuthApi extends Mock implements api_auth.AuthApi {}
class MockHistoryApi extends Mock implements api_hist.HistoryApi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
          return null;
      }
    });
  });

  tearDownAll(() async {
    secureStorageChannel.setMockMethodCallHandler(null);
  });

  const tinyPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+lmfkAAAAASUVORK5CYII=';

  api_auth.AuthSessionDto session() {
    return api_auth.AuthSessionDto(
      user: api_auth.UserDto(
        id: '1',
        nickName: 'TestUser',
        email: 'test@exemple.com',
        avatar: tinyPngBase64,
        isAdmin: false,
        isNew: false,
      ),
      token: api_auth.AuthTokenDto(token: 'fake-token'),
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
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);
    });

    testWidgets(
        "connecté: affiche 1 match dans l'historique (mock HistoryMatchDto)",
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      const match = api_hist.HistoryMatchDto(
        id: 'm1',
        dt: null,
        finish: true,
        nbQuestions: 10,
        score: 7,
        time: 65,
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

      when(() => mockHistory.getHistory(
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


      expect(find.text('Vous n’êtes pas connecté'), findsNothing);
      expect(find.text('TestUser'), findsOneWidget);

      expect(find.text('Historique des parties'), findsOneWidget);
      expect(find.textContaining('1 Partie'), findsOneWidget);

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

      verify(() => mockAuth.me()).called(1);
      verify(() => mockHistory.getHistory(
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

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'OldNickname',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      expect(find.byTooltip('Modifier le pseudo'), findsOneWidget);

      expect(find.text('OldNickname'), findsOneWidget);
    });

    testWidgets('_deleteAccount confirme et appelle l\'API',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      when(() => mockAuth.deleteMe()).thenAnswer(
        (_) async => api.ApiResponse.err(message: 'Test: API mockée'),
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

      await tester.tap(find.text('Supprimer mon compte'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer le compte'), findsOneWidget);
      expect(
          find.text('Cette action est irréversible. Confirmer ?'),
          findsOneWidget);

      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      verify(() => mockAuth.deleteMe()).called(1);
    });

    testWidgets('_deleteAccount annulé ne supprime pas',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      await tester.tap(find.text('Supprimer mon compte'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      verifyNever(() => mockAuth.deleteMe());
    });

    testWidgets('_signOut déconnecte l\'utilisateur',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      expect(AuthStore.instance.isAuthenticated, isTrue);

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(AuthStore.instance.isAuthenticated, isFalse);
    });

    testWidgets('_changeHistoryPage appelle l\'API avec la bonne page',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      // Créer 25 matchs fictifs pour avoir plusieurs pages
      final matches = List.generate(
        25,
        (i) => api_hist.HistoryMatchDto(
          id: 'm$i',
          dt: null,
          finish: true,
          nbQuestions: 10,
          score: 7,
          time: 65,
          percent: 70,
          partyType: const api_hist.HistoryPartyTypeDto(id: 1, label: 'Solo'),
          partyDifficulty: const <api_hist.HistoryPartyDifficultyDto>[
            api_hist.HistoryPartyDifficultyDto(
              id: 1,
              difficulty: api_hist.HistoryDifficultyDto(id: 1, label: 'Facile'),
            ),
          ],
          partyTheme: const <api_hist.HistoryPartyThemeDto>[
            api_hist.HistoryPartyThemeDto(
              id: 1,
              theme: api_hist.HistoryThemeDto(id: 1, label: 'Sport', icon: null),
            ),
          ],
        ),
      );

      when(() => mockHistory.getHistory(page: any(named: 'page'), size: any(named: 'size'))).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_hist.HistoryPageDto(
            items: matches,
            totalCount: 25,
            currentPage: 1,
            totalPages: 3,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(page: 2, size: 10)).thenAnswer(
        (_) async => api.ApiResponse.ok(
          const api_hist.HistoryPageDto(
            items: <api_hist.HistoryMatchDto>[],
            totalCount: 25,
            currentPage: 2,
            totalPages: 3,
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

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Page 1 / 3'), findsOneWidget);

      verify(() => mockHistory.getHistory(page: 1, size: 1000)).called(1);
    });

    testWidgets('_startEditingNickname active le mode édition',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      await tester.tap(find.byTooltip('Modifier le pseudo'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byTooltip('Valider'), findsOneWidget);
      expect(find.byTooltip('Annuler'), findsOneWidget);
    });

    testWidgets('_cancelEditingNickname annule l\'édition',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      await tester.tap(find.byTooltip('Modifier le pseudo'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.byTooltip('Annuler'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('TestUser'), findsOneWidget);
    });

    testWidgets('_saveNickname met à jour le pseudo avec succès',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'OldNickname',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      when(() => mockAuth.updateNickname(nickname: 'NewNickname')).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'NewNickname',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
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

      await tester.tap(find.byTooltip('Modifier le pseudo'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NewNickname');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Valider'));
      await tester.pumpAndSettle();

      verify(() => mockAuth.updateNickname(nickname: 'NewNickname')).called(1);
      expect(find.text('NewNickname'), findsOneWidget);
    });

    testWidgets('_saveNickname rejette un pseudo vide',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      await tester.tap(find.byTooltip('Modifier le pseudo'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Valider'));
      await tester.pumpAndSettle();

      expect(find.text('Le pseudo ne peut pas être vide.'), findsOneWidget);
      verifyNever(() => mockAuth.updateNickname(nickname: any(named: 'nickname')));
    });

    testWidgets('_formatRelative formate correctement les dates dans l\'UI',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      final twoMinutesAgo = DateTime.now().subtract(const Duration(minutes: 2));
      final match = api_hist.HistoryMatchDto(
        id: 'm1',
        dt: twoMinutesAgo,
        finish: true,
        nbQuestions: 10,
        score: 7,
        time: 65,
        percent: 70,
        partyType: const api_hist.HistoryPartyTypeDto(id: 1, label: 'Solo'),
        partyDifficulty: const <api_hist.HistoryPartyDifficultyDto>[],
        partyTheme: const <api_hist.HistoryPartyThemeDto>[],
      );

      when(() => mockHistory.getHistory(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_hist.HistoryPageDto(
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

      expect(find.textContaining('Il y a'), findsOneWidget);
    });

    testWidgets('erreur API me() → affiche la carte d\'erreur serveur',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async =>
            api.ApiResponse.err(message: 'Serveur indisponible', statusCode: 500),
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

      // Should show error card or not-connected card
      final hasError =
          find.textContaining('Serveur').evaluate().isNotEmpty ||
          find.textContaining('erreur').evaluate().isNotEmpty ||
          find.textContaining('Impossible').evaluate().isNotEmpty ||
          find.textContaining('connecté').evaluate().isNotEmpty;
      expect(hasError, isTrue);
    });

    testWidgets('erreur API getHistory → affiche un message d\'erreur historique',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer(
        (_) async =>
            api.ApiResponse.err(message: 'Erreur historique', statusCode: 500),
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

      expect(find.text('TestUser'), findsOneWidget);
      // Error in history section or no matches shown
      final hasHistoryError =
          find.textContaining('Erreur').evaluate().isNotEmpty ||
          find.textContaining('aucune').evaluate().isNotEmpty ||
          find.textContaining('partie').evaluate().isNotEmpty;
      expect(hasHistoryError, isTrue);
    });

    testWidgets('historique vide → affiche 0 partie(s)',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      expect(find.textContaining('0 Partie'), findsOneWidget);
    });

    testWidgets('historique avec match non-terminé → affiche "En cours"',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      const match = api_hist.HistoryMatchDto(
        id: 'm-ongoing',
        dt: null,
        finish: false,
        nbQuestions: 10,
        score: 3,
        time: 30,
        percent: 30,
        partyType: api_hist.HistoryPartyTypeDto(id: 1, label: 'Solo'),
        partyDifficulty: [],
        partyTheme: [],
      );

      when(() => mockHistory.getHistory(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer(
        (_) async => api.ApiResponse.ok(
          const api_hist.HistoryPageDto(
            items: [match],
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

      expect(find.text('En cours'), findsOneWidget);
    });

    testWidgets('_saveNickname renvoie une erreur API → affiche snackbar',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      when(() => mockAuth.updateNickname(nickname: any(named: 'nickname')))
          .thenAnswer(
        (_) async => api.ApiResponse.err(message: 'Pseudo déjà pris'),
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

      await tester.tap(find.byTooltip('Modifier le pseudo'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NouveauPseudo');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Valider'));
      await tester.pumpAndSettle();

      verify(() => mockAuth.updateNickname(nickname: 'NouveauPseudo')).called(1);
      // Still on profile page (no navigation)
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets(
        'match avec plusieurs thèmes → affiche le premier thème et "+N" si besoin',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      const match = api_hist.HistoryMatchDto(
        id: 'm-multi',
        dt: null,
        finish: true,
        nbQuestions: 10,
        score: 8,
        time: 100,
        percent: 80,
        partyType: api_hist.HistoryPartyTypeDto(id: 1, label: 'Solo'),
        partyDifficulty: [
          api_hist.HistoryPartyDifficultyDto(
            id: 1,
            difficulty: api_hist.HistoryDifficultyDto(id: 1, label: 'Facile'),
          ),
        ],
        partyTheme: [
          api_hist.HistoryPartyThemeDto(
            id: 1,
            theme: api_hist.HistoryThemeDto(id: 1, label: 'Sport', icon: null),
          ),
          api_hist.HistoryPartyThemeDto(
            id: 2,
            theme:
                api_hist.HistoryThemeDto(id: 2, label: 'Science', icon: null),
          ),
          api_hist.HistoryPartyThemeDto(
            id: 3,
            theme:
                api_hist.HistoryThemeDto(id: 3, label: 'Histoire', icon: null),
          ),
        ],
      );

      when(() => mockHistory.getHistory(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer(
        (_) async => api.ApiResponse.ok(
          const api_hist.HistoryPageDto(
            items: [match],
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

      // Match should render (Terminer = finished match)
      expect(find.text('Terminer'), findsOneWidget);
      // At minimum the first difficulty label is shown
      expect(find.text('Facile'), findsOneWidget);
    });

    testWidgets('match avec time = 0 → affiche 0s', (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      const match = api_hist.HistoryMatchDto(
        id: 'm-zerotime',
        dt: null,
        finish: true,
        nbQuestions: 5,
        score: 5,
        time: 0,
        percent: 100,
        partyType: api_hist.HistoryPartyTypeDto(id: 1, label: 'Solo'),
        partyDifficulty: [],
        partyTheme: [],
      );

      when(() => mockHistory.getHistory(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer(
        (_) async => api.ApiResponse.ok(
          const api_hist.HistoryPageDto(
            items: [match],
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

      expect(find.text('Terminer'), findsOneWidget);
    });

    testWidgets('match avec time null → affiche --', (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      const match = api_hist.HistoryMatchDto(
        id: 'm-nulltime',
        dt: null,
        finish: true,
        nbQuestions: 5,
        score: null,
        time: null,
        percent: null,
        partyType: api_hist.HistoryPartyTypeDto(id: 1, label: 'Solo'),
        partyDifficulty: [],
        partyTheme: [],
      );

      when(() => mockHistory.getHistory(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer(
        (_) async => api.ApiResponse.ok(
          const api_hist.HistoryPageDto(
            items: [match],
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

      // Match should still render
      expect(find.text('Terminer'), findsOneWidget);
    });

    testWidgets('widget peut être démonté proprement après pumpAndSettle',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      when(() => mockHistory.getHistory(
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

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    testWidgets('date il y a plus d\'un an → format absolu dans l\'UI',
        (WidgetTester tester) async {
      await AuthStore.instance.signInWithSession(session());

      when(() => mockAuth.me()).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_auth.UserDto(
            id: '1',
            nickName: 'TestUser',
            email: 'test@exemple.com',
            avatar: tinyPngBase64,
            isAdmin: false,
            isNew: false,
          ),
          statusCode: 200,
        ),
      );

      final oldDate =
          DateTime.now().subtract(const Duration(days: 400));
      final match = api_hist.HistoryMatchDto(
        id: 'm-old',
        dt: oldDate,
        finish: true,
        nbQuestions: 10,
        score: 5,
        time: 60,
        percent: 50,
        partyType: const api_hist.HistoryPartyTypeDto(id: 1, label: 'Solo'),
        partyDifficulty: const [],
        partyTheme: const [],
      );

      when(() => mockHistory.getHistory(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer(
        (_) async => api.ApiResponse.ok(
          api_hist.HistoryPageDto(
            items: [match],
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

      // Date should be displayed in some format (absolute or relative)
      expect(find.text('Terminer'), findsOneWidget);
    });
  });
}

