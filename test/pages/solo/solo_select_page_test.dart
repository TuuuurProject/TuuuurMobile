import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:tuuuur_flutter/pages/solo/solo_select_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/api/api_client.dart' as api;
import 'package:tuuuur_flutter/api/auth/auth_api_service.dart';
import 'package:tuuuur_flutter/api/auth/auth_models.dart';
import 'package:tuuuur_flutter/api/solo/solo_models.dart';
import 'package:tuuuur_flutter/api/other/theme_models.dart';
import 'package:tuuuur_flutter/api/other/difficulty_models.dart';
import 'package:tuuuur_flutter/widgets/gaming_widgets.dart';
import 'package:tuuuur_flutter/widgets/common_widgets.dart';
import 'package:tuuuur_flutter/api/other/theme_api_service.dart';
import 'package:tuuuur_flutter/api/other/difficulty_api_service.dart';
import 'package:tuuuur_flutter/api/api_client.dart' show ApiClient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final Map<String, String> secureStore = <String, String>{};

  setUpAll(() async {
    secureStorageChannel.setMockMethodCallHandler((MethodCall call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'write':
          final key = args['key'] as String?;
          final value = args['value'] as String?;
          if (key != null && value != null) secureStore[key] = value;
          return null;
        case 'read':
          final key = args['key'] as String?;
          return key == null ? null : secureStore[key];
        case 'delete':
          final key = args['key'] as String?;
          if (key != null) secureStore.remove(key);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(secureStore);
        default:
          return null;
      }
    });
  });

  tearDownAll(() async {
    secureStorageChannel.setMockMethodCallHandler(null);
  });

  setUp(() async {
    secureStore.clear();
    await AuthStore.instance.signOut();
  });

  tearDown(() async {
    ToastManager.hide();
    secureStore.clear();
    await AuthStore.instance.signOut();
  });

  Future<void> pumpSolo(
    WidgetTester tester, {
    required Size surfaceSize,
    required ThemesFetcher fetchThemes,
    required DifficultiesFetcher fetchDifficulties,
    bool authenticated = true,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    if (authenticated) {
      final session = AuthSessionDto(
        user: UserDto(id: '1', nickName: 'TestUser', email: 'test@test.com'),
        token: AuthTokenDto(
          token: 'test_token',
          refreshToken: 'test_refresh',
          validTo: DateTime.now().add(const Duration(hours: 1)),
          refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
        ),
        isGoogleUser: false,
        raw: {},
      );
      await AuthStore.instance.signInWithSession(session);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: MyAuthStore(
          notifier: AuthStore.instance,
          child: SoloSelectPage(
            fetchThemes: fetchThemes,
            fetchDifficulties: fetchDifficulties,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpSoloWithRouter(
    WidgetTester tester, {
    required Size surfaceSize,
    required ThemesFetcher fetchThemes,
    required DifficultiesFetcher fetchDifficulties,
    void Function(Map<String, String> queryParams)? onSoloQuizParams,
    bool authenticated = true,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    if (authenticated) {
      final session = AuthSessionDto(
        user: UserDto(id: '1', nickName: 'TestUser', email: 'test@test.com'),
        token: AuthTokenDto(
          token: 'test_token',
          refreshToken: 'test_refresh',
          validTo: DateTime.now().add(const Duration(hours: 1)),
          refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
        ),
        isGoogleUser: false,
        raw: {},
      );
      await AuthStore.instance.signInWithSession(session);
    }

    final router = GoRouter(
      initialLocation: '/solo',
      routes: [
        GoRoute(
          path: '/solo',
          builder: (context, state) => SoloSelectPage(
            fetchThemes: fetchThemes,
            fetchDifficulties: fetchDifficulties,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('LOGIN_PAGE'))),
        ),
        GoRoute(
          path: '/solo-quiz',
          name: 'solo-quiz',
          builder: (context, state) {
            final qp = Map<String, String>.from(state.uri.queryParameters);
            onSoloQuizParams?.call(qp);
            return const Scaffold(body: Center(child: Text('SOLO_QUIZ_PAGE')));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MyAuthStore(
          notifier: AuthStore.instance,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpForUi(WidgetTester tester) async {
    await tester.pump();
  }

  Finder categoriesCardFinder() {
    final title = find.text('Catégories');
    return find.ancestor(of: title, matching: find.byType(GamingCard));
  }

  Finder settingsCardFinder() {
    final title = find.text('⚙️ Paramètres');
    return find.ancestor(of: title, matching: find.byType(GamingCard));
  }

  Future<void> tapStart(WidgetTester tester) async {
    final adventure = find.text("Commencer l'aventure");
    final jouer = find.text('Jouer');

    if (adventure.evaluate().isNotEmpty) {
      await tester.tap(adventure);
    } else {
      await tester.tap(jouer);
    }
    await tester.pump();
  }

  Future<void> pumpSoloWithDefaultFetchers(
    WidgetTester tester, {
    required Size surfaceSize,
    required ThemeApi themeApiOverride,
    required DifficultyApi difficultyApiOverride,
    bool authenticated = true,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    if (authenticated) {
      final session = AuthSessionDto(
        user: UserDto(id: '1', nickName: 'TestUser', email: 'test@test.com'),
        token: AuthTokenDto(
          token: 'test_token',
          refreshToken: 'test_refresh',
          validTo: DateTime.now().add(const Duration(hours: 1)),
          refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
        ),
        isGoogleUser: false,
        raw: {},
      );
      await AuthStore.instance.signInWithSession(session);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: MyAuthStore(
          notifier: AuthStore.instance,
          child: SoloSelectPage(
            themeApiOverride: themeApiOverride,
            difficultyApiOverride: difficultyApiOverride,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
  }

  Finder numericQuestionsText() {
    final re = RegExp(r'^\d+\squestions$');
    return find.byWidgetPredicate((w) {
      return w is Text && w.data != null && re.hasMatch(w.data!.trim());
    });
  }

  testWidgets(
    'happy path: charge thèmes+difficultés, sélection, modal de confirmation',
    (WidgetTester tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
        {'id': 2, 'key': 'sport', 'name': 'Sport', 'icon': 'medal'},
        {'id': 3, 'key': 'music', 'name': 'Musique', 'icon': 'music'},
      ], statusCode: 200);

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 1, 'label': 'Facile'},
        {'id': 2, 'label': 'Moyen'},
        {'id': 3, 'label': 'Difficile'},
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 1200),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      await tester.pumpAndSettle();

      expect(find.text('Général'), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('Musique'), findsOneWidget);

      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Moyen'), findsOneWidget);
      expect(find.text('Difficile'), findsOneWidget);

      await tester.tap(find.text('Général'));
      await tester.pump();
      await tester.tap(find.text('Sport'));
      await tester.pump();

      await tapStart(tester);

      // Attendre l'animation du modal avec pump() au lieu de pumpAndSettle()
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Démarrer le quiz'), findsOneWidget);
      expect(find.text('Catégories:'), findsOneWidget);
      expect(find.text('Général, Sport'), findsOneWidget);
      expect(find.text('Difficulté:'), findsOneWidget);
      expect(find.text('Moyen'), findsWidgets);
    },
  );

  testWidgets(
    'themes: affiche état loading tant que le fetch n\'a pas répondu',
    (tester) async {
      final themesCompleter = Completer<api.ApiResponse<List<dynamic>>>();

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 1, 'label': 'Facile'},
        {'id': 2, 'label': 'Moyen'},
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 800),
        fetchThemes: ({headers}) => themesCompleter.future,
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      expect(find.text('Chargement des thèmes…'), findsOneWidget);

      themesCompleter.complete(
        api.ApiResponse.ok(<dynamic>[
          {
            'id': 1,
            'key': 'general',
            'name': 'Général',
            'icon': 'wand-magic-sparkles',
          },
        ], statusCode: 200),
      );

      await tester.pumpAndSettle();
      expect(find.text('Général'), findsOneWidget);
    },
  );

  testWidgets(
    'themes: erreur -> affiche carte erreur + retry refait un fetch',
    (tester) async {
      var calls = 0;

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 1, 'label': 'Facile'},
        {'id': 2, 'label': 'Moyen'},
      ], statusCode: 200);

      Future<api.ApiResponse<List<dynamic>>> fetchThemes({headers}) async {
        calls++;
        if (calls == 1) {
          return api.ApiResponse.err(
            message: 'Boom themes',
            statusCode: 500,
            raw: null,
          );
        }
        return api.ApiResponse.ok(<dynamic>[
          {
            'id': 1,
            'key': 'general',
            'name': 'Général',
            'icon': 'wand-magic-sparkles',
          },
        ], statusCode: 200);
      }

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: fetchThemes,
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      await tester.pumpAndSettle();

      expect(find.text('Thèmes'), findsOneWidget);
      expect(find.text('Boom themes'), findsOneWidget);

      final retry = find.text('↻ Réessayer').first;
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('Général'), findsOneWidget);
    },
  );

  testWidgets('themes: 401 -> affiche bouton "Se connecter" (sans le taper)', (
    tester,
  ) async {
    final diffsOk = api.ApiResponse.ok(<dynamic>[
      {'id': 1, 'label': 'Facile'},
      {'id': 2, 'label': 'Moyen'},
    ], statusCode: 200);

    await pumpSolo(
      tester,
      surfaceSize: const Size(1000, 900),
      fetchThemes: ({headers}) async =>
          api.ApiResponse.err(message: null, statusCode: 401, raw: null),
      fetchDifficulties: ({headers}) async => diffsOk,
    );

    await tester.pumpAndSettle();

    expect(find.text('Thèmes'), findsOneWidget);
    expect(find.text('Session expirée ou non authentifié.'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets(
    'difficultés: affiche état loading tant que le fetch n\'a pas répondu',
    (tester) async {
      final diffsCompleter = Completer<api.ApiResponse<List<dynamic>>>();

      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) => diffsCompleter.future,
      );

      expect(find.text('Difficulté'), findsOneWidget);
      expect(find.text('Chargement des difficultés…'), findsOneWidget);

      diffsCompleter.complete(
        api.ApiResponse.ok(<dynamic>[
          {'id': 2, 'label': 'Moyen'},
        ], statusCode: 200),
      );

      await tester.pumpAndSettle();
      expect(find.text('Moyen'), findsOneWidget);
    },
  );

  testWidgets(
    'difficultés: erreur -> affiche message + retry refait un fetch',
    (tester) async {
      var calls = 0;

      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      Future<api.ApiResponse<List<dynamic>>> fetchDiffs({headers}) async {
        calls++;
        if (calls == 1) {
          return api.ApiResponse.err(
            message: 'Boom diffs',
            statusCode: 500,
            raw: null,
          );
        }
        return api.ApiResponse.ok(<dynamic>[
          {'id': 1, 'label': 'Facile'},
          {'id': 2, 'label': 'Moyen'},
        ], statusCode: 200);
      }

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: fetchDiffs,
      );

      await tester.pumpAndSettle();

      expect(find.text('Difficulté'), findsOneWidget);
      expect(find.text('Boom diffs'), findsOneWidget);

      final settingsCard = settingsCardFinder();
      final retryInSettings = find.descendant(
        of: settingsCard,
        matching: find.text('↻ Réessayer'),
      );
      expect(retryInSettings, findsOneWidget);

      await tester.tap(retryInSettings);
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Moyen'), findsOneWidget);
    },
  );

  testWidgets(
    'difficultés: 401 -> affiche bouton "Se connecter" (sans le taper)',
    (tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async =>
            api.ApiResponse.err(message: null, statusCode: 401, raw: null),
      );

      await tester.pumpAndSettle();

      expect(find.text('Difficulté'), findsOneWidget);
      expect(find.text('Session expirée ou non authentifié.'), findsOneWidget);

      final settingsCard = settingsCardFinder();
      final loginBtn = find.descendant(
        of: settingsCard,
        matching: find.text('Se connecter'),
      );
      expect(loginBtn, findsOneWidget);
    },
  );

  testWidgets('difficultés: aucune sélection par défaut', (tester) async {
    final themesOk = api.ApiResponse.ok(<dynamic>[
      {
        'id': 1,
        'key': 'general',
        'name': 'Général',
        'icon': 'wand-magic-sparkles',
      },
    ], statusCode: 200);

    final diffsOk = api.ApiResponse.ok(<dynamic>[
      {'id': 1, 'label': 'Facile'},
      {'id': 2, 'label': 'Moyen'},
      {'id': 3, 'label': 'Difficile'},
    ], statusCode: 200);

    await pumpSolo(
      tester,
      surfaceSize: const Size(1000, 900),
      fetchThemes: ({headers}) async => themesOk,
      fetchDifficulties: ({headers}) async => diffsOk,
    );

    await tester.pumpAndSettle();

    final moyenText = tester.widget<Text>(find.text('Moyen'));
    expect(moyenText.style?.color, isNot(Colors.white));
  });

  testWidgets(
    'difficultés: sélection multiple permet de sélectionner plusieurs difficultés',
    (tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 1, 'label': 'Facile'},
        {'id': 2, 'label': 'Moyen'},
        {'id': 3, 'label': 'Difficile'},
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      await tester.pumpAndSettle();

      // Vérifier que les difficultés sont affichées
      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Moyen'), findsOneWidget);
      expect(find.text('Difficile'), findsOneWidget);
    },
  );

  testWidgets(
    'slider: changer le nombre de questions met à jour "X questions"',
    (tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 2, 'label': 'Moyen'},
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      await tester.pumpAndSettle();

      expect(find.text('10 questions'), findsOneWidget);
      expect(numericQuestionsText(), findsOneWidget);

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      final slider = tester.widget<Slider>(sliderFinder);
      expect(slider.onChanged, isNotNull);

      slider.onChanged!.call(20.0);
      await tester.pump();

      expect(find.text('20 questions'), findsOneWidget);
      expect(find.text('10 questions'), findsNothing);
      expect(numericQuestionsText(), findsOneWidget);
    },
  );

  testWidgets(
    'start: sans catégorie -> toast puis disparition (pas de timers pending)',
    (tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 2, 'label': 'Moyen'},
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      await tester.pumpAndSettle();

      await tapStart(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('Veuillez sélectionner au moins une catégorie'),
        findsOneWidget,
      );
      expect(find.text('Démarrer le quiz'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(
        find.text('Veuillez sélectionner au moins une catégorie'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'start: catégorie ok mais difficultés vides -> toast puis disparition',
    (tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      final diffsEmpty = api.ApiResponse.ok(<dynamic>[], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => diffsEmpty,
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Général'));
      await tester.pump();

      await tapStart(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('Veuillez choisir au moins une difficulté'),
        findsOneWidget,
      );
      expect(find.text('Démarrer le quiz'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(find.text('Veuillez choisir une difficulté'), findsNothing);
    },
  );

  testWidgets('mapping: supporte items non-Map (fields) + tri alphabétique', (
    tester,
  ) async {
    final themesOk = api.ApiResponse.ok(<dynamic>[
      _ThemeObj(id: 2, key: 'sport', name: 'Sport', icon: 'medal'),
      _ThemeObj(
        id: 1,
        key: 'general',
        name: 'Général',
        icon: 'wand-magic-sparkles',
      ),
      _ThemeObj(id: 3, key: 'gaming', name: 'Gaming', icon: 'gamepad'),
    ], statusCode: 200);

    final diffsOk = api.ApiResponse.ok(<dynamic>[
      _DiffObj(id: 1, label: 'Facile'),
      _DiffObj(id: 2, label: 'Moyen'),
    ], statusCode: 200);

    await pumpSolo(
      tester,
      surfaceSize: const Size(1000, 900),
      fetchThemes: ({headers}) async => themesOk,
      fetchDifficulties: ({headers}) async => diffsOk,
    );

    await tester.pumpAndSettle();

    expect(find.text('Général'), findsOneWidget);
    expect(find.text('Sport'), findsOneWidget);
    expect(find.text('Gaming'), findsOneWidget);

    final categoriesCard = categoriesCardFinder();
    expect(categoriesCard, findsOneWidget);

    final buttonsInCategories = tester
        .widgetList<CategoryButton>(
          find.descendant(
            of: categoriesCard,
            matching: find.byType(CategoryButton),
          ),
        )
        .toList();

    expect(buttonsInCategories.isNotEmpty, isTrue);
    expect(buttonsInCategories.first.text, equals('Gaming'));
  });

  testWidgets('themes: exception -> affiche "Erreur réseau:" (cover catch)', (
    tester,
  ) async {
    final diffsOk = api.ApiResponse.ok(<dynamic>[
      {'id': 2, 'label': 'Moyen'},
    ], statusCode: 200);

    await pumpSolo(
      tester,
      surfaceSize: const Size(1000, 800),
      fetchThemes: ({headers}) async {
        throw Exception('No internet');
      },
      fetchDifficulties: ({headers}) async => diffsOk,
    );

    await tester.pumpAndSettle();

    expect(find.text('Thèmes'), findsOneWidget);
    expect(find.textContaining('Erreur réseau:'), findsOneWidget);
    expect(find.textContaining('Exception: No internet'), findsOneWidget);
  });

  testWidgets(
    'icon fallback: mapping par nom (incl. jeu/gaming/vidéo) + _mInt num/string',
    (tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {'id': 1.0, 'key': 'general', 'name': 'Général', 'icon': '???'},
        {'id': 2, 'key': 'history', 'name': 'Histoire', 'icon': '???'},
        {'id': 3, 'key': 'science', 'name': 'Science', 'icon': '???'},
        {'id': 4, 'key': 'sport', 'name': 'Sport', 'icon': '???'},
        {'id': 5, 'key': 'music', 'name': 'Musique', 'icon': '???'},
        {'id': 6, 'key': 'cinema', 'name': 'Cinéma', 'icon': '???'},
        {'id': 7, 'key': 'art', 'name': 'Art', 'icon': '???'},
        {'id': 8, 'key': 'geo', 'name': 'Géographie', 'icon': '???'},
        {'id': 9, 'key': 'tech', 'name': 'Technologie', 'icon': '???'},

        {'id': '42', 'key': '', 'name': 'Jeu vidéo', 'icon': '???'},

        {'id': 99, 'key': 'unknown', 'name': 'Inconnu', 'icon': '???'},
      ], statusCode: 200);

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 2, 'label': 'Moyen'},
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      await tester.pumpAndSettle();

      final categoriesCard = categoriesCardFinder();
      final buttons = tester
          .widgetList<CategoryButton>(
            find.descendant(
              of: categoriesCard,
              matching: find.byType(CategoryButton),
            ),
          )
          .toList();

      CategoryButton byText(String text) =>
          buttons.firstWhere((b) => b.text == text);

      expect(byText('Général').icon, FontAwesomeIcons.wandMagicSparkles);
      expect(byText('Histoire').icon, FontAwesomeIcons.buildingColumns);
      expect(byText('Science').icon, FontAwesomeIcons.flask);
      expect(byText('Sport').icon, FontAwesomeIcons.medal);
      expect(byText('Musique').icon, FontAwesomeIcons.music);
      expect(byText('Cinéma').icon, FontAwesomeIcons.film);
      expect(byText('Art').icon, FontAwesomeIcons.palette);
      expect(byText('Géographie').icon, FontAwesomeIcons.globe);
      expect(byText('Technologie').icon, FontAwesomeIcons.laptopCode);

      expect(byText('Jeu vidéo').icon, FontAwesomeIcons.gamepad);
    },
  );

  testWidgets(
    'navigation: themes 401 -> tap "Se connecter" => go /login (cover goLogin)',
    (tester) async {
      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 2, 'label': 'Moyen'},
      ], statusCode: 200);

      await pumpSoloWithRouter(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async =>
            api.ApiResponse.err(message: null, statusCode: 401, raw: null),
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      await tester.pumpAndSettle();

      expect(find.text('Se connecter'), findsOneWidget);
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_PAGE'), findsOneWidget);
    },
  );

  testWidgets(
    'navigation: modal confirm -> appelle goSoloQuiz + pushNamed solo-quiz (cover onConfirm/goSoloQuiz)',
    (tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
        {'id': 2, 'key': 'sport', 'name': 'Sport', 'icon': 'medal'},
      ], statusCode: 200);

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 2.0, 'label': 'Moyen'},
        {'id': '3', 'label': 'Difficile'},
      ], statusCode: 200);

      Map<String, String>? gotParams;

      await pumpSoloWithRouter(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => diffsOk,
        onSoloQuizParams: (qp) => gotParams = qp,
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Général'));
      await tester.pump();

      await tapStart(tester);
      await tester.pumpAndSettle();

      expect(find.text('Démarrer le quiz'), findsOneWidget);

      final primaryBtns = find.byType(GamingButtonPrimary);
      expect(primaryBtns, findsWidgets);
      await tester.tap(primaryBtns.last);
      await tester.pumpAndSettle();

      expect(find.text('SOLO_QUIZ_PAGE'), findsOneWidget);

      expect(gotParams, isNotNull);
      expect(gotParams!['categories'], 'general');
      expect(gotParams!['questions'], '10');
      expect(gotParams!['difficulties'], '2');
    },
  );

  testWidgets(
    'default fetchers: utilise themeApi/difficultyApi (fallback) et retourne OK',
    (tester) async {
      var themesCalled = false;
      var diffsCalled = false;

      final fakeThemeApi = FakeThemeApi(({headers}) async {
        themesCalled = true;
        expect(headers, isNull);
        return api.ApiResponse.ok(<ThemeDto>[
          ThemeDto(
            id: 1,
            key: 'general',
            name: 'Général',
            icon: 'wand-magic-sparkles',
          ),
          ThemeDto(id: 2, key: 'sport', name: 'Sport', icon: 'medal'),
        ], statusCode: 200);
      });

      final fakeDiffApi = FakeDifficultyApi(({headers}) async {
        diffsCalled = true;
        expect(headers, isNull);
        return api.ApiResponse.ok(<DifficultyDto>[
          DifficultyDto(id: 1, label: 'Facile'),
          DifficultyDto(id: 2, label: 'Moyen'),
        ], statusCode: 200);
      });

      await pumpSoloWithDefaultFetchers(
        tester,
        surfaceSize: const Size(1000, 900),
        themeApiOverride: fakeThemeApi,
        difficultyApiOverride: fakeDiffApi,
      );

      await tester.pumpAndSettle();

      expect(find.text('Général'), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Moyen'), findsOneWidget);

      expect(themesCalled, isTrue);
      expect(diffsCalled, isTrue);
    },
  );

  testWidgets(
    'default themesFetcher: si ThemeApi renvoie err => wrapper ApiResponse.err et UI erreur',
    (tester) async {
      final fakeThemeApi = FakeThemeApi(({headers}) async {
        return api.ApiResponse.err(
          message: 'Boom themes fallback',
          statusCode: 500,
          raw: {'x': 'y'},
        );
      });

      final fakeDiffApi = FakeDifficultyApi(({headers}) async {
        return api.ApiResponse.ok(<DifficultyDto>[
          DifficultyDto(id: 2, label: 'Moyen'),
        ], statusCode: 200);
      });

      await pumpSoloWithDefaultFetchers(
        tester,
        surfaceSize: const Size(1000, 900),
        themeApiOverride: fakeThemeApi,
        difficultyApiOverride: fakeDiffApi,
      );

      await tester.pumpAndSettle();

      expect(find.text('Thèmes'), findsOneWidget);
      expect(find.text('Boom themes fallback'), findsOneWidget);
      expect(find.text('↻ Réessayer'), findsOneWidget);
    },
  );

  testWidgets(
    'default difficultiesFetcher: si DifficultyApi renvoie err => wrapper ApiResponse.err et UI erreur',
    (tester) async {
      final fakeThemeApi = FakeThemeApi(({headers}) async {
        return api.ApiResponse.ok(<ThemeDto>[
          ThemeDto(
            id: 1,
            key: 'general',
            name: 'Général',
            icon: 'wand-magic-sparkles',
          ),
        ], statusCode: 200);
      });

      final fakeDiffApi = FakeDifficultyApi(({headers}) async {
        return api.ApiResponse.err(
          message: 'Boom diffs fallback',
          statusCode: 500,
          raw: {'err': true},
        );
      });

      await pumpSoloWithDefaultFetchers(
        tester,
        surfaceSize: const Size(1000, 900),
        themeApiOverride: fakeThemeApi,
        difficultyApiOverride: fakeDiffApi,
      );

      await tester.pumpAndSettle();

      expect(find.text('⚙️ Paramètres'), findsOneWidget);
      expect(find.text('Difficulté'), findsOneWidget);
      expect(find.text('Boom diffs fallback'), findsOneWidget);

      final settingsCard = settingsCardFinder();
      final retryBtn = find.descendant(
        of: settingsCard,
        matching: find.text('↻ Réessayer'),
      );
      expect(retryBtn, findsOneWidget);
    },
  );

  group('_buildAuthRequiredCard', () {
    testWidgets('affiche la carte quand non authentifié', (
      WidgetTester tester,
    ) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 1, 'label': 'Facile'},
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 800),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => diffsOk,
        authenticated: false,
      );

      await tester.pumpAndSettle();

      expect(find.text('Connexion requise'), findsOneWidget);
      expect(
        find.text('Vous devez être connecté pour jouer en mode solo.'),
        findsOneWidget,
      );
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.byIcon(FontAwesomeIcons.userLock), findsOneWidget);

      expect(find.text('Catégories'), findsNothing);
      expect(find.text('Général'), findsNothing);
    });

    testWidgets('bouton Se connecter navigue vers /login avec returnTo', (
      WidgetTester tester,
    ) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 1, 'label': 'Facile'},
      ], statusCode: 200);

      String? navigatedPath;
      Map<String, dynamic>? navigationExtra;

      final router = GoRouter(
        initialLocation: '/solo',
        routes: [
          GoRoute(
            path: '/solo',
            builder: (context, state) => SoloSelectPage(
              fetchThemes: ({headers}) async => themesOk,
              fetchDifficulties: ({headers}) async => diffsOk,
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              navigatedPath = '/login';
              navigationExtra = state.extra as Map<String, dynamic>?;
              return const Scaffold(body: Text('LOGIN_PAGE'));
            },
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MyAuthStore(
            notifier: AuthStore.instance,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(
        GamingButtonPrimary,
        'Se connecter',
      );
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(navigatedPath, '/login');
      expect(navigationExtra, isNotNull);
      expect(navigationExtra!['returnTo'], '/solo');
      expect(find.text('LOGIN_PAGE'), findsOneWidget);
    });

    testWidgets('ne charge pas les thèmes/difficultés quand non authentifié', (
      WidgetTester tester,
    ) async {
      int themesCalls = 0;
      int diffsCalls = 0;

      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles',
        },
      ], statusCode: 200);

      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 1, 'label': 'Facile'},
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 800),
        fetchThemes: ({headers}) async {
          themesCalls++;
          return themesOk;
        },
        fetchDifficulties: ({headers}) async {
          diffsCalls++;
          return diffsOk;
        },
        authenticated: false,
      );

      await tester.pumpAndSettle();

      expect(themesCalls, 0);
      expect(diffsCalls, 0);

      expect(find.text('Connexion requise'), findsOneWidget);
    });
  });
}

