import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:tuuuur_flutter/pages/online/duel_1v1_page.dart';
import 'package:tuuuur_flutter/widgets/gaming_widgets.dart';

Future<void> _pumpDuelPage(
  WidgetTester tester, {
  required Size surfaceSize,
  required List<String> categories,
  required VoidCallback onBack,
  required VoidCallback onStart,
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
          child: SizedBox(
            width: surfaceSize.width,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Duel1v1Page(
                categories: categories,
                onBack: onBack,
                onStart: onStart,
              ),
            ),
          ),
        ),
      ),
    ),
  );


  await tester.pump();


  await tester.pump(const Duration(milliseconds: 800));
}



Future<void> _flushOpponentTimer(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
}


Future<void> _pressPrimaryButton(WidgetTester tester) async {
  final finder = find.byType(GamingButtonPrimary);
  expect(finder, findsOneWidget);

  final btn = tester.widget<GamingButtonPrimary>(finder);



  expect(btn.onPressed, isNotNull);

  btn.onPressed!.call();
  await tester.pump(const Duration(milliseconds: 50));
}



Future<void> _triggerBack(WidgetTester tester) async {
  final arrowIcon = find.byWidgetPredicate(
    (w) => w is FaIcon && w.icon == FontAwesomeIcons.arrowLeft,
  );
  expect(arrowIcon, findsOneWidget);

  final ancestors = find.ancestor(
    of: arrowIcon,
    matching: find.byType(GestureDetector),
  );

  final gds = ancestors
      .evaluate()
      .map((e) => e.widget)
      .whereType<GestureDetector>()
      .where((gd) => gd.onTap != null)
      .toList();


  expect(gds.length, 1);

  gds.single.onTap!.call();
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  group('Duel1v1Page', () {
    testWidgets('affiche header + règles + catégories (layout wide)',
        (tester) async {
      var backCalls = 0;
      var startCalls = 0;

      await _pumpDuelPage(
        tester,
        surfaceSize: const Size(900, 1200),
        categories: const ['Sport', 'Histoire'],
        onBack: () => backCalls++,
        onStart: () => startCalls++,
      );


      expect(find.text('Duel 1vs1'), findsOneWidget);
      expect(find.text('Règles du Duel'), findsOneWidget);
      expect(find.text('Catégories du duel'), findsOneWidget);


      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('Histoire'), findsOneWidget);


      final arenaRow = find.byWidgetPredicate((w) {
        if (w is! Row) return false;
        final expandedCount = w.children.whereType<Expanded>().length;
        return expandedCount == 2 && w.children.length == 3;
      });
      expect(arenaRow, findsOneWidget);


      final rulesRow = find.byWidgetPredicate((w) {
        if (w is! Row) return false;
        final expandedCount = w.children.whereType<Expanded>().length;
        return expandedCount == 3 && w.children.length == 3;
      });
      expect(rulesRow, findsOneWidget);


      expect(find.text('Prêt !'), findsOneWidget);
      expect(find.textContaining('Cliquez sur "Prêt"'), findsOneWidget);

      expect(backCalls, 0);
      expect(startCalls, 0);

      await _flushOpponentTimer(tester);
    });

    testWidgets('back déclenche onBack (sans tap flaky dû aux anims)',
        (tester) async {
      var backCalls = 0;

      await _pumpDuelPage(
        tester,
        surfaceSize: const Size(900, 1200),
        categories: const ['A'],
        onBack: () => backCalls++,
        onStart: () {},
      );

      await _triggerBack(tester);
      expect(backCalls, 1);

      await _flushOpponentTimer(tester);
    });

    testWidgets('toggle ready on/off met à jour le texte + hint',
        (tester) async {
      await _pumpDuelPage(
        tester,
        surfaceSize: const Size(900, 1200),
        categories: const ['X', 'Y'],
        onBack: () {},
        onStart: () {},
      );


      expect(find.text('Prêt !'), findsOneWidget);
      expect(find.textContaining('Cliquez sur "Prêt"'), findsOneWidget);


      await _pressPrimaryButton(tester);
      expect(find.text('Pas prêt'), findsOneWidget);
      expect(find.text('En attente de l\'adversaire...'), findsOneWidget);


      await _pressPrimaryButton(tester);
      expect(find.text('Prêt !'), findsOneWidget);
      expect(find.textContaining('Cliquez sur "Prêt"'), findsOneWidget);

      await _flushOpponentTimer(tester);
    });

    testWidgets(
        'flow prêt -> adversaire prêt (2s) -> bouton start -> onStart',
        (tester) async {
      var startCalls = 0;

      await _pumpDuelPage(
        tester,
        surfaceSize: const Size(900, 1200),
        categories: const ['Sport'],
        onBack: () {},
        onStart: () => startCalls++,
      );


      await _pressPrimaryButton(tester);
      expect(find.text('Pas prêt'), findsOneWidget);
      expect(find.text('En attente de l\'adversaire...'), findsOneWidget);


      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 50));


      expect(find.text('⚔️ COMMENCER LE DUEL !'), findsOneWidget);
      expect(find.text('En attente de l\'adversaire...'), findsNothing);


      await _pressPrimaryButton(tester);
      expect(startCalls, 1);

      await _flushOpponentTimer(tester);
    });

    testWidgets('layout narrow : arena en colonne + rules en Wrap (spécifique)',
        (tester) async {
      await _pumpDuelPage(
        tester,
        surfaceSize: const Size(380, 2000),
        categories: const ['Cat1', 'Cat2', 'Cat3'],
        onBack: () {},
        onStart: () {},
      );


      final arenaRow = find.byWidgetPredicate((w) {
        if (w is! Row) return false;
        return w.children.whereType<Expanded>().length == 2 && w.children.length == 3;
      });
      expect(arenaRow, findsNothing);


      final rulesWrap = find.byWidgetPredicate((w) {
        if (w is! Wrap) return false;
        if (w.children.length != 3) return false;
        return w.children.every((c) => c is SizedBox);
      });
      expect(rulesWrap, findsOneWidget);


      expect(find.text('Cat1'), findsOneWidget);
      expect(find.text('Cat2'), findsOneWidget);
      expect(find.text('Cat3'), findsOneWidget);

      await _flushOpponentTimer(tester);
    });
  });
}
