import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/pages/auth/change_password_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';

void main() {
  group('ChangePasswordPage', () {
    Widget _wrap(Widget child) {
      return MaterialApp(
        home: MyAuthStore(
          notifier: AuthStore.instance,
          child: child,
        ),
      );
    }

    testWidgets('affiche tous les éléments de la page', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ChangePasswordPage()));
      await tester.pump();

      expect(find.byType(ChangePasswordPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // 3 champs (old, new, confirm)
      expect(find.byType(TextField), findsNWidgets(3));

      // Boutons (libellés attendus)
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Valider'), findsOneWidget);

      // Titre appbar
      expect(find.text('Réinitialiser le mot de passe'), findsOneWidget);
    });

    testWidgets('peut basculer la visibilité des mots de passe', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ChangePasswordPage()));
      await tester.pump();

      // Par défaut, les 3 suffixIcon devraient être "visibility"
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));

      // Toggle du 1er champ
      await tester.tap(find.byIcon(Icons.visibility).first);
      await tester.pump();

      // Après toggle, on doit voir au moins une icône "visibility_off"
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    });

    testWidgets('les TextFields acceptent les entrées', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ChangePasswordPage()));
      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));

      await tester.enterText(fields.at(0), 'OldPass123');
      await tester.enterText(fields.at(1), 'NewPass123');
      await tester.enterText(fields.at(2), 'NewPass123');

      expect(find.text('OldPass123'), findsOneWidget);
      expect(find.text('NewPass123'), findsNWidgets(2));
    });

    testWidgets('affiche une erreur si champs requis manquants', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ChangePasswordPage()));
      await tester.pump();

      await tester.tap(find.text('Valider'));
      await tester.pump(); // laisse le SnackBar apparaître

      expect(find.text('Tous les champs sont requis.'), findsOneWidget);
    });

    testWidgets('affiche une erreur si les mots de passe ne correspondent pas', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ChangePasswordPage()));
      await tester.pump();

      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), 'OldPass123');
      await tester.enterText(fields.at(1), 'NewPass123');
      await tester.enterText(fields.at(2), 'OtherPass123');

      await tester.tap(find.text('Valider'));
      await tester.pump();

      expect(find.text('Les mots de passe ne correspondent pas.'), findsOneWidget);
    });

    testWidgets('affiche une erreur si le nouveau mot de passe ne respecte pas la complexité', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ChangePasswordPage()));
      await tester.pump();

      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), 'OldPass123');
      await tester.enterText(fields.at(1), 'short');
      await tester.enterText(fields.at(2), 'short');

      await tester.tap(find.text('Valider'));
      await tester.pump();

      expect(
        find.text('Nouveau mot de passe invalide (min 8, 1 maj, 1 min, 1 chiffre).'),
        findsOneWidget,
      );
    });

    testWidgets('dispose correctement les controllers', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ChangePasswordPage()));
      await tester.pump();

      expect(find.byType(ChangePasswordPage), findsOneWidget);

      // Détruire le widget
      await tester.pumpWidget(Container());
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche un Scaffold avec SafeArea', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ChangePasswordPage()));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      // AppBar inclut généralement un SafeArea
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
    });

    test('ChangePasswordPage crée un state correct', () {
      const page = ChangePasswordPage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}
