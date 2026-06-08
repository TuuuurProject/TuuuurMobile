import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/navigation/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Routeur de test avec des pages factices (évite de charger les vraies pages)
// ─────────────────────────────────────────────────────────────────────────────

GoRouter _buildTestRouter() {
  Widget page(String label) => Scaffold(body: Center(child: Text(label)));

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', name: 'home', builder: (c, s) => page('HOME')),
      GoRoute(path: '/solo', name: 'solo', builder: (c, s) => page('SOLO')),
      GoRoute(path: '/group', name: 'group', builder: (c, s) => page('GROUP')),
      GoRoute(path: '/online', name: 'online', builder: (c, s) => page('ONLINE')),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (c, s) => page('PROFILE'),
      ),
      GoRoute(path: '/login', name: 'login', builder: (c, s) => page('LOGIN')),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (c, s) => page('REGISTER'),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (c, s) => page('LEADERBOARD'),
      ),
      GoRoute(
        path: '/solo-quiz',
        name: 'solo-quiz',
        builder: (c, s) =>
            page('SOLOQUIZ ${s.uri.queryParameters['questions']}'),
      ),
      GoRoute(
        path: '/history/:partyId',
        name: 'history-quiz',
        builder: (c, s) => page(
          'HISTORY ${s.pathParameters['partyId']} '
          '${s.uri.queryParameters['isSolo']}',
        ),
      ),
    ],
  );
}

Future<void> _pumpRouter(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: _buildTestRouter()));
  await tester.pumpAndSettle();
}

void main() {
  group('SoloQuizParams.toJson', () {
    test('sérialise sans partyId', () {
      final params = SoloQuizParams(
        categories: ['sport', 'cinema'],
        questions: 10,
        difficulties: [1, 2],
      );

      final json = params.toJson();

      expect(json['categories'], 'sport,cinema');
      expect(json['questions'], '10');
      expect(json['difficulties'], '1,2');
      expect(json.containsKey('partyId'), isFalse);
    });

    test('inclut partyId quand présent', () {
      final params = SoloQuizParams(
        categories: ['general'],
        questions: 5,
        difficulties: [2],
        partyId: 'abc-123',
      );

      final json = params.toJson();

      expect(json['partyId'], 'abc-123');
    });
  });

  group('SoloQuizParams.fromJson', () {
    test('parse des paramètres complets', () {
      final params = SoloQuizParams.fromJson({
        'categories': 'sport,cinema',
        'questions': '15',
        'difficulties': '1,3',
        'partyId': 'p-1',
      });

      expect(params.categories, ['sport', 'cinema']);
      expect(params.questions, 15);
      expect(params.difficulties, [1, 3]);
      expect(params.partyId, 'p-1');
    });

    test('applique les valeurs par défaut sur map vide', () {
      final params = SoloQuizParams.fromJson({});

      expect(params.categories, ['general']);
      expect(params.questions, 10);
      expect(params.difficulties, [2]);
      expect(params.partyId, isNull);
    });

    test('ignore les difficultés non numériques', () {
      final params = SoloQuizParams.fromJson({'difficulties': '1,abc,3'});

      expect(params.difficulties, [1, 3]);
    });

    test('retombe sur [2] quand difficultés vides/invalides', () {
      final params = SoloQuizParams.fromJson({'difficulties': 'x,y'});

      expect(params.difficulties, [2]);
    });

    test('questions invalides retombe sur 10', () {
      final params = SoloQuizParams.fromJson({'questions': 'notanumber'});

      expect(params.questions, 10);
    });
  });

  group('AppNavigation extensions', () {
    testWidgets('go* naviguent vers les bons chemins', (tester) async {
      await _pumpRouter(tester);
      expect(find.text('HOME'), findsOneWidget);

      tester.element(find.text('HOME')).goSolo();
      await tester.pumpAndSettle();
      expect(find.text('SOLO'), findsOneWidget);

      tester.element(find.text('SOLO')).goGroup();
      await tester.pumpAndSettle();
      expect(find.text('GROUP'), findsOneWidget);

      tester.element(find.text('GROUP')).goGroupMode();
      await tester.pumpAndSettle();
      expect(find.text('GROUP'), findsOneWidget);

      tester.element(find.text('GROUP')).goOnline();
      await tester.pumpAndSettle();
      expect(find.text('ONLINE'), findsOneWidget);

      tester.element(find.text('ONLINE')).goProfile();
      await tester.pumpAndSettle();
      expect(find.text('PROFILE'), findsOneWidget);

      tester.element(find.text('PROFILE')).goLogin();
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);

      tester.element(find.text('LOGIN')).goRegister();
      await tester.pumpAndSettle();
      expect(find.text('REGISTER'), findsOneWidget);

      tester.element(find.text('REGISTER')).goLeaderboard();
      await tester.pumpAndSettle();
      expect(find.text('LEADERBOARD'), findsOneWidget);

      tester.element(find.text('LEADERBOARD')).goHome();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('goSoloQuiz pousse la route nommée solo-quiz', (tester) async {
      await _pumpRouter(tester);

      tester.element(find.text('HOME')).goSoloQuiz(
        categories: ['general'],
        questions: 7,
        difficulties: [2],
      );
      await tester.pumpAndSettle();

      expect(find.text('SOLOQUIZ 7'), findsOneWidget);
    });

    testWidgets('goHistoryQuiz pousse la route nommée history-quiz', (
      tester,
    ) async {
      await _pumpRouter(tester);

      tester.element(find.text('HOME')).goHistoryQuiz('party-9', isSolo: true);
      await tester.pumpAndSettle();

      expect(find.text('HISTORY party-9 true'), findsOneWidget);
    });

    testWidgets('goBack pop quand la pile le permet', (tester) async {
      await _pumpRouter(tester);

      tester.element(find.text('HOME')).push('/solo');
      await tester.pumpAndSettle();
      expect(find.text('SOLO'), findsOneWidget);

      tester.element(find.text('SOLO')).goBack();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('goBack revient à l\'accueil quand rien à pop', (tester) async {
      await _pumpRouter(tester);

      // go() remplace la pile : depuis /solo il n'y a rien à pop.
      tester.element(find.text('HOME')).goSolo();
      await tester.pumpAndSettle();
      expect(find.text('SOLO'), findsOneWidget);

      tester.element(find.text('SOLO')).goBack();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
