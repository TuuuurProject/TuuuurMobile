import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/navigation/navigation_utils.dart';

void main() {
  group('runWithConfirmIfNeeded', () {
    testWidgets('exécute l\'action directement si confirm est false', (WidgetTester tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  runWithConfirmIfNeeded(
                    context,
                    confirm: false,
                    message: 'Are you sure?',
                    action: () {
                      actionCalled = true;
                    },
                  );
                },
                child: const Text('Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(actionCalled, isTrue);
      expect(find.text('Confirmation'), findsNothing);
    });

    testWidgets('affiche un dialog de confirmation si confirm est true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  runWithConfirmIfNeeded(
                    context,
                    confirm: true,
                    message: 'Voulez-vous continuer?',
                    action: () {},
                  );
                },
                child: const Text('Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmation'), findsOneWidget);
      expect(find.text('Voulez-vous continuer?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Oui'), findsOneWidget);
    });

    testWidgets('exécute l\'action si l\'utilisateur confirme', (WidgetTester tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  runWithConfirmIfNeeded(
                    context,
                    confirm: true,
                    message: 'Continuer?',
                    action: () {
                      actionCalled = true;
                    },
                  );
                },
                child: const Text('Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Oui'));
      await tester.pumpAndSettle();

      expect(actionCalled, isTrue);
    });

    testWidgets('n\'exécute pas l\'action si l\'utilisateur annule', (WidgetTester tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  runWithConfirmIfNeeded(
                    context,
                    confirm: true,
                    message: 'Continuer?',
                    action: () {
                      actionCalled = true;
                    },
                  );
                },
                child: const Text('Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(actionCalled, isFalse);
    });

    testWidgets('n\'exécute pas l\'action si le dialog est fermé sans réponse', (WidgetTester tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  runWithConfirmIfNeeded(
                    context,
                    confirm: true,
                    message: 'Continuer?',
                    action: () {
                      actionCalled = true;
                    },
                  );
                },
                child: const Text('Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmation'), findsOneWidget);

      expect(actionCalled, isFalse);
    });
  });
}
