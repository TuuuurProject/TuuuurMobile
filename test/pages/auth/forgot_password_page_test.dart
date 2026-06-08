import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/api_module.dart' as api_module;
import 'package:tuuuur_flutter/api/auth/auth_api_service.dart';
import 'package:tuuuur_flutter/pages/auth/forgot_password_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';
import 'package:tuuuur_flutter/navigation/app_messengers.dart'
    show rootScaffoldMessengerKey;

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

  int callCount = 0;
  String? lastLogin;

  ApiResponse<bool> immediateResponse = ApiResponse.ok(true, statusCode: 200);

  Completer<ApiResponse<bool>>? _pending;

  void makePending() {
    _pending = Completer<ApiResponse<bool>>();
  }

  void completePending(ApiResponse<bool> response) {
    _pending?.complete(response);
    _pending = null;
  }

  @override
  Future<ApiResponse<bool>> passwordForgot({required String login}) {
    callCount += 1;
    lastLogin = login;

    if (_pending != null) {
      return _pending!.future;
    }
    return Future.value(immediateResponse);
  }
}

GoRouter _createRouter({
  String initialLocation = '/forgot-password',
  AuthApi? authApi,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const _DummyPage('home', pageKey: Key('page_home')),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => ForgotPasswordPage(authApiOverride: authApi),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => _DummyPage(
          'reset-password extra=${state.extra}',
          pageKey: const Key('page_reset-password'),
        ),
      ),
    ],
  );
}

Widget _wrapWithApp(GoRouter router) {
  return MaterialApp.router(
    scaffoldMessengerKey: rootScaffoldMessengerKey,
    routerConfig: router,
  );
}

Future<void> _pumpForgot(
  WidgetTester tester, {
  GoRouter? router,
  AuthApi? authApi,
}) async {
  final r = router ?? _createRouter(authApi: authApi);
  await tester.pumpWidget(_wrapWithApp(r));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthApi fake;

  setUpAll(() {
    try {
      api_module.ApiModule.instance.initialize(authStore: AuthStore.instance);
    } catch (_) {}
  });

  setUp(() {
    fake = _FakeAuthApi();
  });

  group('ForgotPasswordPage - rendu', () {
    testWidgets('affiche les éléments essentiels', (tester) async {
      await _pumpForgot(tester, authApi: fake);

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      expect(find.text('Mot de passe oublié'), findsOneWidget);
      expect(find.text('Recevoir un code de réinitialisation'), findsOneWidget);

      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.textInputAction, TextInputAction.done);

      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Envoyer le code'), findsOneWidget);
    });
  });

  group('ForgotPasswordPage - validation & interactions', () {
    testWidgets('validation: login requis => SnackBar', (tester) async {
      await _pumpForgot(tester, authApi: fake);

      await tester.tap(find.text('Envoyer le code'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Le login est requis.'), findsOneWidget);

      expect(fake.callCount, 0);
    });

    testWidgets('soumission clavier (done) déclenche l’envoi si login rempli', (
      tester,
    ) async {
      await _pumpForgot(tester, authApi: fake);

      await tester.enterText(find.byType(TextField), 'testuser');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fake.callCount, 1);
      expect(fake.lastLogin, 'testuser');
    });

    testWidgets(
      'état loading: le bouton affiche "Envoi..." tant que la requête est en cours',
      (tester) async {
        await _pumpForgot(tester, authApi: fake);

        fake.makePending();

        await tester.enterText(find.byType(TextField), 'testuser');
        await tester.tap(find.text('Envoyer le code'));

        await tester.pump();

        expect(find.text('Envoi...'), findsOneWidget);

        fake.completePending(ApiResponse.ok(true, statusCode: 200));
        await tester.pumpAndSettle();

        expect(find.text('Envoi...'), findsNothing);
      },
    );

    testWidgets('erreur API => affiche le message et reste sur la page', (
      tester,
    ) async {
      await _pumpForgot(tester, authApi: fake);

      fake.immediateResponse = ApiResponse.err(
        message: 'Impossible de démarrer la procédure.',
        statusCode: 400,
      );

      await tester.enterText(find.byType(TextField), 'testuser');
      await tester.tap(find.text('Envoyer le code'));
      await tester.pumpAndSettle();

      expect(fake.callCount, 1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Impossible de démarrer la procédure.'), findsOneWidget);

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets(
      'succès API => SnackBar vert + navigation vers /reset-password avec extra',
      (tester) async {
        await _pumpForgot(tester, authApi: fake);

        fake.immediateResponse = ApiResponse.ok(true, statusCode: 200);

        await tester.enterText(find.byType(TextField), 'testuser');
        await tester.tap(find.text('Envoyer le code'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text('Code envoyé par email. Consultez votre boîte 📬'),
          findsOneWidget,
        );

        final snack = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snack.backgroundColor, TuuurTheme.brandGreen);

        expect(find.byKey(const Key('page_reset-password')), findsOneWidget);

        final resetText = tester.widget<Text>(
          find.byKey(const Key('page_reset-password')),
        );
        expect(resetText.data, contains('login: testuser'));
      },
    );
  });

  group('ForgotPasswordPage - navigation (GoRouter)', () {
    testWidgets('Annuler => retour (goBack) vers home', (tester) async {
      final router = _createRouter(initialLocation: '/forgot-password');
      await _pumpForgot(tester, router: router);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });
  });

  group('ForgotPasswordPage - cycle de vie', () {
    testWidgets('dispose correctement', (tester) async {
      await _pumpForgot(tester, authApi: fake);

      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('crée un State correct', () {
      const page = ForgotPasswordPage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}
