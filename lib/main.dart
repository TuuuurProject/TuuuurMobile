import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/api_module.dart';
import 'stores/auth_store.dart';
import 'theme/tuuuur_theme.dart';
import 'navigation/app_router.dart';
import 'navigation/app_messengers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // UI système (status / nav bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: TuuurTheme.brandDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Hydrate l'état d'auth depuis le Secure Storage
  await AuthStore.instance.load();

  // Initialise le module API avec l'AuthStore
  ApiModule.instance.initialize(authStore: AuthStore.instance);

  runApp(
    MyAuthStore(
      notifier: AuthStore.instance,
      child: const TuuurApp(),
    ),
  );
}

class TuuurApp extends StatelessWidget {
  const TuuurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tuuuur - Quiz Gaming',
      debugShowCheckedModeBanner: false,
      theme: TuuurTheme.theme,
      routerConfig: appRouter,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling, // pas de scaling auto du texte
          ),
          child: child!,
        );
      },
    );
  }
}
