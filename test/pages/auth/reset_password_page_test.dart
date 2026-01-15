import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth_api_service.dart';
import 'package:tuuuur_flutter/navigation/app_messengers.dart'
    show rootScaffoldMessengerKey;
import 'package:tuuuur_flutter/pages/auth/reset_password_page.dart';
import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';

class _DummyPage extends StatelessWidget {
  final String label;
  final Key pageKey;

  const _DummyPage(this.label, {required this.pageKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label, key: pageKey)),
    );
  }
}

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(ApiClient(baseUrl: 'http://localhost'));

  int resetCount = 0;
  String? lastLogin;
  String? lastCode;
  String? lastPassword;

  ApiResponse<bool> immediateResponse = ApiResponse.ok(true, statusCode: 200);

  Completer<ApiResponse<bool>>? _pending;
  void makePending() => _pending = Completer<ApiResponse<bool>>();
  void completePending(ApiResponse<bool> res) {
    _pending?.complete(res);
    _pending = null;
  }

  @override
  Future<ApiResponse<bool>> passwordReset({
    required String login,
    required String code,
    required String password,
  }) {
    resetCount += 1;
    lastLogin = login;
    lastCode = code;
    lastPassword = password;

    if (_pending != null) return _pending!.future;
    return Future.value(immediateResponse);
  }
}

GoRouter _createRouter({String initialLocation = '/' , String? initialLogin}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const _DummyPage('home', pageKey: Key('page_home')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const _DummyPage('login', pageKey: Key('page_login')),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => ResetPasswordPage(initialLogin: initialLogin),
      ),
    ],
  );
}

Widget _wrapWithApp(GoRouter router) {
  return MaterialApp.router(
    scaffoldMessengerKey: rootScaffoldMessengerKey, // ✅ crucial pour AuthSnackbars
    routerConfig: router,
  );
}

Future<void> _pumpReset(
  WidgetTester tester, {
  GoRouter? router,
  String initialLocation = '/',
  String? initialLogin,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 2000));
  addTearDown(() async => tester.binding.setSurfaceSize(null));

  final r = router ?? _createRouter(initialLocation: initialLocation, initialLogin: initialLogin);
  await tester.pumpWidget(_wrapWithApp(r));
  await tester.pumpAndSettle();
}

Finder _tf(int index) => find.byType(TextField).at(index);

Future<void> _fillForm(
  WidgetTester tester, {
  required String login,
  required String code,
  required String password,
  required String confirm,
}) async {
  // ✅ la page a 4 TextField (login, code, pwd, confirm)
  expect(find.byType(TextField), findsNWidgets(4));

  await tester.enterText(_tf(0), login);
  await tester.enterText(_tf(1), code);
  await tester.enterText(_tf(2), password);
  await tester.enterText(_tf(3), confirm);
  await tester.pump();
}

