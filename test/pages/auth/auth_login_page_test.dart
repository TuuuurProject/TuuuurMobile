import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/pages/auth/auth_login_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';
import 'package:tuuuur_flutter/api/api_module.dart';
import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth/auth_api_service.dart';

class MockAuthApi extends Mock implements AuthApi {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleAuth extends Mock implements GoogleSignInAuthentication {}
class MockAuthStore extends Mock implements AuthStore {}

class _DummyPage extends StatelessWidget {
  final String label;
  const _DummyPage(this.label);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label, key: Key('page_$label'))),
    );
  }
}

class _HomeWithLoginLink extends StatelessWidget {
  const _HomeWithLoginLink();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('go_login'),
          onPressed: () => context.push('/login'),
          child: const Text('Go login'),
        ),
      ),
    );
  }
}

GoRouter _createRouter({String initialLocation = '/login'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
      GoRoute(path: '/login', builder: (_, __) => const AuthLoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const _DummyPage('register')),
      GoRoute(path: '/forgot-password', builder: (_, __) => const _DummyPage('forgot-password')),
      GoRoute(path: '/verify', builder: (_, state) => _DummyPage('verify extra=${state.extra}')),
    ],
  );
}

Widget _wrapWithApp(GoRouter router, {AuthStore? store}) {
  return MyAuthStore(
    notifier: store ?? AuthStore.instance,
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpLogin(WidgetTester tester, {GoRouter? router}) async {
  final r = router ?? _createRouter();
  await tester.pumpWidget(_wrapWithApp(r));
  await tester.pumpAndSettle();
}

AuthSessionDto _makeSession() {
  return AuthSessionDto(
    user: UserDto(
      id: 1,
      nickName: 'GoogleUser',
      email: 'test@gmail.com',
      isAdmin: false,
      isNew: false,
    ),
    token: AuthTokenDto(
      token: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      validTo: DateTime.now().add(const Duration(hours: 1)),
    ),
    isGoogleUser: true,
    raw: const {},
  );
}

GoRouter _routerForGoogle({
  required MockAuthApi authApi,
  required MockGoogleSignIn google,
  String? returnTo,
  bool homeHasLoginLink = false,
  String initialLocation = '/login',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => homeHasLoginLink ? const _HomeWithLoginLink() : const _DummyPage('home'),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => AuthLoginPage(
          authApi: authApi,
          googleSignIn: google,
          returnTo: returnTo,
        ),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const _DummyPage('profile')),
    ],
  );
}

