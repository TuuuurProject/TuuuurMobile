
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:tuuuur_flutter/widgets/gaming_widgets.dart';
import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';

Future<void> _pumpInApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(

          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('GamingButtonPrimary', () {
    testWidgets('affiche texte + icône et déclenche onPressed', (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        GamingButtonPrimary(
          text: 'Jouer',
          icon: FontAwesomeIcons.play,
          onPressed: () => calls++,
        ),
      );

      expect(find.text('Jouer'), findsOneWidget);

      final fa = find.byWidgetPredicate(
        (w) => w is FaIcon && w.icon == FontAwesomeIcons.play,
      );
      expect(fa, findsOneWidget);

      await tester.tap(find.text('Jouer'));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('loading: affiche le loader et ne déclenche pas onPressed',
        (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        GamingButtonPrimary(
          text: 'Jouer',
          icon: FontAwesomeIcons.play,
          isLoading: true,
          onPressed: () => calls++,
        ),
      );

      expect(find.text('Jouer'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);


      expect(
        find.byWidgetPredicate(
          (w) => w is FaIcon && w.icon == FontAwesomeIcons.play,
        ),
        findsNothing,
      );

      await tester.tap(find.text('Jouer'));
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('width: rend une largeur fixe quand width est fourni',
        (tester) async {
      await _pumpInApp(
        tester,
        GamingButtonPrimary(
          text: 'Largeur',
          width: 240,
          onPressed: () {},
        ),
      );


      final btnFinder = find.byType(GamingButtonPrimary);
      expect(btnFinder, findsOneWidget);

      final size = tester.getSize(btnFinder);
      expect(size.width, 240);
    });
  });

  group('GamingButtonSecondary', () {
    testWidgets('déclenche onPressed', (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        GamingButtonSecondary(
          text: 'Rechercher',
          onPressed: () => calls++,
        ),
      );

      expect(find.text('Rechercher'), findsOneWidget);

      await tester.tap(find.text('Rechercher'));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('loading: affiche le loader et ne déclenche pas onPressed',
        (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        GamingButtonSecondary(
          text: 'Rechercher',
          isLoading: true,
          onPressed: () => calls++,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Rechercher'));
      await tester.pump();

      expect(calls, 0);
    });
  });

  group('GamingButtonGhost', () {
    testWidgets('déclenche onPressed', (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        GamingButtonGhost(
          text: 'Retour',
          onPressed: () => calls++,
        ),
      );

      expect(find.text('Retour'), findsOneWidget);

      await tester.tap(find.text('Retour'));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('loading: affiche le loader et ne déclenche pas onPressed',
        (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        GamingButtonGhost(
          text: 'Retour',
          isLoading: true,
          onPressed: () => calls++,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Retour'));
      await tester.pump();

      expect(calls, 0);
    });
  });

  group('GamingCard', () {
    testWidgets('affiche son child et déclenche onTap', (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        GamingCard(
          onTap: () => calls++,
          child: const Text('Contenu'),
        ),
      );

      expect(find.text('Contenu'), findsOneWidget);

      await tester.tap(find.text('Contenu'));
      await tester.pump();

      expect(calls, 1);
    });
  });

  group('PillBadge', () {
    testWidgets('affiche texte et déclenche onTap', (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        PillBadge(
          text: 'Badge',
          onTap: () => calls++,
        ),
      );

      expect(find.text('Badge'), findsOneWidget);

      await tester.tap(find.text('Badge'));
      await tester.pump();

      expect(calls, 1);
    });
  });

  group('Badges', () {
    testWidgets('BadgeSuccess affiche texte + icône si fournie', (tester) async {
      await _pumpInApp(
        tester,
        const BadgeSuccess(
          text: 'OK',
          icon: FontAwesomeIcons.check,
        ),
      );

      expect(find.text('OK'), findsOneWidget);

      final iconFinder = find.byWidgetPredicate(
        (w) => w is FaIcon && w.icon == FontAwesomeIcons.check,
      );
      expect(iconFinder, findsOneWidget);

      final fa = tester.widget<FaIcon>(iconFinder);
      expect(fa.color, TuuurTheme.brandGreen);
    });

    testWidgets('BadgeWarning affiche texte', (tester) async {
      await _pumpInApp(
        tester,
        const BadgeWarning(text: 'Attention'),
      );

      expect(find.text('Attention'), findsOneWidget);
    });

    testWidgets('BadgeInfo affiche texte + icône si fournie', (tester) async {
      await _pumpInApp(
        tester,
        const BadgeInfo(
          text: 'Info',
          icon: FontAwesomeIcons.circleInfo,
        ),
      );

      expect(find.text('Info'), findsOneWidget);

      final iconFinder = find.byWidgetPredicate(
        (w) => w is FaIcon && w.icon == FontAwesomeIcons.circleInfo,
      );
      expect(iconFinder, findsOneWidget);

      final fa = tester.widget<FaIcon>(iconFinder);
      expect(fa.color, TuuurTheme.brandCyan);
    });
  });

  group('CategoryButton', () {
    testWidgets('selected=true => texte blanc, icône blanche, onTap appelé',
        (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        CategoryButton(
          text: 'Science',
          icon: FontAwesomeIcons.flask,
          selected: true,
          onTap: () => calls++,
        ),
      );

      expect(find.text('Science'), findsOneWidget);

      final textW = tester.widget<Text>(find.text('Science'));
      expect(textW.style?.color, Colors.white);

      final iconFinder = find.byWidgetPredicate(
        (w) => w is FaIcon && w.icon == FontAwesomeIcons.flask,
      );
      expect(iconFinder, findsOneWidget);

      final fa = tester.widget<FaIcon>(iconFinder);
      expect(fa.color, Colors.white);

      await tester.tap(find.text('Science'));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets(
        'selected=false => texte brandLightGray, icône brandLightGray, onTap appelé',
        (tester) async {
      var calls = 0;

      await _pumpInApp(
        tester,
        CategoryButton(
          text: 'Histoire',
          icon: FontAwesomeIcons.book,
          selected: false,
          onTap: () => calls++,
        ),
      );

      expect(find.text('Histoire'), findsOneWidget);

      final textW = tester.widget<Text>(find.text('Histoire'));
      expect(textW.style?.color, TuuurTheme.brandLightGray);

      final iconFinder = find.byWidgetPredicate(
        (w) => w is FaIcon && w.icon == FontAwesomeIcons.book,
      );
      expect(iconFinder, findsOneWidget);

      final fa = tester.widget<FaIcon>(iconFinder);
      expect(fa.color, TuuurTheme.brandLightGray);

      await tester.tap(find.text('Histoire'));
      await tester.pump();

      expect(calls, 1);
    });
  });
}
