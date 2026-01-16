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
import 'package:tuuuur_flutter/widgets/gaming_widgets.dart';
import 'package:tuuuur_flutter/widgets/common_widgets.dart'; 
import 'package:tuuuur_flutter/api/theme_api_service.dart';
import 'package:tuuuur_flutter/api/difficulty_api_service.dart';
import 'package:tuuuur_flutter/api/api_client.dart' show ApiClient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
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
    // Sécurité anti pollution tests (Overlay + timer)
    ToastManager.hide();
    secureStore.clear();
    await AuthStore.instance.signOut();
  });

  Future<void> pumpSolo(
    WidgetTester tester, {
    required Size surfaceSize,
    required ThemesFetcher fetchThemes,
    required DifficultiesFetcher fetchDifficulties,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

    // 1) build initial
    await tester.pump();
    // 2) laisse didChangeDependencies déclencher les setState loading
    await tester.pump();
  }

  Future<void> pumpSoloWithRouter(
    WidgetTester tester, {
    required Size surfaceSize,
    required ThemesFetcher fetchThemes,
    required DifficultiesFetcher fetchDifficulties,
    void Function(Map<String, String> queryParams)? onSoloQuizParams,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

    // 1) build initial
    await tester.pump();
    // 2) laisse didChangeDependencies déclencher les setState loading
    await tester.pump();
  }

  Future<void> pumpForUi(WidgetTester tester) async {
    // 1) microtasks
    await tester.pump();
    // 2) laisse le temps aux animations/futures de finir (flutter_animate ~400ms)
    await tester.pump(const Duration(milliseconds: 900));
    // 3) flush
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
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          'icon': 'wand-magic-sparkles'
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
        surfaceSize: const Size(1000, 800),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      await tester.pumpAndSettle();

      // Catégories
      expect(find.text('Général'), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('Musique'), findsOneWidget);

      // Difficultés
      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Moyen'), findsOneWidget);
      expect(find.text('Difficile'), findsOneWidget);

      // Sélection catégories
      await tester.tap(find.text('Général'));
      await tester.pump();
      await tester.tap(find.text('Sport'));
      await tester.pump();

      // Start
      await tapStart(tester);
      await tester.pumpAndSettle();

      // Modal confirmation
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
            'icon': 'wand-magic-sparkles'
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
            'icon': 'wand-magic-sparkles'
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

  testWidgets(
    'themes: 401 -> affiche bouton "Se connecter" (sans le taper)',
    (tester) async {
      final diffsOk = api.ApiResponse.ok(<dynamic>[
        {'id': 1, 'label': 'Facile'},
        {'id': 2, 'label': 'Moyen'},
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => api.ApiResponse.err(
          message: null,
          statusCode: 401,
          raw: null,
        ),
        fetchDifficulties: ({headers}) async => diffsOk,
      );

      await tester.pumpAndSettle();

      expect(find.text('Thèmes'), findsOneWidget);
      expect(find.text('Session expirée ou non authentifié.'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    },
  );

  testWidgets(
    'difficultés: affiche état loading tant que le fetch n\'a pas répondu',
    (tester) async {
      final diffsCompleter = Completer<api.ApiResponse<List<dynamic>>>();

      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles'
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
          'icon': 'wand-magic-sparkles'
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
          'icon': 'wand-magic-sparkles'
        },
      ], statusCode: 200);

      await pumpSolo(
        tester,
        surfaceSize: const Size(1000, 900),
        fetchThemes: ({headers}) async => themesOk,
        fetchDifficulties: ({headers}) async => api.ApiResponse.err(
          message: null,
          statusCode: 401,
          raw: null,
        ),
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

  testWidgets(
    'difficultés: sélection par défaut = id 2 si présent',
    (tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles'
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
      expect(moyenText.style?.color, Colors.white);
    },
  );

  testWidgets(
    'difficultés: sélection unique change quand on tape un autre',
    (tester) async {
      final themesOk = api.ApiResponse.ok(<dynamic>[
        {
          'id': 1,
          'key': 'general',
          'name': 'Général',
          'icon': 'wand-magic-sparkles'
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

      expect(tester.widget<Text>(find.text('Moyen')).style?.color, Colors.white);

      await tester.tap(find.text('Difficile'));
      await tester.pump();

      expect(
        tester.widget<Text>(find.text('Difficile')).style?.color,
        Colors.white,
      );
      expect(
        tester.widget<Text>(find.text('Moyen')).style?.color,
        isNot(Colors.white),
      );
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
          'icon': 'wand-magic-sparkles'
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

      // Le pill "10 questions" doit être là (et seulement 1 texte "^\d+ questions$")
      expect(find.text('10 questions'), findsOneWidget);
      expect(numericQuestionsText(), findsOneWidget);

      // On évite les gestures (flaky) => onChanged direct
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      final slider = tester.widget<Slider>(sliderFinder);
      expect(slider.onChanged, isNotNull);

      slider.onChanged!.call(55.0);
      await tester.pump();

      expect(find.text('55 questions'), findsOneWidget);
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
          'icon': 'wand-magic-sparkles'
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

      // IMPORTANT: flush le Future.delayed(2s) du ToastManager
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
          'icon': 'wand-magic-sparkles'
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

      expect(find.text('Veuillez choisir une difficulté'), findsOneWidget);
      expect(find.text('Démarrer le quiz'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(find.text('Veuillez choisir une difficulté'), findsNothing);
    },
  );

  testWidgets(
    'mapping: supporte items non-Map (fields) + tri général en premier',
    (tester) async {
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
      expect(buttonsInCategories.first.text, equals('Général'));
    },
  );

  testWidgets(
    'themes: exception -> affiche "Erreur réseau:" (cover catch)',
    (tester) async {
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
    },
  );

  testWidgets(
    'icon fallback: mapping par nom (incl. jeu/gaming/vidéo) + _mInt num/string',
    (tester) async {
      // On force le switch(icon) à ne PAS matcher => fallback par name
      final themesOk = api.ApiResponse.ok(<dynamic>[
        // num => _mInt(v is num) cover
        {'id': 1.0, 'key': 'general', 'name': 'Général', 'icon': '???'},
        {'id': 2, 'key': 'history', 'name': 'Histoire', 'icon': '???'},
        {'id': 3, 'key': 'science', 'name': 'Science', 'icon': '???'},
        {'id': 4, 'key': 'sport', 'name': 'Sport', 'icon': '???'},
        {'id': 5, 'key': 'music', 'name': 'Musique', 'icon': '???'},
        {'id': 6, 'key': 'cinema', 'name': 'Cinéma', 'icon': '???'},
        {'id': 7, 'key': 'art', 'name': 'Art', 'icon': '???'},
        {'id': 8, 'key': 'geo', 'name': 'Géographie', 'icon': '???'},
        {'id': 9, 'key': 'tech', 'name': 'Technologie', 'icon': '???'},

        // String => _mInt(v is String) cover
        // key vide => l'id string est utilisé pour construire category.id
        {'id': '42', 'key': '', 'name': 'Jeu vidéo', 'icon': '???'},

        // fallback final => shapes
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

      // ✅ branche "jeu/gaming/vidéo/video" -> gamepad
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
        fetchThemes: ({headers}) async => api.ApiResponse.err(
          message: null,
          statusCode: 401,
          raw: null,
        ),
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
        {'id': 1, 'key': 'general', 'name': 'Général', 'icon': 'wand-magic-sparkles'},
        {'id': 2, 'key': 'sport', 'name': 'Sport', 'icon': 'medal'},
      ], statusCode: 200);

      // num + string => couvre aussi _mInt(v is num/String) côté difficultés
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

      // sélection d’au moins une catégorie
      await tester.tap(find.text('Général'));
      await tester.pump();

      // start => ouvre modal
      await tapStart(tester);
      await tester.pumpAndSettle();

      expect(find.text('Démarrer le quiz'), findsOneWidget);

      // Tap le dernier GamingButtonPrimary => en pratique celui du modal (confirm)
      final primaryBtns = find.byType(GamingButtonPrimary);
      expect(primaryBtns, findsWidgets);
      await tester.tap(primaryBtns.last);
      await tester.pumpAndSettle();

      // navigation OK
      expect(find.text('SOLO_QUIZ_PAGE'), findsOneWidget);

      // paramètres passés via queryParameters (goSoloQuiz)
      expect(gotParams, isNotNull);
      expect(gotParams!['categories'], 'general'); // une seule catégorie
      expect(gotParams!['questions'], '10'); // default
      expect(gotParams!['difficulty'], '2'); // défaut id=2 si présent
    },
  );

  testWidgets(
    'default fetchers: utilise themeApi/difficultyApi (fallback) et retourne OK',
    (tester) async {
      var themesCalled = false;
      var diffsCalled = false;

      final fakeThemeApi = FakeThemeApi(({headers}) async {
        themesCalled = true;
        expect(headers, isNull); // anon dans ces tests
        return api.ApiResponse.ok(
          <ThemeDto>[
            ThemeDto(id: 1, key: 'general', name: 'Général', icon: 'wand-magic-sparkles'),
            ThemeDto(id: 2, key: 'sport', name: 'Sport', icon: 'medal'),
          ],
          statusCode: 200,
        );
      });

      final fakeDiffApi = FakeDifficultyApi(({headers}) async {
        diffsCalled = true;
        expect(headers, isNull);
        return api.ApiResponse.ok(
          <DifficultyDto>[
            DifficultyDto(id: 1, label: 'Facile'),
            DifficultyDto(id: 2, label: 'Moyen'),
          ],
          statusCode: 200,
        );
      });

      await pumpSoloWithDefaultFetchers(
        tester,
        surfaceSize: const Size(1000, 900),
        themeApiOverride: fakeThemeApi,
        difficultyApiOverride: fakeDiffApi,
      );

      await tester.pumpAndSettle();

      // UI
      expect(find.text('Général'), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Moyen'), findsOneWidget);

      // ✅ prouve que les closures fallback ont été exécutées
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
        return api.ApiResponse.ok(
          <DifficultyDto>[DifficultyDto(id: 2, label: 'Moyen')],
          statusCode: 200,
        );
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
        return api.ApiResponse.ok(
          <ThemeDto>[
            ThemeDto(id: 1, key: 'general', name: 'Général', icon: 'wand-magic-sparkles'),
          ],
          statusCode: 200,
        );
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

      // Thèmes OK => settings visibles => erreur difficultés visible
      expect(find.text('⚙️ Paramètres'), findsOneWidget);
      expect(find.text('Difficulté'), findsOneWidget);
      expect(find.text('Boom diffs fallback'), findsOneWidget);

      final settingsCard = settingsCardFinder();
      final retryBtn = find.descendant(of: settingsCard, matching: find.text('↻ Réessayer'));
      expect(retryBtn, findsOneWidget);
    },
  );


}

/// Petits objets pour tester _mString/_mInt (branche "obj as dynamic")
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
  final Future<api.ApiResponse<List<ThemeDto>>> Function({Map<String, String>? headers})
      onGetThemes;

  FakeThemeApi(this.onGetThemes)
      : super(ApiClient(
          httpClient: http.Client(),
          baseUrl: 'http://localhost',
        ));

  @override
  Future<api.ApiResponse<List<ThemeDto>>> getThemes({Map<String, String>? headers}) {
    return onGetThemes(headers: headers);
  }
}

class FakeDifficultyApi extends DifficultyApi {
  final Future<api.ApiResponse<List<DifficultyDto>>> Function({Map<String, String>? headers})
      onGetDiffs;

  FakeDifficultyApi(this.onGetDiffs)
      : super(ApiClient(
          httpClient: http.Client(),
          baseUrl: 'http://localhost',
        ));

  @override
  Future<api.ApiResponse<List<DifficultyDto>>> getDifficulties({Map<String, String>? headers}) {
    return onGetDiffs(headers: headers);
  }
}