Future<void> _tapFinder(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tapPrimaryButton(WidgetTester tester, String label) async {
  // Trouve le widget parent tappable autour du texte
  final btn = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) =>
        w.runtimeType.toString() == 'GamingButtonPrimary' ||
        w is ElevatedButton ||
        w is TextButton ||
        w is OutlinedButton ||
        w is InkWell ||
        w is GestureDetector),
  );

  // Si ton GamingButtonPrimary n’est pas capturé par predicate (rare),
  // on fallback sur le texte mais sans warning fatal.
  final target = btn.evaluate().isNotEmpty ? btn.first : find.text(label);

  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthApi originalAuthApi;
  late _FakeAuthApi fake;

  setUpAll(() {
    originalAuthApi = authApi;
  });

  setUp(() {
    fake = _FakeAuthApi();
    authApi = fake;
  });

  tearDownAll(() {
    authApi = originalAuthApi;
  });

  group('ResetPasswordPage - rendu', () {
    testWidgets('affiche les éléments essentiels', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      expect(find.byType(ResetPasswordPage), findsOneWidget);

      expect(find.text('Réinitialiser le mot de passe'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Code reçu par email'), findsOneWidget);
      expect(find.text('Nouveau mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);

      expect(find.byType(TextField), findsNWidgets(4));

      await tester.ensureVisible(find.text('Valider'));
      expect(find.text('Valider'), findsOneWidget);

      await tester.ensureVisible(find.text('Annuler'));
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('préremplit le login si initialLogin est fourni', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password', initialLogin: 'prefillUser');
      await _pumpReset(tester, router: router);

      final loginField = tester.widget<TextField>(_tf(0));
      expect(loginField.controller?.text, 'prefillUser');
    });
  });

  group('ResetPasswordPage - validations', () {
    testWidgets('login requis', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      await _tapPrimaryButton(tester, 'Valider');

      expect(find.text('Le login est requis.'), findsOneWidget);
      expect(fake.resetCount, 0);
    });

    testWidgets('code requis', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      await _fillForm(
        tester,
        login: 'user',
        code: '',
        password: 'Abcd1234',
        confirm: 'Abcd1234',
      );

      await _tapPrimaryButton(tester, 'Valider');

      expect(find.text('Le code est requis.'), findsOneWidget);
      expect(fake.resetCount, 0);
    });

    testWidgets('nouveau mot de passe requis', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      await _fillForm(
        tester,
        login: 'user',
        code: '123456',
        password: '',
        confirm: '',
      );

      await _tapPrimaryButton(tester, 'Valider');

      expect(find.text('Le nouveau mot de passe est requis.'), findsOneWidget);
      expect(fake.resetCount, 0);
    });

    testWidgets('mot de passe invalide', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      await _fillForm(
        tester,
        login: 'user',
        code: '123456',
        password: 'password',
        confirm: 'password',
      );

      await _tapPrimaryButton(tester, 'Valider');

      expect(
        find.text('Mot de passe invalide : min 8, 1 maj, 1 min, 1 chiffre.'),
        findsOneWidget,
      );
      expect(fake.resetCount, 0);
    });

    testWidgets('mots de passe différents', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      await _fillForm(
        tester,
        login: 'user',
        code: '123456',
        password: 'Abcd1234',
        confirm: 'Abcd12345',
      );

      await _tapPrimaryButton(tester, 'Valider');

      expect(find.text('Les mots de passe ne correspondent pas.'), findsOneWidget);
      expect(fake.resetCount, 0);
    });
  });

  group('ResetPasswordPage - interactions', () {
    testWidgets('bascule la visibilité (icône oeil)', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      // 2 champs password => 2 yeux
      await tester.ensureVisible(find.byIcon(Icons.visibility).first);
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.visibility).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('submit clavier (done) sur confirm déclenche reset', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      fake.immediateResponse = ApiResponse.err(message: 'KO', statusCode: 400);

      await _fillForm(
        tester,
        login: 'user',
        code: '123456',
        password: 'Abcd1234',
        confirm: 'Abcd1234',
      );

      // ✅ il faut focus le champ confirm avant receiveAction
      await tester.tap(_tf(3));
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fake.resetCount, 1);
    });

    testWidgets('loading: "Validation..." pendant la requête', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      fake.makePending();

      await _fillForm(
        tester,
        login: 'user',
        code: '123456',
        password: 'Abcd1234',
        confirm: 'Abcd1234',
      );

      await _tapPrimaryButton(tester, 'Valider');
      expect(find.text('Validation...'), findsOneWidget);

      fake.completePending(ApiResponse.ok(true, statusCode: 200));
      await tester.pumpAndSettle();
    });
  });

  group('ResetPasswordPage - API & navigation', () {
    testWidgets('erreur API => affiche message et reste', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      fake.immediateResponse = ApiResponse.err(
        message: 'Réinitialisation impossible.',
        statusCode: 400,
      );

      await _fillForm(
        tester,
        login: 'user',
        code: '123456',
        password: 'Abcd1234',
        confirm: 'Abcd1234',
      );

      await _tapPrimaryButton(tester, 'Valider');

      expect(fake.resetCount, 1);
      expect(find.text('Réinitialisation impossible.'), findsOneWidget);
      expect(find.byType(ResetPasswordPage), findsOneWidget);
    });

    testWidgets('succès API => SnackBar vert + go(/login)', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      fake.immediateResponse = ApiResponse.ok(true, statusCode: 200);

      await _fillForm(
        tester,
        login: 'user',
        code: '123456',
        password: 'Abcd1234',
        confirm: 'Abcd1234',
      );

      await _tapPrimaryButton(tester, 'Valider');

      // SnackBar succès (juste après le tap)
      expect(find.text('Mot de passe réinitialisé ✅'), findsOneWidget);
      final msg = find.text('Mot de passe réinitialisé ✅');
      expect(msg, findsOneWidget);

      final snackFinder = find.byWidgetPredicate((w) {
        if (w is! SnackBar) return false;
        final c = w.content;
        return c is Text && c.data == 'Mot de passe réinitialisé ✅';
      });
      expect(snackFinder, findsWidgets);

      final snacks = tester.widgetList<SnackBar>(snackFinder).toList();
      final last = snacks.last;
      expect(last.backgroundColor, TuuurTheme.brandGreen);

      await _tapPrimaryButton(tester, 'Valider');
      await tester.pump();

      // Puis navigation
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('page_login')), findsOneWidget);
    });
  });

  group('ResetPasswordPage - navigation (GoRouter)', () {
    testWidgets('Annuler => goBack (pop) vers home (avec historique)', (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpReset(tester, router: router);

      // ✅ push pour créer un historique (go remplace, push empile)
      router.push('/reset-password');
      await tester.pumpAndSettle();

      await _tapPrimaryButton(tester, 'Annuler');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });

    testWidgets('AppBar back => goBack (pop) vers home (avec historique)', (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpReset(tester, router: router);

      router.push('/reset-password');
      await tester.pumpAndSettle();

      await _tapFinder(tester, find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });
  });

  group('ResetPasswordPage - cycle de vie', () {
    testWidgets('dispose correctement', (tester) async {
      final router = _createRouter(initialLocation: '/reset-password');
      await _pumpReset(tester, router: router);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('crée un State correct', () {
      const page = ResetPasswordPage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}
