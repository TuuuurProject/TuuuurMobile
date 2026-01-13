// change_nickname_page_test.dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth_api_service.dart';
import 'package:tuuuur_flutter/navigation/app_messengers.dart'
    show rootScaffoldMessengerKey;
import 'package:tuuuur_flutter/pages/auth/change_nickname_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';
import 'package:tuuuur_flutter/widgets/gaming_widgets.dart';

class _DummyPage extends StatelessWidget {
  final String label;
  final Key pageKey;

  const _DummyPage(this.label, {required this.pageKey, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label, key: pageKey)),
    );
  }
}

/// Fake AuthApi pour éviter le réseau + capturer les params.
class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(ApiClient(baseUrl: 'http://localhost'));

  int callCount = 0;
  String? lastNickname;
  Map<String, String>? lastHeaders;

  ApiResponse<UserDto> immediateResponse = ApiResponse.ok(
    UserDto(id: 1, nickName: 'NewNick', email: 'a@b.com'),
    statusCode: 200,
  );

  Completer<ApiResponse<UserDto>>? _pending;
  void makePending() => _pending = Completer<ApiResponse<UserDto>>();
  void completePending(ApiResponse<UserDto> res) {
    _pending?.complete(res);
    _pending = null;
  }

  @override
  Future<ApiResponse<UserDto>> updateNickname({
    required String nickname,
    Map<String, String>? headers,
  }) {
    callCount += 1;
    lastNickname = nickname;
    lastHeaders = headers;

    if (_pending != null) return _pending!.future;
    return Future.value(immediateResponse);
  }
}

GoRouter _createRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const _DummyPage('home', pageKey: Key('page_home')),
      ),
      GoRoute(
        path: '/change-nickname',
        builder: (_, state) {
          final initial = state.uri.queryParameters['initial'];
          return ChangeNicknamePage(initialNickname: initial);
        },
      ),
    ],
  );
}

Widget _wrapWithApp(GoRouter router) {
  return MyAuthStore(
    notifier: AuthStore.instance,
    child: MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey, // ✅ snackbars
      routerConfig: router,
    ),
  );
}

