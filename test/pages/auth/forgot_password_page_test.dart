import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/pages/auth/forgot_password_page.dart';

Future<void> _pumpPage(WidgetTester tester) async {
  // Largeur >= 548 pour que (screenWidth - 48) >= 500 (padding 24 * 2)
  await tester.binding.setSurfaceSize(const Size(700, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    const MaterialApp(
      home: ForgotPasswordPage(),
    ),
  );

  await tester.pump(); // build
}

void main() {
  group('ForgotPasswordPage', () {
    testWidgets('affiche tous les éléments de la page', (WidgetTester tester) async {
      await _pumpPage(tester);

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // AppBar
      expect(find.text('Mot de passe oublié'), findsOneWidget);

      // Contenu
      expect(find.text('Recevoir un code de réinitialisation'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      // Champ login
      expect(find.byType(TextField), findsOneWidget);

      // Boutons
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Envoyer le code'), findsOneWidget);
    });

    testWidgets('le TextField accepte les entrées', (WidgetTester tester) async {
      await _pumpPage(tester);

      final loginField = find.byType(TextField);
      expect(loginField, findsOneWidget);

      await tester.enterText(loginField, 'testuser');
      await tester.pump();

      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('affiche une erreur si le login est vide', (WidgetTester tester) async {
      await _pumpPage(tester);

      await tester.tap(find.text('Envoyer le code'));
      await tester.pump(); // fait apparaître la SnackBar

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Le login est requis.'), findsOneWidget);
    });

    testWidgets('dispose correctement le controller', (WidgetTester tester) async {
      await _pumpPage(tester);

      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      // Détruire le widget
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('ForgotPasswordPage crée un state correct', () {
      const page = ForgotPasswordPage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}
