import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/auth/auth_store.dart';  
import 'theme/tuuuur_theme.dart';
import 'navigation/app_router.dart';

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
