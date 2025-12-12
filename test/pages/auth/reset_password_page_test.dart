import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/pages/auth/reset_password_page.dart';

void main() {
  group('ResetPasswordPage', () {
    testWidgets('affiche tous les éléments de la page de reset',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordPage(),
        ),
      );

      await tester.pump();

      expect(find.byType(ResetPasswordPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // AppBar
      expect(find.text('Réinitialiser le mot de passe'), findsOneWidget);

      // Labels principaux
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Code reçu par email'), findsOneWidget);
      expect(find.text('Nouveau mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);

      // 4 champs : login, code, password, confirm
      expect(find.byType(TextField), findsAtLeastNWidgets(4));

      // Boutons (selon implémentation GamingButton*)
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Valider'), findsOneWidget);
    });

    testWidgets('préremplit le login si initialLogin est fourni',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordPage(initialLogin: 'testuser'),
        ),
      );

      await tester.pump();

      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('peut basculer la visibilité des champs mot de passe',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordPage(),
        ),
      );

      await tester.pump();

      // Il y a 2 icônes "visibility" au départ (password + confirm)
      final visibilityIcons = find.byIcon(Icons.visibility);
      expect(visibilityIcons, findsWidgets);

      // Taper sur la première icône -> elle devient visibility_off
      await tester.tap(visibilityIcons.first);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Taper sur la deuxième icône (celle restante)
      final remainingVisibility = find.byIcon(Icons.visibility);
      if (remainingVisibility.evaluate().isNotEmpty) {
        await tester.tap(remainingVisibility.first);
        await tester.pump();
      }

      // Les deux devraient être en visibility_off
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(2));
    });

    testWidgets('les TextFields acceptent les entrées',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordPage(),
        ),
      );

      await tester.pump();

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(4));

      // login
      await tester.enterText(textFields.at(0), 'testlogin');
      expect(find.text('testlogin'), findsOneWidget);

      // code
      await tester.enterText(textFields.at(1), '123456');
      expect(find.text('123456'), findsOneWidget);

      // password
      await tester.enterText(textFields.at(2), 'Testpass1');
      expect(find.text('Testpass1'), findsOneWidget);

      // confirm
      await tester.enterText(textFields.at(3), 'Testpass1');
      expect(find.text('Testpass1'), findsAtLeastNWidgets(2));
    });

    testWidgets('le champ code a maxLength=6 et clavier numérique',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordPage(),
        ),
      );

      await tester.pump();

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(4));

      final codeField = tester.widget<TextField>(textFields.at(1));
      expect(codeField.maxLength, 6);
      expect(codeField.keyboardType, TextInputType.number);
    });

    testWidgets('affiche une erreur si on valide avec un formulaire vide',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordPage(),
        ),
      );

      await tester.pump();

      // Clique sur "Valider" sans rien remplir => doit afficher SnackBar "Le login est requis."
      await tester.tap(find.text('Valider'));
      await tester.pump(); // lance l'animation SnackBar

      expect(find.text('Le login est requis.'), findsOneWidget);
    });

    testWidgets('dispose correctement les controllers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordPage(),
        ),
      );

      await tester.pump();

      expect(find.byType(ResetPasswordPage), findsOneWidget);

      // Détruire le widget
      await tester.pumpWidget(Container());

      expect(tester.takeException(), isNull);
    });

    test('ResetPasswordPage crée un state correct', () {
      const page = ResetPasswordPage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}
