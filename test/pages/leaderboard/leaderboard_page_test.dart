import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/pages/leaderboard/leaderboard_page.dart';

Future<void> _pumpLeaderboardPage(
  WidgetTester tester, {
  required Size surfaceSize,
}) async {
  tester.binding.window.devicePixelRatioTestValue = 1.0;
  tester.binding.window.physicalSizeTestValue = surfaceSize;
  addTearDown(() {
    tester.binding.window.clearPhysicalSizeTestValue();
    tester.binding.window.clearDevicePixelRatioTestValue();
  });

  await tester.pumpWidget(const MaterialApp(home: LeaderboardPage()));

  await tester.pump();

  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('LeaderboardPage', () {
    testWidgets(
      'layout wide : header en Row + podium en Row + liste affichée',
      (tester) async {
        await _pumpLeaderboardPage(tester, surfaceSize: const Size(900, 1400));

        expect(find.text('🏆 Classement Gaming'), findsOneWidget);
        expect(find.text('Top 20 Légendes'), findsOneWidget);

        final badgeText = find.text('Top 20 Légendes');
        final headerRows = find
            .ancestor(of: badgeText, matching: find.byType(Row))
            .evaluate()
            .map((e) => e.widget)
            .whereType<Row>()
            .where((r) => r.mainAxisAlignment == MainAxisAlignment.spaceBetween)
            .toList();
        expect(headerRows.length, 1);

        final podiumRow = find.byWidgetPredicate((w) {
          if (w is! Row) return false;
          if (w.crossAxisAlignment != CrossAxisAlignment.end) return false;
          final expandedCount = w.children.whereType<Expanded>().length;
          return expandedCount == 3 && w.children.length == 5;
        });
        expect(podiumRow, findsOneWidget);

        expect(find.text('#1 Ava'), findsOneWidget);
        expect(find.text('#2 Liam'), findsOneWidget);
        expect(find.text('#3 Emma'), findsOneWidget);

        expect(find.text('Classement Complet'), findsOneWidget);
        expect(find.text('Mise à jour en temps réel'), findsOneWidget);

        for (var r = 4; r <= 20; r++) {
          expect(find.text('#$r'), findsOneWidget);
        }

        expect(find.text('Noah'), findsOneWidget);
        expect(find.text('Mia'), findsOneWidget);
        expect(find.text('Yanis'), findsOneWidget);

        expect(find.text('Champion actuel'), findsNWidgets(2));
        expect(find.text('Challenger'), findsNWidgets(5));
        expect(find.text('Joueur confirmé'), findsNWidgets(10));

        expect(find.text('⚡ 1603'), findsOneWidget);

        await _disposeTree(tester);
      },
    );

    testWidgets(
      'layout narrow : header empilé (Column) + podium non-wide + header liste empilé',
      (tester) async {
        await _pumpLeaderboardPage(tester, surfaceSize: const Size(380, 2000));

        expect(find.text('🏆 Classement Gaming'), findsOneWidget);
        expect(find.text('Top 20 Légendes'), findsOneWidget);

        final badgeText = find.text('Top 20 Légendes');

        final headerColumns = find.ancestor(
          of: badgeText,
          matching: find.byType(Column),
        );
        expect(headerColumns, findsWidgets);

        final headerSpaceBetweenRow = find.byWidgetPredicate((w) {
          if (w is! Row) return false;
          if (w.mainAxisAlignment != MainAxisAlignment.spaceBetween)
            return false;
          return find
              .descendant(of: find.byWidget(w), matching: badgeText)
              .evaluate()
              .isNotEmpty;
        });
        expect(headerSpaceBetweenRow, findsNothing);

        final widePodiumRow = find.byWidgetPredicate((w) {
          if (w is! Row) return false;
          if (w.crossAxisAlignment != CrossAxisAlignment.end) return false;
          final expandedCount = w.children.whereType<Expanded>().length;
          return expandedCount == 3 && w.children.length == 5;
        });
        expect(widePodiumRow, findsNothing);

        expect(find.text('#1 Ava'), findsOneWidget);
        expect(find.text('#2 Liam'), findsOneWidget);
        expect(find.text('#3 Emma'), findsOneWidget);

        expect(find.text('Classement Complet'), findsOneWidget);
        expect(find.text('Mise à jour en temps réel'), findsOneWidget);

        final listChip = find.text('Mise à jour en temps réel');
        final listHeaderColumns = find.ancestor(
          of: listChip,
          matching: find.byType(Column),
        );
        expect(listHeaderColumns, findsWidgets);

        expect(find.text('#4'), findsOneWidget);
        expect(find.text('#20'), findsOneWidget);

        await _disposeTree(tester);
      },
    );
  });
}