Future<void> _pumpApp(WidgetTester tester, GoRouter router) async {
  await tester.binding.setSurfaceSize(const Size(1200, 2000));
  addTearDown(() async => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(_wrapWithApp(router));
  await tester.pumpAndSettle();
}

Future<void> _openChangeNicknamePage(
  WidgetTester tester,
  GoRouter router, {
  String? initialNickname,
}) async {
  final loc = initialNickname == null
      ? '/change-nickname'
      : '/change-nickname?initial=${Uri.encodeComponent(initialNickname)}';

  router.push(loc); // ✅ crée un historique pour pop()
  await tester.pumpAndSettle();

  expect(find.byType(ChangeNicknamePage), findsOneWidget);
}

Finder _nicknameField() => find.byType(TextField).first;

Future<void> _tapFinder(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Finder _snackBarWithMessage(String msg) {
  return find.byWidgetPredicate((w) {
    if (w is! SnackBar) return false;
    final c = w.content;
    return c is Text && c.data == msg;
  });
}

void main() {
  const MethodChannel _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async {
      switch (call.method) {
        case 'write':
        case 'delete':
        case 'deleteAll':
          return null;
        case 'read':
          return null;
        case 'readAll':
          return <String, String>{};
        case 'containsKey':
          return false;
        default:
          return null;
      }
    });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthApi _originalAuthApi;
  late _FakeAuthApi fake;

  setUpAll(() {
    _originalAuthApi = authApi;
  });

  setUp(() {
    fake = _FakeAuthApi();
    authApi = fake;
  });

  tearDownAll(() {
    authApi = _originalAuthApi;
  });

  group('ChangeNicknamePage - rendu', () {
    testWidgets('affiche les éléments essentiels', (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpApp(tester, router);
      await _openChangeNicknamePage(tester, router, initialNickname: 'OldNick');

      expect(find.text('Changer le pseudo'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      expect(find.text('Nouveau pseudo'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      expect(find.byType(GamingButtonSecondary), findsOneWidget);
      expect(find.byType(GamingButtonPrimary), findsOneWidget);

      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Valider'), findsOneWidget);

      // Le champ est prérempli avec initialNickname
      final tf = tester.widget<TextField>(_nicknameField());
      expect(tf.controller?.text, 'OldNick');
    });
  });

  group('ChangeNicknamePage - interactions', () {
    testWidgets('submit clavier (done) déclenche updateNickname', (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpApp(tester, router);
      await _openChangeNicknamePage(tester, router);

      fake.immediateResponse = ApiResponse.err(message: 'KO', statusCode: 400);

      await tester.enterText(_nicknameField(), 'NewNick');
      await tester.pump();

      await _tapFinder(tester, _nicknameField());
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fake.callCount, 1);
      expect(fake.lastNickname, 'NewNick');
    });

    testWidgets('loading: "Mise à jour…" + champ désactivé', (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpApp(tester, router);
      await _openChangeNicknamePage(tester, router);

      fake.makePending();

      await tester.enterText(_nicknameField(), 'NewNick');
      await tester.pump();

      await _tapFinder(tester, find.byType(GamingButtonPrimary));

      expect(find.text('Mise à jour…'), findsOneWidget);

      final tf = tester.widget<TextField>(_nicknameField());
      expect(tf.enabled, isFalse);

      // Terminer l’appel
      fake.completePending(
        ApiResponse.ok(UserDto(id: 1, nickName: 'NewNick'), statusCode: 200),
      );
      await tester.pumpAndSettle();
    });
  });

  group('ChangeNicknamePage - API & navigation', () {
    testWidgets('erreur API => affiche message et reste sur la page',
        (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpApp(tester, router);
      await _openChangeNicknamePage(tester, router);

      fake.immediateResponse = ApiResponse.err(
        message: 'Échec custom',
        statusCode: 400,
      );

      await tester.enterText(_nicknameField(), 'NewNick');
      await tester.pump();

      await _tapFinder(tester, find.byType(GamingButtonPrimary));

      expect(fake.callCount, 1);
      expect(find.text('Échec custom'), findsWidgets);
      expect(find.byType(ChangeNicknamePage), findsOneWidget);
    });

    testWidgets('succès API => SnackBar vert + pop vers home', (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpApp(tester, router);
      await _openChangeNicknamePage(tester, router);

      fake.immediateResponse = ApiResponse.ok(
        UserDto(id: 1, nickName: 'NewNick'),
        statusCode: 200,
      );

      final expectedHeaders = AuthStore.instance.authHeaders;

      await tester.enterText(_nicknameField(), 'NewNick');
      await tester.pump();

      await _tapFinder(tester, find.byType(GamingButtonPrimary));

      await tester.pumpAndSettle();

      final sbFinder = _snackBarWithMessage('Pseudo mis à jour ✅');
      expect(sbFinder, findsWidgets);

      final last = tester.widgetList<SnackBar>(sbFinder).toList().last;
      expect(last.backgroundColor, TuuurTheme.brandGreen);

      // pop => retour home
      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });
  });

  group('ChangeNicknamePage - navigation', () {
    testWidgets('Annuler => pop vers home', (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpApp(tester, router);
      await _openChangeNicknamePage(tester, router);

      await _tapFinder(tester, find.byType(GamingButtonSecondary));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });

    testWidgets('AppBar back => pop vers home', (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpApp(tester, router);
      await _openChangeNicknamePage(tester, router);

      await _tapFinder(tester, find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_home')), findsOneWidget);
    });
  });

  group('ChangeNicknamePage - cycle de vie', () {
    testWidgets('dispose correctement', (tester) async {
      final router = _createRouter(initialLocation: '/');
      await _pumpApp(tester, router);
      await _openChangeNicknamePage(tester, router);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('crée un State correct', () {
      const page = ChangeNicknamePage();
      final state = page.createState();
      expect(state, isNotNull);
    });
  });
}
