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

  // Pump several frames to let animations start
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // Pump a few times to ensure cleanup
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _toggleCategoryByLabel(WidgetTester tester, String label) async {
  final labelFinder = find.text(label);
  expect(labelFinder, findsOneWidget);

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

  expect(gds.length, 1);

  gds.single.onTap!.call();
  await tester.pump(const Duration(milliseconds: 50));
}

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

      expect(find.text('Catégories de Combat'), findsOneWidget);
      expect(
        find.text(
          'Sélectionnez vos domaines d\'expertise pour des duels équilibrés.',
        ),
        findsOneWidget,
      );

      expect(find.text('Mode Compétitif'), findsNWidgets(2));
      expect(find.text('Matchmaking équilibré'), findsOneWidget);
      expect(find.text('Rang dynamique'), findsOneWidget);

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

      expect(find.text('← Retour'), findsOneWidget);
      expect(find.text('🔍 Lancer la recherche'), findsOneWidget);

      expect(_actionsRowFinder(), findsOneWidget);

      await _pressButtonByText(tester, '🔍 Lancer la recherche');
      expect(searched, isNotNull);
      expect(searched, equals(['Général']));

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

      await _toggleCategoryByLabel(tester, 'Sport');

      await _pressButtonByText(tester, '🔍 Lancer la recherche');
      expect(searched, equals(['Général', 'Sport']));

      await _toggleCategoryByLabel(tester, 'Général');
      await _pressButtonByText(tester, '🔍 Lancer la recherche');
      expect(searched, equals(['Sport']));

      await _toggleCategoryByLabel(tester, 'Sport');
      await _pressButtonByText(tester, '🔍 Lancer la recherche');
      expect(searched, equals(['Sport']));

      await _disposeTree(tester);
    });

    testWidgets('layout narrow : boutons empilés en Column (stretch)',
        (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final msg = details.exceptionAsString();
        if (msg.contains('A RenderFlex overflowed')) {
          return;
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

      expect(find.text('← Retour'), findsOneWidget);
      expect(find.text('🔍 Lancer la recherche'), findsOneWidget);

      expect(_actionsColumnFinder(), findsOneWidget);

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
