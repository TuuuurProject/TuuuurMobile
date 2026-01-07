import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/pages/auth/auth_verify_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/navigation/app_messengers.dart';

void main() {
  group('AuthVerifyPage', () {
    testWidgets('affiche tous les éléments de la page de vérification',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(AuthVerifyPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // 2 champs : login + code
      expect(find.byType(TextField), findsAtLeastNWidgets(2));

      // Labels & éléments principaux
      expect(find.text('Pseudo (login)'), findsOneWidget);
      expect(find.text('Code à 6 chiffres'), findsOneWidget);
      expect(find.text('Valider le code'), findsOneWidget);
      expect(find.text('Renvoyer le code'), findsOneWidget);
    });

    testWidgets('pré-remplit le login avec initialLogin',
        (WidgetTester tester) async {
      const initialLogin = 'testuser';

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(initialLogin: initialLogin),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(2));

      final loginField = tester.widget<TextField>(fields.first);
      expect(loginField.controller, isNotNull);
      expect(loginField.controller!.text, equals(initialLogin));
    });

    testWidgets('affiche le hint email quand fourni', (WidgetTester tester) async {
      const emailHint = 't***@gmail.com';

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(emailHint: emailHint),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Envoyé à $emailHint'), findsOneWidget);
    });

    testWidgets('le champ code a maxLength = 6', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(2));

      // Le 2e TextField est celui du code
      final codeField = tester.widget<TextField>(fields.at(1));
      expect(codeField.maxLength, equals(6));
      expect(codeField.keyboardType, equals(TextInputType.number));
    });

    testWidgets('affiche un SnackBar si login manquant (validation locale)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '123456'); // code ok
      await tester.tap(find.text('Valider le code'));
      await tester.pump(); // affiche le SnackBar

      expect(find.text('Le pseudo (login) est requis.'), findsOneWidget);
    });

    testWidgets('affiche un SnackBar si code invalide (validation locale)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.at(1), '123'); // invalide
      await tester.tap(find.text('Valider le code'));
      await tester.pump();

      expect(
        find.text('Code invalide. Entrez les 6 chiffres reçus par email.'),
        findsOneWidget,
      );
    });

    testWidgets('les TextFields acceptent les entrées',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(2));

      await tester.enterText(fields.first, 'testuser');
      expect(find.text('testuser'), findsOneWidget);

      await tester.enterText(fields.at(1), '123456');
      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('dispose correctement les controllers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AuthVerifyPage), findsOneWidget);

      await tester.pumpWidget(Container());
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche un Scaffold avec SafeArea (via AppBar)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: MyAuthStore(
            notifier: AuthStore.instance,
            child: const AuthVerifyPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    test('AuthVerifyPage crée un state correct', () {
      const page = AuthVerifyPage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}
