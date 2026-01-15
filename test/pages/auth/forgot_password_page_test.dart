// forgot_password_page_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth_api_service.dart';
import 'package:tuuuur_flutter/pages/auth/forgot_password_page.dart';
import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';
import 'package:tuuuur_flutter/navigation/app_messengers.dart' show rootScaffoldMessengerKey;


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

/// Fake contrôlable pour éviter les appels réseau.
/// On remplace la variable globale `authApi` par cette instance en test.
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

GoRouter _createRouter({String initialLocation = '/forgot-password'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const _DummyPage('home', pageKey: Key('page_home')),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
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

Future<void> _pumpForgot(WidgetTester tester, {GoRouter? router}) async {
  final r = router ?? _createRouter();
  await tester.pumpWidget(_wrapWithApp(r));
  await tester.pumpAndSettle();
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
    authApi = fake; // <-- on remplace le global pour tous les tests
  });

  tearDownAll(() {
    authApi = originalAuthApi; // <-- on restaure
  });

  group('ForgotPasswordPage - rendu', () {
    testWidgets('affiche les éléments essentiels', (tester) async {
      await _pumpForgot(tester);

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // Titres / textes principaux (selon ton code)
      expect(find.text('Mot de passe oublié'), findsOneWidget);
      expect(find.text('Recevoir un code de réinitialisation'), findsOneWidget);

      // Champ login
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.textInputAction, TextInputAction.done);

      // Boutons
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Envoyer le code'), findsOneWidget);
    });
  });

  group('ForgotPasswordPage - validation & interactions', () {
    testWidgets('validation: login requis => SnackBar', (tester) async {
      await _pumpForgot(tester);

      await tester.tap(find.text('Envoyer le code'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Le login est requis.'), findsOneWidget);

      // Important: pas d’appel API si invalide
      expect(fake.callCount, 0);
    });

    testWidgets('soumission clavier (done) déclenche l’envoi si login rempli', (tester) async {
      await _pumpForgot(tester);

      await tester.enterText(find.byType(TextField), 'testuser');

      // Simule "done" clavier
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(); // lance setState(_isLoading = true)
      await tester.pumpAndSettle();

      expect(fake.callCount, 1);
      expect(fake.lastLogin, 'testuser');
    });

    testWidgets('état loading: le bouton affiche "Envoi..." tant que la requête est en cours', (tester) async {
      await _pumpForgot(tester);

      fake.makePending();

      await tester.enterText(find.byType(TextField), 'testuser');
      await tester.tap(find.text('Envoyer le code'));

      // 1er pump: setState(_isLoading=true)
      await tester.pump();

      expect(find.text('Envoi...'), findsOneWidget);

      // on termine la requête
      fake.completePending(ApiResponse.ok(true, statusCode: 200));
      await tester.pumpAndSettle();

      // Le bouton revient (page a probablement navigué, mais au minimum l'état loading est fini)
      expect(find.text('Envoi...'), findsNothing);
    });

    testWidgets('erreur API => affiche le message et reste sur la page', (tester) async {
      await _pumpForgot(tester);

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

      // Toujours sur ForgotPasswordPage
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('succès API => SnackBar vert + navigation vers /reset-password avec extra', (tester) async {
      await _pumpForgot(tester);

      fake.immediateResponse = ApiResponse.ok(true, statusCode: 200);

      await tester.enterText(find.byType(TextField), 'testuser');
      await tester.tap(find.text('Envoyer le code'));
      await tester.pumpAndSettle();

      // SnackBar succès (texte exact dans ta page)
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Code envoyé par email. Consultez votre boîte 📬'),
        findsOneWidget,
      );

      // Optionnel: si ton helper met bien la couleur demandée
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, TuuurTheme.brandGreen);

      // Navigation
      expect(find.byKey(const Key('page_reset-password')), findsOneWidget);

      // Vérifie l’extra (Map toString => "{login: testuser}")
      final resetText = tester.widget<Text>(find.byKey(const Key('page_reset-password')));
      expect(resetText.data, contains('login: testuser'));
    });
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
      await _pumpForgot(tester);

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
