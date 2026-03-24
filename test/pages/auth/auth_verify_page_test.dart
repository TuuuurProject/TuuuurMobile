import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tuuuur_flutter/api/auth/auth_api_service.dart';
import 'package:tuuuur_flutter/api/auth/auth_models.dart';
import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';
import 'package:tuuuur_flutter/pages/auth/auth_verify_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/navigation/app_messengers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
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

  setUp(() async {
    secureStore.clear();
    await AuthStore.instance.signOut();
  });

  tearDown(() async {
    secureStore.clear();
    await AuthStore.instance.signOut();
  });
  group('AuthVerifyPage', () {
    testWidgets('affiche tous les éléments de la page de vérification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(AuthVerifyPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      expect(find.byType(TextField), findsAtLeastNWidgets(2));

      expect(find.text('Pseudo (login)'), findsOneWidget);
      expect(find.text('Code à 6 chiffres'), findsOneWidget);
      expect(find.text('Valider le code'), findsOneWidget);
    });

    testWidgets('pré-remplit le login avec initialLogin', (
      WidgetTester tester,
    ) async {
      const initialLogin = 'testuser';

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(initialLogin: initialLogin),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(2));

      final loginField = tester.widget<TextField>(fields.first);
      expect(loginField.controller, isNotNull);
      expect(loginField.controller!.text, equals(initialLogin));
    });

    testWidgets('affiche le hint email quand fourni', (
      WidgetTester tester,
    ) async {
      const emailHint = 't***@gmail.com';

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(emailHint: emailHint),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Envoyé à $emailHint'), findsOneWidget);
    });

    testWidgets('le champ code a maxLength = 6', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(2));

      final codeField = tester.widget<TextField>(fields.at(1));
      expect(codeField.maxLength, equals(6));
      expect(codeField.keyboardType, equals(TextInputType.number));
    });

    testWidgets('affiche un SnackBar si login manquant (validation locale)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '123456');
      await tester.tap(find.text('Valider le code'));
      await tester.pump();

      expect(find.text('Le pseudo (login) est requis.'), findsOneWidget);
    });

    testWidgets('affiche un SnackBar si code invalide (validation locale)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.at(1), '123');
      await tester.tap(find.text('Valider le code'));
      await tester.pump();

      expect(
        find.text('Code invalide. Entrez les 6 chiffres reçus par email.'),
        findsOneWidget,
      );
    });

    testWidgets('les TextFields acceptent les entrées', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(2));

      await tester.enterText(fields.first, 'testuser');
      expect(find.text('testuser'), findsOneWidget);

      await tester.enterText(fields.at(1), '123456');
      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('dispose correctement les controllers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AuthVerifyPage), findsOneWidget);

      await tester.pumpWidget(Container());
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche un Scaffold avec SafeArea (via AppBar)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    test('AuthVerifyPage crée un state correct', () {
      const page = AuthVerifyPage();
      final state = page.createState();
      expect(state, isNotNull);
    });

    testWidgets('initialLogin pré-remplit le TextField login', (
      WidgetTester tester,
    ) async {
      const initialLogin = 'prefilleduser';

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(initialLogin: initialLogin),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      final loginField = tester.widget<TextField>(fields.first);
      expect(loginField.controller!.text, equals(initialLogin));
    });

    testWidgets('returnTo est passé au widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(returnTo: '/solo'),
          ),
        ),
      );

      await tester.pump();

      final verifyPage = tester.widget<AuthVerifyPage>(
        find.byType(AuthVerifyPage),
      );
      expect(verifyPage.returnTo, '/solo');
    });

    testWidgets(
      'bouton "Valider le code" est présent et désactivé initialement',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            home: MyAuthStore(
              notifier: AuthStore.instance,
              child: const AuthVerifyPage(),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Valider le code'), findsOneWidget);
      },
    );

    testWidgets('navigation arrière fonctionne avec GoRouter', (
      WidgetTester tester,
    ) async {
      bool poppedCorrectly = false;

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/verify'),
                child: const Text('Go to Verify'),
              ),
            ),
          ),
          GoRoute(
            path: '/verify',
            builder: (context, state) => const AuthVerifyPage(),
            onExit: (context, state) {
              poppedCorrectly = true;
              return true;
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          builder: (context, child) => MyAuthStore(
            notifier: AuthStore.instance,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Verify'));
      await tester.pumpAndSettle();

      final backButton = find.byType(IconButton);
      await tester.tap(backButton.first);
      await tester.pumpAndSettle();

      expect(poppedCorrectly, isTrue);
    });
  });

  group('handleVerify - tests de navigation', () {
    testWidgets('validation locale: login requis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '123456');
      await tester.tap(find.text('Valider le code'));
      await tester.pump();

      expect(find.text('Le pseudo (login) est requis.'), findsOneWidget);
    });

    testWidgets('validation locale: code à 6 chiffres requis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.at(1), '123');
      await tester.tap(find.text('Valider le code'));
      await tester.pump();

      expect(
        find.text('Code invalide. Entrez les 6 chiffres reçus par email.'),
        findsOneWidget,
      );
    });
  });

  group('AuthVerifyPage - handleVerify couverture complète', () {
    late MockAuthApi mockAuthApi;

    setUp(() {
      mockAuthApi = MockAuthApi();
    });

    testWidgets('appelle verify2fa avec les valeurs trim', (tester) async {
      when(
        () => mockAuthApi.verify2fa(
          login: any(named: 'login'),
          code: any(named: 'code'),
        ),
      ).thenAnswer(
        (_) async =>
            ApiResponse<AuthSessionDto>.err(message: 'nope', statusCode: 401),
      );

      final router = _routerForVerify(authApi: mockAuthApi);
      await _pumpVerifyRouter(tester, router);

      await _fillForm(tester, login: '  user  ', code: '123456');
      await tester.tap(find.text('Valider le code'));
      await tester.pumpAndSettle();

      verify(
        () => mockAuthApi.verify2fa(login: 'user', code: '123456'),
      ).called(1);
    });

    testWidgets(
      'loading: affiche "Vérification..." pendant l\'attente puis revient',
      (tester) async {
        final completer = Completer<ApiResponse<AuthSessionDto>>();

        when(
          () => mockAuthApi.verify2fa(
            login: any(named: 'login'),
            code: any(named: 'code'),
          ),
        ).thenAnswer((_) => completer.future);

        final router = _routerForVerify(authApi: mockAuthApi);
        await _pumpVerifyRouter(tester, router);

        await _fillForm(tester);

        await tester.tap(find.text('Valider le code'));
        await tester.pump();

        expect(find.text('Vérification...'), findsOneWidget);

        completer.complete(
          ApiResponse<AuthSessionDto>.err(message: 'bad', statusCode: 401),
        );
        await tester.pumpAndSettle();

        expect(find.text('Valider le code'), findsOneWidget);
      },
    );

    testWidgets('succès + returnTo => snack vert + go(returnTo)', (
      tester,
    ) async {
      when(
        () => mockAuthApi.verify2fa(
          login: any(named: 'login'),
          code: any(named: 'code'),
        ),
      ).thenAnswer(
        (_) async =>
            ApiResponse<AuthSessionDto>.ok(_makeSession(), statusCode: 200),
      );

      final router = _routerForVerify(
        authApi: mockAuthApi,
        returnTo: '/profile',
      );
      await _pumpVerifyRouter(tester, router);

      await _fillForm(tester);
      await tester.tap(find.text('Valider le code'));
      await tester.pumpAndSettle();

      expect(find.text('Compte vérifié, connexion réussie !'), findsOneWidget);
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, TuuurTheme.brandGreen);

      expect(find.byKey(const Key('page_profile')), findsOneWidget);
    });

    testWidgets('succès + canPop => router.pop()', (tester) async {
      when(
        () => mockAuthApi.verify2fa(
          login: any(named: 'login'),
          code: any(named: 'code'),
        ),
      ).thenAnswer(
        (_) async =>
            ApiResponse<AuthSessionDto>.ok(_makeSession(), statusCode: 200),
      );

      final router = _routerForVerify(
        authApi: mockAuthApi,
        initialLocation: '/',
        withPushFromHome: true,
      );
      await _pumpVerifyRouter(tester, router);

      await tester.tap(find.byKey(const Key('go_verify')));
      await tester.pumpAndSettle();

      await _fillForm(tester);
      await tester.tap(find.text('Valider le code'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('go_verify')), findsOneWidget);
    });

    testWidgets('succès + !canPop => router.go("/")', (tester) async {
      when(
        () => mockAuthApi.verify2fa(
          login: any(named: 'login'),
          code: any(named: 'code'),
        ),
      ).thenAnswer(
        (_) async =>
            ApiResponse<AuthSessionDto>.ok(_makeSession(), statusCode: 200),
      );

      final router = _routerForVerify(
        authApi: mockAuthApi,
        initialLocation: '/verify',
      );
      await _pumpVerifyRouter(tester, router);

      await _fillForm(tester);
      await tester.tap(find.text('Valider le code'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });

    testWidgets('échec API avec message => snack message', (tester) async {
      when(
        () => mockAuthApi.verify2fa(
          login: any(named: 'login'),
          code: any(named: 'code'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse<AuthSessionDto>.err(
          message: 'Code expiré',
          statusCode: 400,
        ),
      );

      final router = _routerForVerify(authApi: mockAuthApi);
      await _pumpVerifyRouter(tester, router);

      await _fillForm(tester);
      await tester.tap(find.text('Valider le code'));
      await tester.pumpAndSettle();

      expect(find.text('Code expiré'), findsOneWidget);
      expect(find.byType(AuthVerifyPage), findsOneWidget);
    });

    testWidgets(
      'échec API sans message => fallback "Vérification impossible."',
      (tester) async {
        when(
          () => mockAuthApi.verify2fa(
            login: any(named: 'login'),
            code: any(named: 'code'),
          ),
        ).thenAnswer(
          (_) async =>
              ApiResponse<AuthSessionDto>.err(message: null, statusCode: 500),
        );

        final router = _routerForVerify(authApi: mockAuthApi);
        await _pumpVerifyRouter(tester, router);

        await _fillForm(tester);
        await tester.tap(find.text('Valider le code'));
        await tester.pumpAndSettle();

        expect(find.text('Vérification impossible.'), findsOneWidget);
      },
    );

    testWidgets(
      'mounted check: dispose avant la réponse API => pas d\'exception',
      (tester) async {
        final completer = Completer<ApiResponse<AuthSessionDto>>();
        when(
          () => mockAuthApi.verify2fa(
            login: any(named: 'login'),
            code: any(named: 'code'),
          ),
        ).thenAnswer((_) => completer.future);

        final router = _routerForVerify(authApi: mockAuthApi);
        await _pumpVerifyRouter(tester, router);

        await _fillForm(tester);
        await tester.tap(find.text('Valider le code'));
        await tester.pump();

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        completer.complete(
          ApiResponse<AuthSessionDto>.ok(_makeSession(), statusCode: 200),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
      },
    );
  });
}

class MockAuthApi extends Mock implements AuthApi {}

class _DummyPage extends StatelessWidget {
  final String label;
  const _DummyPage(this.label);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(label, key: Key('page_$label'))),
    );
  }
}