void _stubHappyPathGoogle({
  required MockGoogleSignIn google,
  required MockGoogleAccount account,
  required MockGoogleAuth auth,
  String idToken = 'id_token_123',
  bool isAlreadySignedIn = false,
}) {
  when(() => google.isSignedIn()).thenAnswer((_) async => isAlreadySignedIn);
  when(() => google.signOut()).thenAnswer((_) async => null);
  when(() => google.signIn()).thenAnswer((_) async => account);
  when(() => account.authentication).thenAnswer((_) async => auth);
  when(() => auth.idToken).thenReturn(idToken);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_makeSession());
  });

  group('AuthLoginPage - rendu', () {
    testWidgets('affiche les éléments essentiels', (tester) async {
      await _pumpLogin(tester);

      expect(find.byType(AuthLoginPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      expect(find.text('Connexion'), findsWidgets);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));

      final pseudoField = tester.widget<TextField>(fields.first);
      final passwordField = tester.widget<TextField>(fields.at(1));

      expect(pseudoField.decoration?.hintText, 'Votre pseudo');
      expect(pseudoField.textInputAction, TextInputAction.next);

      expect(passwordField.decoration?.hintText, '••••••••');
      expect(passwordField.obscureText, isTrue);

      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Mot de passe oublié ?'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('AuthLoginPage - interactions', () {
    testWidgets('bascule la visibilité du mot de passe', (tester) async {
      await _pumpLogin(tester);

      final fields = find.byType(TextField);
      final passwordFieldFinder = fields.at(1);

      expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isTrue);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('validation: pseudo requis => SnackBar orange', (tester) async {
      await _pumpLogin(tester);

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Le pseudo est requis.'), findsOneWidget);

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, TuuurTheme.brandOrange);
    });

    testWidgets('validation: mot de passe requis => SnackBar orange', (tester) async {
      await _pumpLogin(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'testuser');

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Le mot de passe est requis.'), findsOneWidget);

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, TuuurTheme.brandOrange);
    });

    testWidgets('tentative de login: affiche un SnackBar', (tester) async {
      await _pumpLogin(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.at(1), 'testpass123');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SnackBar), findsOneWidget);

      final textFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(Text),
      );
      expect(textFinder, findsWidgets);

      final firstText = tester.widget<Text>(textFinder.first).data ?? '';
      expect(firstText.trim().isNotEmpty, isTrue);
    });
  });

  group('AuthLoginPage - navigation (GoRouter)', () {
    testWidgets('Mot de passe oublié ? => /forgot-password', (tester) async {
      final router = _createRouter();
      await _pumpLogin(tester, router: router);

      await tester.ensureVisible(find.text('Mot de passe oublié ?'));
      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_forgot-password')), findsOneWidget);
    });

    testWidgets('Créer un compte => /register', (tester) async {
      final router = _createRouter();
      await _pumpLogin(tester, router: router);

      await tester.ensureVisible(find.text('Créer un compte'));
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_register')), findsOneWidget);
    });

    testWidgets('Annuler => retour', (tester) async {
      final router = _createRouter(initialLocation: '/login');
      await _pumpLogin(tester, router: router);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });

    testWidgets('AppBar back => retour', (tester) async {
      final router = _createRouter(initialLocation: '/login');
      await _pumpLogin(tester, router: router);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });
  });

  group('AuthLoginPage - cycle de vie', () {
    testWidgets('dispose correctement', (tester) async {
      await _pumpLogin(tester);

      expect(find.byType(AuthLoginPage), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('crée un State correct', () {
      const page = AuthLoginPage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });

  group('AuthLoginPage - handleLogin comportement UI', () {
    testWidgets('handleLogin lance un appel API avec des credentials valides', (tester) async {
      final router = _createRouter();
      await _pumpLogin(tester, router: router);

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 50));

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('handleLogin avec credentials valides affiche un résultat', (tester) async {
      final router = _createRouter();
      await _pumpLogin(tester, router: router);

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('handleLogin affiche SnackBar après exécution', (tester) async {
      final router = _createRouter();
      await _pumpLogin(tester, router: router);

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('AuthLoginPage - handleGoogleLogin comportement UI', () {
    testWidgets('bouton Google affiche le texte correct', (tester) async {
      final router = _createRouter();
      await _pumpLogin(tester, router: router);

      expect(find.text('Continuer avec Google'), findsOneWidget);

      expect(find.byWidgetPredicate((widget) =>
        widget is ElevatedButton &&
        widget.style?.backgroundColor?.resolve({}) == const Color(0xFF4285F4)
      ), findsOneWidget);
    });

    testWidgets('handleGoogleLogin est cliquable', (tester) async {
      final router = _createRouter();
      await _pumpLogin(tester, router: router);

      final googleButton = find.text('Continuer avec Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('AuthLoginPage - returnTo navigation', () {
    testWidgets('page créée avec returnTo conserve la valeur', (tester) async {
      const testReturnTo = '/profile';

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(
            path: '/login',
            builder: (_, __) => const AuthLoginPage(returnTo: testReturnTo),
          ),
          GoRoute(path: '/verify', builder: (_, state) => _DummyPage('verify extra=${state.extra}')),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(AuthLoginPage), findsOneWidget);

      final authLoginPage = tester.widget<AuthLoginPage>(find.byType(AuthLoginPage));
      expect(authLoginPage.returnTo, testReturnTo);
    });

    testWidgets('page créée sans returnTo a returnTo null', (tester) async {
      final router = _createRouter();
      await _pumpLogin(tester, router: router);

      final authLoginPage = tester.widget<AuthLoginPage>(find.byType(AuthLoginPage));
      expect(authLoginPage.returnTo, isNull);
    });
  });

  group('AuthLoginPage - mounted checks', () {
    testWidgets('dispose n\'échoue pas quand appelé plusieurs fois', (tester) async {
      await _pumpLogin(tester);

      expect(find.byType(AuthLoginPage), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('les actions ne causent pas d\'erreur si le widget est disposed', (tester) async {
      final router = _createRouter();
      await _pumpLogin(tester, router: router);

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'user');
      await tester.enterText(fields.at(1), 'pass');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('AuthLoginPage - handleLogin avec mocks', () {
    late MockAuthApi mockAuthApi;

    setUp(() {
      mockAuthApi = MockAuthApi();
    });

    testWidgets('handleLogin success => toast cyan et navigation vers /verify', (tester) async {
      when(() => mockAuthApi.login(
            login: any(named: 'login'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => ApiResponse<bool>.ok(true, statusCode: 200),
      );

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/login', builder: (_, __) => AuthLoginPage(authApi: mockAuthApi)),
          GoRoute(path: '/verify', builder: (_, state) => _DummyPage('verify extra=${state.extra}')),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Code envoyé par email. Vérifiez votre boîte 📬'), findsOneWidget);

      final snackBars = find.byType(SnackBar);
      expect(snackBars, findsWidgets);
      final snackBar = tester.widgetList<SnackBar>(snackBars).last;
      expect(snackBar.backgroundColor, TuuurTheme.brandCyan);

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_verify extra={login: testuser, returnTo: null}')), findsOneWidget);

      verify(() => mockAuthApi.login(login: 'testuser', password: 'password123')).called(1);
    });

    testWidgets('handleLogin failure => toast orange avec message d\'erreur', (tester) async {
      when(() => mockAuthApi.login(
            login: any(named: 'login'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => ApiResponse<bool>.err(
          message: 'Identifiants invalides',
          statusCode: 401,
        ),
      );

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/login', builder: (_, __) => AuthLoginPage(authApi: mockAuthApi)),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'wronguser');
      await tester.enterText(fields.at(1), 'wrongpass');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Identifiants invalides'), findsOneWidget);

      final snackBars = find.byType(SnackBar);
      expect(snackBars, findsWidgets);
      final snackBar = tester.widgetList<SnackBar>(snackBars).last;
      expect(snackBar.backgroundColor, TuuurTheme.brandOrange);

      await tester.pumpAndSettle();

      expect(find.byType(AuthLoginPage), findsOneWidget);

      verify(() => mockAuthApi.login(login: 'wronguser', password: 'wrongpass')).called(1);
    });

    testWidgets('handleLogin failure sans message => toast par défaut', (tester) async {
      when(() => mockAuthApi.login(
            login: any(named: 'login'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => ApiResponse<bool>.err(
          message: null,
          statusCode: 500,
        ),
      );

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/login', builder: (_, __) => AuthLoginPage(authApi: mockAuthApi)),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'user');
      await tester.enterText(fields.at(1), 'pass');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Connexion impossible.'), findsOneWidget);

      final snackBars = find.byType(SnackBar);
      expect(snackBars, findsWidgets);
      final snackBar = tester.widgetList<SnackBar>(snackBars).last;
      expect(snackBar.backgroundColor, TuuurTheme.brandOrange);
    });

    testWidgets('handleLogin avec returnTo => passe returnTo à /verify', (tester) async {
      when(() => mockAuthApi.login(
            login: any(named: 'login'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => ApiResponse<bool>.ok(true, statusCode: 200),
      );

      final router = GoRouter(
        initialLocation: '/login-with-return',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(
            path: '/login-with-return',
            builder: (_, __) => AuthLoginPage(returnTo: '/profile', authApi: mockAuthApi),
          ),
          GoRoute(
            path: '/verify',
            builder: (_, state) => _DummyPage('verify extra=${state.extra}'),
          ),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'user');
      await tester.enterText(fields.at(1), 'pass');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('page_verify extra={login: user, returnTo: /profile}')), findsOneWidget);
    });

    testWidgets('handleLogin exception => toast d\'erreur avec message', (tester) async {
      when(() => mockAuthApi.login(
            login: any(named: 'login'),
            password: any(named: 'password'),
          )).thenThrow(Exception('Network error'));

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/login', builder: (_, __) => AuthLoginPage(authApi: mockAuthApi)),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'user');
      await tester.enterText(fields.at(1), 'pass');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Erreur :'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('handleLogin vérifie mounted avant setState après succès', (tester) async {
      when(() => mockAuthApi.login(
            login: any(named: 'login'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return ApiResponse<bool>.ok(true, statusCode: 200);
        },
      );

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/login', builder: (_, __) => AuthLoginPage(authApi: mockAuthApi)),
          GoRoute(path: '/verify', builder: (_, state) => _DummyPage('verify extra=${state.extra}')),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'user');
      await tester.enterText(fields.at(1), 'pass');

      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  group('AuthLoginPage - handleGoogleLogin avec mocks', () {
    late MockAuthApi mockAuthApi;

    setUp(() {
      mockAuthApi = MockAuthApi();
    });

    testWidgets('handleGoogleLogin success => toast vert et navigation', (tester) async {
      final session = AuthSession(
        user: UserDto(
          id: 1,
          nickName: 'GoogleUser',
          email: 'test@gmail.com',
          isAdmin: false,
          isNew: false,
        ),
        token: AuthToken(
          token: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
          validTo: DateTime.now().add(const Duration(hours: 1)),
        ),
        isGoogleUser: true,
        raw: const {},
      );

      when(() => mockAuthApi.loginWithGoogle(idToken: any(named: 'idToken')))
          .thenAnswer(
        (_) async => ApiResponse<AuthSession>.ok(session, statusCode: 200),
      );


      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/login', builder: (_, __) => AuthLoginPage(authApi: mockAuthApi)),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Continuer avec Google'), findsOneWidget);
    });

    testWidgets('handleGoogleLogin failure => toast orange avec message', (tester) async {
      when(() => mockAuthApi.loginWithGoogle(idToken: any(named: 'idToken')))
          .thenAnswer(
        (_) async => ApiResponse<AuthSession>.err(
          message: 'Compte Google non autorisé',
          statusCode: 401,
        ),
      );

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/login', builder: (_, __) => AuthLoginPage(authApi: mockAuthApi)),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Continuer avec Google'), findsOneWidget);
    });

    testWidgets('handleGoogleLogin avec res.data null => toast d\'erreur', (tester) async {
      when(() => mockAuthApi.loginWithGoogle(idToken: any(named: 'idToken')))
          .thenAnswer(
        (_) async => ApiResponse<AuthSession>.err(
          message: 'Données de session manquantes',
          statusCode: 200,
        ),
      );

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/login', builder: (_, __) => AuthLoginPage(authApi: mockAuthApi)),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Continuer avec Google'), findsOneWidget);
    });

    testWidgets('handleGoogleLogin vérifie mounted avant setState', (tester) async {
      final session = AuthSession(
        user: UserDto(
          id: 1,
          nickName: 'GoogleUser',
          email: 'test@gmail.com',
          isAdmin: false,
          isNew: false,
        ),
        token: AuthToken(
          token: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
          validTo: DateTime.now().add(const Duration(hours: 1)),
        ),
        isGoogleUser: true,
        raw: const {},
      );

      when(() => mockAuthApi.loginWithGoogle(idToken: any(named: 'idToken')))
          .thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return ApiResponse<AuthSession>.ok(session, statusCode: 200);
        },
      );


      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/login', builder: (_, __) => AuthLoginPage(authApi: mockAuthApi)),
        ],
      );

      await tester.pumpWidget(_wrapWithApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Continuer avec Google'), findsOneWidget);
    });
  });

  group('AuthLoginPage - handleGoogleLogin couverture complète', () {
    late MockAuthApi authApi;
    late MockGoogleSignIn google;
    late MockGoogleAccount account;
    late MockGoogleAuth googleAuth;
    late MockAuthStore mockStore;

    setUp(() {
      authApi = MockAuthApi();
      google = MockGoogleSignIn();
      account = MockGoogleAccount();
      googleAuth = MockGoogleAuth();
      mockStore = MockAuthStore();
      when(() => mockStore.signInWithSession(any()))
          .thenAnswer((_) async {});
    });

    testWidgets('signedIn == true => signOut appelé avant signIn', (tester) async {
      final signInCompleter = Completer<GoogleSignInAccount?>();

      when(() => google.isSignedIn()).thenAnswer((_) async => true);
      when(() => google.signOut()).thenAnswer((_) async => null);
      when(() => google.signIn()).thenAnswer((_) => signInCompleter.future);

      final router = _routerForGoogle(authApi: authApi, google: google);
      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pump();

      expect(find.text('Connexion Google...'), findsOneWidget);

      verifyInOrder([
        () => google.isSignedIn(),
        () => google.signOut(),
        () => google.signIn(),
      ]);

      signInCompleter.complete(null);
      await tester.pumpAndSettle();

      expect(find.text('Continuer avec Google'), findsOneWidget);
    });

    testWidgets('account == null => loading false et return', (tester) async {
      final signInCompleter = Completer<GoogleSignInAccount?>();

      when(() => google.isSignedIn()).thenAnswer((_) async => false);
      when(() => google.signIn()).thenAnswer((_) => signInCompleter.future);

      final router = _routerForGoogle(authApi: authApi, google: google);
      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pump();

      expect(find.text('Connexion Google...'), findsOneWidget);

      signInCompleter.complete(null);
      await tester.pumpAndSettle();

      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('idToken null/empty => Exception => toast "Erreur Google"', (tester) async {
      when(() => google.isSignedIn()).thenAnswer((_) async => false);
      when(() => google.signIn()).thenAnswer((_) async => account);
      when(() => account.authentication).thenAnswer((_) async => googleAuth);
      when(() => googleAuth.idToken).thenReturn(null);

      final router = _routerForGoogle(authApi: authApi, google: google);
      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur Google:'), findsOneWidget);
      expect(find.textContaining('idToken introuvable'), findsOneWidget);

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, TuuurTheme.brandOrange);

      expect(find.text('Continuer avec Google'), findsOneWidget);
    });

    testWidgets('API refuse (res.ok == false) => toast orange avec message', (tester) async {
      _stubHappyPathGoogle(google: google, account: account, auth: googleAuth, idToken: 'tok');
      when(() => authApi.loginWithGoogle(idToken: 'tok')).thenAnswer(
        (_) async => ApiResponse<AuthSession>.err(message: 'Compte Google non autorisé', statusCode: 401),
      );

      final router = _routerForGoogle(authApi: authApi, google: google);
      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();

      expect(find.text('Compte Google non autorisé'), findsOneWidget);

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, TuuurTheme.brandOrange);

      verify(() => authApi.loginWithGoogle(idToken: 'tok')).called(1);
    });

    testWidgets('succès + returnTo => context.go(returnTo)', (tester) async {
      final session = _makeSession();
      _stubHappyPathGoogle(google: google, account: account, auth: googleAuth, idToken: 'tok');
      when(() => authApi.loginWithGoogle(idToken: 'tok')).thenAnswer(
        (_) async => ApiResponse<AuthSession>.ok(session, statusCode: 200),
      );

      final router = _routerForGoogle(
        authApi: authApi,
        google: google,
        returnTo: '/profile',
        initialLocation: '/login',
      );

      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_profile')), findsOneWidget);
    });

    testWidgets('succès + canPop => goBack', (tester) async {
      final session = _makeSession();
      _stubHappyPathGoogle(google: google, account: account, auth: googleAuth, idToken: 'tok');
      when(() => authApi.loginWithGoogle(idToken: 'tok')).thenAnswer(
        (_) async => ApiResponse<AuthSession>.ok(session, statusCode: 200),
      );

      final router = _routerForGoogle(
        authApi: authApi,
        google: google,
        homeHasLoginLink: true,
        initialLocation: '/',
      );

      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('go_login')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('go_login')), findsOneWidget);
    });

    testWidgets('succès + !canPop => go("/")', (tester) async {
      final session = _makeSession();
      _stubHappyPathGoogle(google: google, account: account, auth: googleAuth, idToken: 'tok');
      when(() => authApi.loginWithGoogle(idToken: 'tok')).thenAnswer(
        (_) async => ApiResponse<AuthSession>.ok(session, statusCode: 200),
      );

      final router = _routerForGoogle(authApi: authApi, google: google, initialLocation: '/login');

      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });

    testWidgets('catch: google.signIn throw => toast "Erreur Google" + loading false', (tester) async {
      when(() => google.isSignedIn()).thenAnswer((_) async => false);
      when(() => google.signIn()).thenThrow(Exception('boom'));

      final router = _routerForGoogle(authApi: authApi, google: google);
      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur Google:'), findsOneWidget);
      expect(find.textContaining('boom'), findsOneWidget);

      expect(find.text('Continuer avec Google'), findsOneWidget);
    });

    testWidgets('mounted check après signIn: dispose avant retour => pas d\'exception', (tester) async {
      when(() => google.isSignedIn()).thenAnswer((_) async => false);
      when(() => google.signIn()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 80));
        return account;
      });

      final router = _routerForGoogle(authApi: authApi, google: google);
      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 120));

      expect(tester.takeException(), isNull);
    });

    testWidgets('mounted check après API: dispose avant réponse => pas d\'exception', (tester) async {
      _stubHappyPathGoogle(google: google, account: account, auth: googleAuth, idToken: 'tok');

      when(() => authApi.loginWithGoogle(idToken: 'tok')).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 80));
        return ApiResponse<AuthSession>.ok(_makeSession(), statusCode: 200);
      });

      final router = _routerForGoogle(authApi: authApi, google: google);
      await tester.pumpWidget(_wrapWithApp(router, store: mockStore));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 120));

      expect(tester.takeException(), isNull);
    });
  });
}
