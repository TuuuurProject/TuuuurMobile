import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/api_module.dart' as api_module;
import 'package:tuuuur_flutter/api/auth/auth_api_service.dart';
import 'package:tuuuur_flutter/navigation/app_messengers.dart'
    show rootScaffoldMessengerKey;
import 'package:tuuuur_flutter/pages/auth/change_password_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';
import 'package:tuuuur_flutter/widgets/gaming_widgets.dart';

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
  String? lastCurrentPassword;
  String? lastNewPassword;
  Map<String, String>? lastHeaders;

  ApiResponse<bool> immediateResponse = ApiResponse.ok(true, statusCode: 200);

  Completer<ApiResponse<bool>>? _pending;
  void makePending() => _pending = Completer<ApiResponse<bool>>();
  void completePending(ApiResponse<bool> res) {
    _pending?.complete(res);
    _pending = null;
  }

  @override
  Future<ApiResponse<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
    Map<String, String>? headers,
  }) {
    callCount += 1;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    lastHeaders = headers;

    if (_pending != null) return _pending!.future;
    return Future.value(immediateResponse);
  }
}

GoRouter _createRouter({String initialLocation = '/', AuthApi? authApi}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const _DummyPage('home', pageKey: Key('page_home')),
      ),
      GoRoute(
        path: '/change-password',
        builder: (_, __) => ChangePasswordPage(authApiOverride: authApi),
      ),
    ],
  );
}

Widget _wrapWithApp(GoRouter router) {
  return MyAuthStore(
    notifier: AuthStore.instance,
    child: MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
    ),
  );
}

Future<void> _pumpApp(WidgetTester tester, GoRouter router) async {
  await tester.binding.setSurfaceSize(const Size(1200, 2000));
  addTearDown(() async => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(_wrapWithApp(router));
  await tester.pumpAndSettle();
}

Future<void> _openChangePasswordPage(WidgetTester tester, GoRouter router) async {
  router.push('/change-password');
  await tester.pumpAndSettle();
  expect(find.byType(ChangePasswordPage), findsOneWidget);
}

Finder _tf(int index) => find.byType(TextField).at(index);

Future<void> _fillForm(
  WidgetTester tester, {
  required String current,
  required String next,
  required String confirm,
}) async {
  expect(find.byType(TextField), findsNWidgets(3));

  await tester.enterText(_tf(0), current);
  await tester.enterText(_tf(1), next);
  await tester.enterText(_tf(2), confirm);
  await tester.pump();
}

Future<void> _tapFinder(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Finder _snackBarWithMessage(String msg) {
  return find.byWidgetPredicate((w) {
    if (w is! SnackBar) return false;
    final c = w.content;
    return c is Text && c.data == msg;
  });
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

  group('ChangePasswordPage - rendu', () {
    testWidgets('affiche les éléments essentiels', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      expect(find.text('Réinitialiser le mot de passe'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      expect(find.text('Mot de passe actuel'), findsOneWidget);
      expect(find.text('Nouveau mot de passe'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.byType(GamingButtonSecondary), findsOneWidget);
      expect(find.byType(GamingButtonPrimary), findsOneWidget);

      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Valider'), findsOneWidget);
    });
  });

  group('ChangePasswordPage - validations', () {
    testWidgets('champs requis', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      await _tapFinder(tester, find.byType(GamingButtonPrimary));

      expect(find.text('Tous les champs sont requis.'), findsWidgets);
      expect(fake.callCount, 0);
    });

    testWidgets('mots de passe différents', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      await _fillForm(
        tester,
        current: 'OldPass123',
        next: 'NewPass123',
        confirm: 'NewPass124',
      );

      await _tapFinder(tester, find.byType(GamingButtonPrimary));

      expect(find.text('Les mots de passe ne correspondent pas.'), findsWidgets);
      expect(fake.callCount, 0);
    });

    testWidgets('complexité non respectée', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      await _fillForm(
        tester,
        current: 'OldPass123',
        next: 'password',
        confirm: 'password',
      );

      await _tapFinder(tester, find.byType(GamingButtonPrimary));

      expect(
        find.text('Nouveau mot de passe invalide (min 8, 1 maj, 1 min, 1 chiffre).'),
        findsWidgets,
      );
      expect(fake.callCount, 0);
    });
  });

  group('ChangePasswordPage - interactions', () {
    testWidgets('bascule la visibilité (icône oeil)', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      expect(find.byIcon(Icons.visibility), findsNWidgets(3));

      await _tapFinder(tester, find.byIcon(Icons.visibility).first);

      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    });

    testWidgets('submit clavier (done) sur confirm déclenche changePassword', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      fake.immediateResponse = ApiResponse.err(message: 'KO', statusCode: 400);

      await _fillForm(
        tester,
        current: 'OldPass123',
        next: 'NewPass123',
        confirm: 'NewPass123',
      );

      await _tapFinder(tester, _tf(2));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fake.callCount, 1);
    });

    testWidgets('loading: "Mise à jour…" + champs désactivés', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      fake.makePending();

      await _fillForm(
        tester,
        current: 'OldPass123',
        next: 'NewPass123',
        confirm: 'NewPass123',
      );

      await _tapFinder(tester, find.byType(GamingButtonPrimary));

      expect(find.text('Mise à jour…'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        final tf = tester.widget<TextField>(_tf(i));
        expect(tf.enabled, isFalse);
      }

      fake.completePending(ApiResponse.ok(true, statusCode: 200));
      await tester.pumpAndSettle();
    });
  });

  group('ChangePasswordPage - API & navigation', () {
    testWidgets('erreur API => affiche message et reste sur la page', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      fake.immediateResponse = ApiResponse.err(
        message: 'Échec custom',
        statusCode: 400,
      );

      await _fillForm(
        tester,
        current: 'OldPass123',
        next: 'NewPass123',
        confirm: 'NewPass123',
      );

      await _tapFinder(tester, find.byType(GamingButtonPrimary));

      expect(fake.callCount, 1);
      expect(find.text('Échec custom'), findsWidgets);
      expect(find.byType(ChangePasswordPage), findsOneWidget);
    });

    testWidgets('succès API => SnackBar vert + pop vers home', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      fake.immediateResponse = ApiResponse.ok(true, statusCode: 200);

      await _fillForm(
        tester,
        current: 'OldPass123',
        next: 'NewPass123',
        confirm: 'NewPass123',
      );

      await _tapFinder(tester, find.byType(GamingButtonPrimary));

      expect(fake.callCount, 1);
      expect(fake.lastCurrentPassword, 'OldPass123');
      expect(fake.lastNewPassword, 'NewPass123');

      final sbFinder = _snackBarWithMessage('Mot de passe mis à jour ✅');
      expect(sbFinder, findsWidgets);
      final last = tester.widgetList<SnackBar>(sbFinder).toList().last;
      expect(last.backgroundColor, TuuurTheme.brandGreen);

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });
  });

  group('ChangePasswordPage - navigation', () {
    testWidgets('Annuler => pop vers home', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      await _tapFinder(tester, find.byType(GamingButtonSecondary));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });

    testWidgets('AppBar back => pop vers home', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      await _tapFinder(tester, find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });
  });

  group('ChangePasswordPage - cycle de vie', () {
    testWidgets('dispose correctement', (tester) async {
      final router = _createRouter(initialLocation: '/', authApi: fake);
      await _pumpApp(tester, router);
      await _openChangePasswordPage(tester, router);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('crée un State correct', () {
      const page = ChangePasswordPage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}

