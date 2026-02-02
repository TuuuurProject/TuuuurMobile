import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:tuuuur_flutter/api/api_module.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();


  FlutterSecureStorage.setMockInitialValues({});

  group('ApiModule integration', () {
    late AuthStore authStore;

    setUp(() async {
      authStore = AuthStore.instance;
      await authStore.signOut();
    });

    test('initialize cree toutes les instances API', () {
      final module = ApiModule.instance;
      module.initialize(authStore: authStore);

      expect(() => module.authApi, returnsNormally);
      expect(() => module.soloApi, returnsNormally);
      expect(() => module.themeApi, returnsNormally);
      expect(() => module.difficultyApi, returnsNormally);
      expect(() => module.historyApi, returnsNormally);
    });

    test('appeler initialize plusieurs fois ne fait rien', () {
      final module = ApiModule.instance;
      module.initialize(authStore: authStore);

      final authApi1 = module.authApi;


      module.initialize(authStore: authStore);

      final authApi2 = module.authApi;


      expect(identical(authApi1, authApi2), isTrue);
    });

    test('leve une assertion si on accede aux API sans initialiser', () {



      final module = ApiModule.instance;
      module.initialize(authStore: authStore);


      expect(module.authApi, isNotNull);
      expect(module.soloApi, isNotNull);
      expect(module.themeApi, isNotNull);
      expect(module.difficultyApi, isNotNull);
      expect(module.historyApi, isNotNull);
    });

    test('dispose nettoie les ressources', () {
      final module = ApiModule.instance;
      module.initialize(authStore: authStore);


      expect(() => module.dispose(), returnsNormally);
    });
  });
}
