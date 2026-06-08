import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/api/api_module.dart' as api_module;
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/pages/auth/auth_register_page.dart';

void main() {
  setUpAll(() {
    try {
      api_module.ApiModule.instance.initialize(authStore: AuthStore.instance);
    } catch (_) {}
  });

  group('AuthRegisterPage', () {
    testWidgets('affiche tous les éléments de la page de register', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AuthRegisterPage()));

      await tester.pump();

      expect(find.byType(AuthRegisterPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      expect(find.byType(TextField), findsAtLeastNWidgets(4));

      expect(find.text('Pseudo'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);

      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Créer le compte'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('peut basculer la visibilité des mots de passe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AuthRegisterPage()));
      await tester.pump();

      final visibilityIcons = find.byIcon(Icons.visibility);
      expect(visibilityIcons, findsNWidgets(2));

      await tester.tap(visibilityIcons.first);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility).first);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));
    });

    testWidgets('affiche les boutons d’action', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthRegisterPage()));
      await tester.pump();

      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Créer le compte'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('les TextFields acceptent les entrées', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AuthRegisterPage()));
      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(4));

      await tester.enterText(fields.at(0), 'testuser');
      await tester.pump();
      expect(
        tester.widget<TextField>(fields.at(0)).controller!.text,
        'testuser',
      );

      await tester.enterText(fields.at(1), 'test@mail.com');
      await tester.pump();
      expect(
        tester.widget<TextField>(fields.at(1)).controller!.text,
        'test@mail.com',
      );

      await tester.enterText(fields.at(2), 'testpass123');
      await tester.pump();
      expect(
        tester.widget<TextField>(fields.at(2)).controller!.text,
        'testpass123',
      );

      await tester.enterText(fields.at(3), 'testpass123');
      await tester.pump();
      expect(
        tester.widget<TextField>(fields.at(3)).controller!.text,
        'testpass123',
      );
    });

    testWidgets('dispose correctement les controllers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AuthRegisterPage()));
      await tester.pump();

      expect(find.byType(AuthRegisterPage), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(tester.takeException(), isNull);
    });

    test('AuthRegisterPage crée un state correct', () {
      const page = AuthRegisterPage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}