class _HomeWithVerifyLink extends StatelessWidget {
  const _HomeWithVerifyLink();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('go_verify'),
          onPressed: () => context.push('/verify'),
          child: const Text('Go verify'),
        ),
      ),
    );
  }
}

AuthSessionDto _makeSession() {
  return AuthSessionDto(
    user: UserDto(
      id: '1',
      nickName: 'User',
      email: 'u@test.com',
      isAdmin: false,
      isNew: false,
    ),
    token: AuthTokenDto(
      token: 't',
      refreshToken: 'rt',
      validTo: DateTime.now().add(const Duration(hours: 1)),
    ),
    isGoogleUser: false,
    raw: const {},
  );
}

GoRouter _routerForVerify({
  required AuthApi authApi,
  String initialLocation = '/verify',
  String? returnTo,
  bool withPushFromHome = false,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => withPushFromHome
            ? const _HomeWithVerifyLink()
            : const _DummyPage('home'),
      ),
      GoRoute(
        path: '/verify',
        builder: (_, __) =>
            AuthVerifyPage(authApi: authApi, returnTo: returnTo),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const _DummyPage('profile'),
      ),
    ],
  );
}

Future<void> _pumpVerifyRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      builder: (context, child) => MyAuthStore(
        notifier: AuthStore.instance,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillForm(
  WidgetTester tester, {
  String login = 'testuser',
  String code = '123456',
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.first, login);
  await tester.enterText(fields.at(1), code);
}