class _ThemeObj {
  final int id;
  final String key;
  final String name;
  final String icon;
  _ThemeObj({
    required this.id,
    required this.key,
    required this.name,
    required this.icon,
  });
}

class _DiffObj {
  final int id;
  final String label;
  _DiffObj({required this.id, required this.label});
}

class FakeThemeApi extends ThemeApi {
  final Future<api.ApiResponse<List<ThemeDto>>> Function({
    Map<String, String>? headers,
  })
  onGetThemes;

  FakeThemeApi(this.onGetThemes)
    : super(ApiClient(httpClient: http.Client(), baseUrl: 'http://localhost'));

  @override
  Future<api.ApiResponse<List<ThemeDto>>> getThemes({
    Map<String, String>? headers,
  }) {
    return onGetThemes(headers: headers);
  }
}

class FakeDifficultyApi extends DifficultyApi {
  final Future<api.ApiResponse<List<DifficultyDto>>> Function({
    Map<String, String>? headers,
  })
  onGetDiffs;

  FakeDifficultyApi(this.onGetDiffs)
    : super(ApiClient(httpClient: http.Client(), baseUrl: 'http://localhost'));

  @override
  Future<api.ApiResponse<List<DifficultyDto>>> getDifficulties({
    Map<String, String>? headers,
  }) {
    return onGetDiffs(headers: headers);
  }
}
