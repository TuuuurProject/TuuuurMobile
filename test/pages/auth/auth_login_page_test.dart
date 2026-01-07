import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/pages/auth/auth_login_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';

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

Widget _wrapWithApp(GoRouter router) {
  return MyAuthStore(
    notifier: AuthStore.instance,
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpLogin(WidgetTester tester, {GoRouter? router}) async {
  final r = router ?? _createRouter();
  await tester.pumpWidget(_wrapWithApp(r));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
