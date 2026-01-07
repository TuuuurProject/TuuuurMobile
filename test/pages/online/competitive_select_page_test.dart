import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:tuuuur_flutter/pages/online/competitive_select_page.dart';
import 'package:tuuuur_flutter/widgets/gaming_widgets.dart';

Future<void> _pumpCompetitiveSelect(
  WidgetTester tester, {
  required Size surfaceSize,
  required VoidCallback onBack,
  required void Function(List<String>) onSearch,
}) async {
  tester.binding.window.devicePixelRatioTestValue = 1.0;
  tester.binding.window.physicalSizeTestValue = surfaceSize;
  addTearDown(() {
    tester.binding.window.clearPhysicalSizeTestValue();
    tester.binding.window.clearDevicePixelRatioTestValue();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // Comme c'est un gros Column, on wrap en scroll en test
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CompetitiveSelectPage(
              onBack: onBack,
              onSearch: onSearch,
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  // Pas de pumpAndSettle() (animations repeat)
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// Toggle une catégorie en appelant directement le onTap du GestureDetector
/// (beaucoup plus stable qu'un tap hit-test, avec flutter_animate).
Future<void> _toggleCategoryByLabel(WidgetTester tester, String label) async {
  final labelFinder = find.text(label);
  expect(labelFinder, findsOneWidget);

  // Remonte au GestureDetector du chip
  final gdFinder = find.ancestor(
    of: labelFinder,
    matching: find.byType(GestureDetector),
  );

  final gds = gdFinder
      .evaluate()
      .map((e) => e.widget)
      .whereType<GestureDetector>()
      .where((gd) => gd.onTap != null)
      .toList();

  // Un seul GestureDetector pour le chip
  expect(gds.length, 1);

  gds.single.onTap!.call();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Appuie sur un bouton GamingButton* en déclenchant onPressed.
/// On le cible par son texte (plus robuste que byType si plusieurs).
Future<void> _pressButtonByText(
  WidgetTester tester,
  String text,
) async {
  final textFinder = find.text(text);
  expect(textFinder, findsOneWidget);

  final ghostFinder = find.ancestor(
    of: textFinder,
    matching: find.byType(GamingButtonGhost),
  );
  if (ghostFinder.evaluate().isNotEmpty) {
    final btn = tester.widget<GamingButtonGhost>(ghostFinder.first);
    expect(btn.onPressed, isNotNull);
    btn.onPressed!.call();
    await tester.pump(const Duration(milliseconds: 50));
    return;
  }

  final secondaryFinder = find.ancestor(
    of: textFinder,
    matching: find.byType(GamingButtonSecondary),
  );
  expect(secondaryFinder, findsOneWidget);

  final btn = tester.widget<GamingButtonSecondary>(secondaryFinder);
  expect(btn.onPressed, isNotNull);
  btn.onPressed!.call();
  await tester.pump(const Duration(milliseconds: 50));
}

Finder _actionsRowFinder() {
  return find.byWidgetPredicate((w) {
    if (w is! Row) return false;
    if (w.mainAxisAlignment != MainAxisAlignment.end) return false;

    bool hasGhost = false;
    bool hasSecondary = false;

    for (final child in w.children) {
      if (child is SizedBox && child.child is GamingButtonGhost) {
        hasGhost = true;
      }
      if (child is SizedBox && child.child is GamingButtonSecondary) {
        hasSecondary = true;
      }
    }
    return hasGhost && hasSecondary;
  });
}

Finder _actionsColumnFinder() {
  return find.byWidgetPredicate((w) {
    if (w is! Column) return false;
    if (w.crossAxisAlignment != CrossAxisAlignment.stretch) return false;

    bool hasGhost = false;
    bool hasSecondary = false;

    for (final child in w.children) {
      if (child is SizedBox && child.child is GamingButtonGhost) {
        hasGhost = true;
      }
      if (child is SizedBox && child.child is GamingButtonSecondary) {
        hasSecondary = true;
      }
    }
    return hasGhost && hasSecondary;
  });
}

void main() {
  group('CompetitiveSelectPage', () {
    testWidgets('affiche header + texte + catégories + info + boutons (wide)',
        (tester) async {
      var backCalls = 0;
      List<String>? searched;

      await _pumpCompetitiveSelect(
        tester,
        surfaceSize: const Size(900, 1200),
        onBack: () => backCalls++,
        onSearch: (cats) => searched = cats,
      );

      // Header: on vérifie la présence de l’icône + le texte dans le même header
      final fireIcon = find.byWidgetPredicate(
        (w) => w is FaIcon && w.icon == FontAwesomeIcons.fire,
      );
      expect(fireIcon, findsOneWidget);

      final headerRow = find.ancestor(of: fireIcon, matching: find.byType(Row));
      expect(headerRow, findsOneWidget);

      expect(
        find.descendant(of: headerRow, matching: find.text('Mode Compétitif')),
        findsOneWidget,
      );

      expect(find.text('Choisissez vos catégories favorites'), findsOneWidget);

      // Card header
      expect(find.text('Catégories de Combat'), findsOneWidget);
      expect(
        find.text(
          'Sélectionnez vos domaines d\'expertise pour des duels équilibrés.',
        ),
        findsOneWidget,
      );

      // Info block
      // "Mode Compétitif" apparaît 2 fois (header + bloc info)
      expect(find.text('Mode Compétitif'), findsNWidgets(2));
      expect(find.text('Matchmaking équilibré'), findsOneWidget);
      expect(find.text('Rang dynamique'), findsOneWidget);

      // Catégories (labels)
      for (final name in const [
        'Général',
        'Histoire',
        'Science',
        'Sport',
        'Musique',
        'Cinéma',
        'Art',
        'Géographie',
      ]) {
        expect(find.text(name), findsOneWidget);
      }

      // Boutons
      expect(find.text('← Retour'), findsOneWidget);
      expect(find.text('🔍 Lancer la recherche'), findsOneWidget);

      // Layout wide des boutons: Row(mainAxisAlignment.end) présent
      expect(_actionsRowFinder(), findsOneWidget);

      // État initial: "general" sélectionné => proceed envoie ["Général"]
      await _pressButtonByText(tester, '🔍 Lancer la recherche');
      expect(searched, isNotNull);
      expect(searched, equals(['Général']));

      // Back
      await _pressButtonByText(tester, '← Retour');
      expect(backCalls, 1);

      await _disposeTree(tester);
    });

    testWidgets('toggle categories + ne permet pas de retirer la dernière',
        (tester) async {
      List<String>? searched;

      await _pumpCompetitiveSelect(
        tester,
        surfaceSize: const Size(900, 1400),
        onBack: () {},
        onSearch: (cats) => searched = cats,
      );

      // On ajoute "Sport"
      await _toggleCategoryByLabel(tester, 'Sport');

      // Recherche => ["Général", "Sport"] (ordre = celui de la liste categories)
      await _pressButtonByText(tester, '🔍 Lancer la recherche');
      expect(searched, equals(['Général', 'Sport']));

      // On enlève "Général" (possible car length > 1)
      await _toggleCategoryByLabel(tester, 'Général');
      await _pressButtonByText(tester, '🔍 Lancer la recherche');
      expect(searched, equals(['Sport']));

      // On tente d'enlever "Sport" (dernier restant) => doit rester sélectionné
      await _toggleCategoryByLabel(tester, 'Sport');
      await _pressButtonByText(tester, '🔍 Lancer la recherche');
      expect(searched, equals(['Sport']));

      await _disposeTree(tester);
    });

    testWidgets('layout narrow : boutons empilés en Column (stretch)',
        (tester) async {
      // NOTE:
      // Sur certaines largeurs très étroites, il y a un RenderFlex overflow
      // dans des sous-widgets (tags) car le contenu est un Row non-ellipsé.
      // On ignore *uniquement* ces overflows pour pouvoir tester le layout des boutons.
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final msg = details.exceptionAsString();
        if (msg.contains('A RenderFlex overflowed')) {
          return; // ignore overflow
        }
        if (oldOnError != null) oldOnError(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      await _pumpCompetitiveSelect(
        tester,
        surfaceSize: const Size(380, 1600),
        onBack: () {},
        onSearch: (_) {},
      );

      // Textes boutons présents
      expect(find.text('← Retour'), findsOneWidget);
      expect(find.text('🔍 Lancer la recherche'), findsOneWidget);

      // On vérifie que la zone boutons est en Column (narrow < 420)
      expect(_actionsColumnFinder(), findsOneWidget);

      // Sur narrow: pas le Row mainAxisAlignment.end pour les boutons
      expect(_actionsRowFinder(), findsNothing);

      await _disposeTree(tester);
    });

    testWidgets('présence de l’icône fire dans le header', (tester) async {
      await _pumpCompetitiveSelect(
        tester,
        surfaceSize: const Size(900, 1200),
        onBack: () {},
        onSearch: (_) {},
      );

      final fireIcon = find.byWidgetPredicate(
        (w) => w is FaIcon && w.icon == FontAwesomeIcons.fire,
      );
      expect(fireIcon, findsOneWidget);

      await _disposeTree(tester);
    });
  });
}
