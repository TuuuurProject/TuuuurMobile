import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/api/auth/auth_models.dart';
import 'package:tuuuur_flutter/pages/home_page.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';

import 'group/group_test_helpers.dart'; // Pour le mock du secure storage

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setupSecureStorageMock);
  tearDownAll(tearDownSecureStorageMock);

  setUp(() async {
    kSecureStore.clear();
    await AuthStore.instance.signOut();
  });

  group('HomePage', () {
    testWidgets('HomePage peut être instanciée et affichée', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const HomePage()));
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Si connecté en Guest, HomePage force la déconnexion', (
      tester,
    ) async {
      // Connecter en guest
      await AuthStore.instance.signInWithSession(
        AuthSessionDto(
          user: UserDto(
            id: 'guest-1',
            nickName: 'GuestUser',
            email: '',
            avatar: null,
            isAdmin: false,
            isNew: false,
          ),
          token: AuthTokenDto(token: 'fake-guest-token'),
          isGoogleUser: false,
          raw: {},
        ),
      );

      expect(AuthStore.instance.isGuest, isTrue);

      await tester.pumpWidget(MaterialApp(home: const HomePage()));

      // Laisse le frame se terminer pour appeler addPostFrameCallback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(AuthStore.instance.isAuthenticated, isFalse);
      expect(AuthStore.instance.isGuest, isFalse);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
