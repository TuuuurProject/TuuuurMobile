import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/pages/leaderboard/leaderboard_page.dart';

Future<void> _pumpLeaderboardPage(
  WidgetTester tester, {
  required Size surfaceSize,
}) async {
  // Surface size (évite les surprises de layout)
  tester.binding.window.devicePixelRatioTestValue = 1.0;
  tester.binding.window.physicalSizeTestValue = surfaceSize;
  addTearDown(() {
    tester.binding.window.clearPhysicalSizeTestValue();
    tester.binding.window.clearDevicePixelRatioTestValue();
  });

  await tester.pumpWidget(
    const MaterialApp(
      home: LeaderboardPage(),
    ),
  );

  // 1 frame pour construire
  await tester.pump();

  // Laisse un peu d’air aux animations (sans pumpAndSettle car repeat())
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _disposeTree(WidgetTester tester) async {
  // Dispose l'arbre et stoppe les tickers/animations repeat
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('LeaderboardPage', () {
    testWidgets('layout wide : header en Row + podium en Row + liste affichée',
        (tester) async {
      await _pumpLeaderboardPage(
        tester,
        surfaceSize: const Size(900, 1400),
      );

      // Textes principaux
      expect(find.text('🏆 Classement Gaming'), findsOneWidget);
      expect(find.text('Top 20 Légendes'), findsOneWidget);

      // Header (wide) : le badge est dans un Row (mainAxisAlignment.spaceBetween)
      final badgeText = find.text('Top 20 Légendes');
      final headerRows = find
          .ancestor(of: badgeText, matching: find.byType(Row))
          .evaluate()
          .map((e) => e.widget)
          .whereType<Row>()
          .where((r) => r.mainAxisAlignment == MainAxisAlignment.spaceBetween)
          .toList();
      expect(headerRows.length, 1);

      // Podium (wide) : Row avec crossAxisAlignment.end et 3 Expanded
      final podiumRow = find.byWidgetPredicate((w) {
        if (w is! Row) return false;
        if (w.crossAxisAlignment != CrossAxisAlignment.end) return false;
        final expandedCount = w.children.whereType<Expanded>().length;
        // Layout exact: Expanded, SizedBox, Expanded, SizedBox, Expanded
        return expandedCount == 3 && w.children.length == 5;
      });
      expect(podiumRow, findsOneWidget);

      // Podium top 3 (texte dans les cartes podium)
      expect(find.text('#1 Ava'), findsOneWidget);
      expect(find.text('#2 Liam'), findsOneWidget);
      expect(find.text('#3 Emma'), findsOneWidget);

      // Header de la liste
      expect(find.text('Classement Complet'), findsOneWidget);
      expect(find.text('Mise à jour en temps réel'), findsOneWidget);

      // La liste contient les ranks 4 -> 20
      for (var r = 4; r <= 20; r++) {
        expect(find.text('#$r'), findsOneWidget);
      }

      // Quelques joueurs attendus (dans la liste)
      expect(find.text('Noah'), findsOneWidget);
      expect(find.text('Mia'), findsOneWidget);
      expect(find.text('Yanis'), findsOneWidget);

      // Sous-titres (dans la liste seulement)
      // ranks 4-5 => Champion actuel (2 joueurs)
      expect(find.text('Champion actuel'), findsNWidgets(2));
      // ranks 6-10 => Challenger (5 joueurs)
      expect(find.text('Challenger'), findsNWidgets(5));
      // ranks 11-20 => Joueur confirmé (10 joueurs)
      expect(find.text('Joueur confirmé'), findsNWidgets(10));

      // Exemple de badge ELO dans la liste (format "⚡ 1603")
      expect(find.text('⚡ 1603'), findsOneWidget); // Noah (rank 4)

      await _disposeTree(tester);
    });

    testWidgets(
        'layout narrow : header empilé (Column) + podium non-wide + header liste empilé',
        (tester) async {
      await _pumpLeaderboardPage(
        tester,
        surfaceSize: const Size(380, 2000),
      );

      // Textes principaux toujours présents
      expect(find.text('🏆 Classement Gaming'), findsOneWidget);
      expect(find.text('Top 20 Légendes'), findsOneWidget);

      // Header (narrow) : le badge est dans un Column (et PAS dans le Row spaceBetween)
      final badgeText = find.text('Top 20 Légendes');

      final headerColumns =
          find.ancestor(of: badgeText, matching: find.byType(Column));
      expect(headerColumns, findsWidgets);

      final headerSpaceBetweenRow = find.byWidgetPredicate((w) {
        if (w is! Row) return false;
        if (w.mainAxisAlignment != MainAxisAlignment.spaceBetween) return false;
        // On vérifie que ce Row contient le badge (sinon ça peut matcher ailleurs)
        return find.descendant(of: find.byWidget(w), matching: badgeText).evaluate().isNotEmpty;
      });
      expect(headerSpaceBetweenRow, findsNothing);

      // Podium (narrow) : il ne doit PAS y avoir le Row wide (crossAxisAlignment.end + 3 Expanded)
      final widePodiumRow = find.byWidgetPredicate((w) {
        if (w is! Row) return false;
        if (w.crossAxisAlignment != CrossAxisAlignment.end) return false;
        final expandedCount = w.children.whereType<Expanded>().length;
        return expandedCount == 3 && w.children.length == 5;
      });
      expect(widePodiumRow, findsNothing);

      // Top 3 toujours présents
      expect(find.text('#1 Ava'), findsOneWidget);
      expect(find.text('#2 Liam'), findsOneWidget);
      expect(find.text('#3 Emma'), findsOneWidget);

      // Header liste (narrow) : "Mise à jour en temps réel" empilé sous le titre
      expect(find.text('Classement Complet'), findsOneWidget);
      expect(find.text('Mise à jour en temps réel'), findsOneWidget);

      final listChip = find.text('Mise à jour en temps réel');
      final listHeaderColumns =
          find.ancestor(of: listChip, matching: find.byType(Column));
      expect(listHeaderColumns, findsWidgets);

      // Quelques rangs check
      expect(find.text('#4'), findsOneWidget);
      expect(find.text('#20'), findsOneWidget);

      await _disposeTree(tester);
    });
  });
}
