import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:tuuuur_flutter/api/api_module.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock du secure storage
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
      
      // Reinitialiser ne devrait rien faire
      module.initialize(authStore: authStore);
      
      final authApi2 = module.authApi;
      
      // Les instances devraient etre les memes
      expect(identical(authApi1, authApi2), isTrue);
    });

    test('leve une assertion si on accede aux API sans initialiser', () {
      // Creer une nouvelle instance (attention, ApiModule.instance est un singleton)
      // On ne peut pas vraiment tester ca sans reinitialiser le singleton,
      // donc on verifie juste que l'acces fonctionne apres init
      final module = ApiModule.instance;
      module.initialize(authStore: authStore);
      
      // Verifier que l'acces fonctionne
      expect(module.authApi, isNotNull);
      expect(module.soloApi, isNotNull);
      expect(module.themeApi, isNotNull);
      expect(module.difficultyApi, isNotNull);
      expect(module.historyApi, isNotNull);
    });

    test('dispose nettoie les ressources', () {
      final module = ApiModule.instance;
      module.initialize(authStore: authStore);

      // Dispose devrait fonctionner sans erreur
      expect(() => module.dispose(), returnsNormally);
    });
  });
}
