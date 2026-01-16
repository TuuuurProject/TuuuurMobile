import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/widgets/common_widgets.dart';

void main() {
  group('GamingModal', () {
    testWidgets('affiche le titre correctement', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GamingModal(
              title: 'Test Modal',
              child: Text('Content'),
            ),
          ),
        ),
      );

      // Attendre que toutes les animations se terminent
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Test Modal'), findsOneWidget);
    });

    testWidgets('affiche le contenu child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GamingModal(
              title: 'Modal',
              child: Text('Modal Content'),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Modal Content'), findsOneWidget);
    });

    testWidgets('affiche les boutons d\'action par défaut', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GamingModal(
              title: 'Modal',
              child: Text('Content'),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Confirmer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('utilise le texte personnalisé pour les boutons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GamingModal(
              title: 'Modal',
              confirmText: 'Valider',
              cancelText: 'Fermer',
              child: Text('Content'),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Valider'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    });

    testWidgets('appelle onConfirm quand le bouton confirmer est cliqué', (WidgetTester tester) async {
      var confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamingModal(
              title: 'Modal',
              child: const Text('Content'),
              onConfirm: () {
                confirmed = true;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Confirmer'));
      await tester.pump();

      expect(confirmed, isTrue);
    });

    testWidgets('appelle onCancel quand le bouton annuler est cliqué', (WidgetTester tester) async {
      var cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamingModal(
              title: 'Modal',
              child: const Text('Content'),
              onCancel: () {
                cancelled = true;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Annuler'));
      await tester.pump();

      expect(cancelled, isTrue);
    });

    testWidgets('affiche le bouton fermer dans le header', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GamingModal(
              title: 'Modal',
              child: Text('Content'),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('ferme la modal via le bouton close', (WidgetTester tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamingModal(
              title: 'Modal',
              child: const Text('Content'),
              onCancel: () {
                closed = true;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('masque les actions quand showActions est false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GamingModal(
              title: 'Modal',
              showActions: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Confirmer'), findsNothing);
      expect(find.text('Annuler'), findsNothing);
    });

    testWidgets('GamingModal.show affiche la modal', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  GamingModal.show(
                    context: context,
                    title: 'Test Dialog',
                    child: const Text('Dialog Content'),
                  );
                },
                child: const Text('Show Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Modal'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog Content'), findsOneWidget);
    });

    testWidgets('GamingModal.show peut être fermée', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  GamingModal.show(
                    context: context,
                    title: 'Dialog',
                    child: const Text('Content'),
                    barrierDismissible: true,
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Dialog'), findsOneWidget);

      // Fermer via le bouton annuler
      await tester.tap(find.text('Annuler'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Dialog'), findsNothing);
    });
  });
}
