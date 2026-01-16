import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Pages de l'application
import '../pages/home_page.dart';
import '../pages/solo/solo_select_page.dart';
import '../pages/solo/solo_quiz_page.dart';
import '../pages/group/group_mode_page.dart';
import '../pages/online/online_mode_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/auth/auth_login_page.dart';
import '../pages/auth/auth_register_page.dart';
import '../pages/auth/auth_verify_page.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/auth/reset_password_page.dart';
import '../pages/auth/change_password_page.dart';
import '../pages/leaderboard/leaderboard_page.dart';

// Modèles pour la navigation
class SoloQuizParams {
  final List<String> categories;
  final int questions;
  final int difficulty; // 1=Facile, 2=Moyen, 3=Difficile, 4=Extrême

  SoloQuizParams({
    required this.categories,
    required this.questions,
    required this.difficulty,
  });

  Map<String, String> toJson() => {
        'categories': categories.join(','),
        'questions': questions.toString(),
        'difficulty': difficulty.toString(),
      };

  factory SoloQuizParams.fromJson(Map<String, String> params) {
    return SoloQuizParams(
      categories: params['categories']?.split(',') ?? ['general'],
      questions: int.tryParse(params['questions'] ?? '10') ?? 10,
      difficulty: int.tryParse(params['difficulty'] ?? '2') ?? 2,
    );
  }
}

// Configuration du routeur Go Router
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Page d'accueil
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),

    // Mode Solo
    GoRoute(
      path: '/solo',
      name: 'solo',
      builder: (context, state) => const SoloSelectPage(),
    ),

    // Quiz Solo avec paramètres
    GoRoute(
      path: '/solo-quiz',
      name: 'solo-quiz',
      builder: (context, state) {
        final params = SoloQuizParams.fromJson(state.uri.queryParameters);
        return SoloQuizPage(
          categories: params.categories,
          questions: params.questions,
          difficulty: params.difficulty,
        );
      },
    ),

    // Mode Groupe
    GoRoute(
      path: '/group',
      name: 'group',
      builder: (context, state) => const GroupModePage(),
    ),

    // Mode En ligne
    GoRoute(
      path: '/online',
      name: 'online',
      builder: (context, state) => const OnlineModePage(),
    ),

    // Profil utilisateur
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),

    // Connexion
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AuthLoginPage(returnTo: extra?['returnTo'] as String?);
      },
    ),

    GoRoute(
      path: '/verify',
      builder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AuthVerifyPage(
          initialLogin: extra?['login'] as String?,
          emailHint: extra?['email'] as String?,
          returnTo: extra?['returnTo'] as String?,
        );
      },
    ),

    GoRoute(
      path: '/change-password',
      builder: (ctx, state) => const ChangePasswordPage(),
    ),

    // Inscription
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AuthRegisterPage(returnTo: extra?['returnTo'] as String?);
      },
    ),

    // Classement
    GoRoute(
      path: '/leaderboard',
      name: 'leaderboard',
      builder: (context, state) => const LeaderboardPage(),
    ),

    GoRoute(
      path: '/forgot-password',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ForgotPasswordPage(returnTo: extra?['returnTo'] as String?);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ResetPasswordPage(
          initialLogin: extra?['login'] as String?,
          returnTo: extra?['returnTo'] as String?,
        );
      },
    ),
  ],

  // Gestion des erreurs de navigation
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page non trouvée',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'La page "${state.fullPath}" n\'existe pas.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    ),
  ),
);

// Extensions utilitaires pour la navigation
extension AppNavigation on BuildContext {
  // Navigation vers les différentes pages
  void goHome() => go('/');
  void goSolo() => go('/solo');
  void goGroup() => go('/group');
  void goOnline() => go('/online');
  void goProfile() => go('/profile');
  void goLogin() => go('/login');
  void goRegister() => go('/register');
  void goLeaderboard() => go('/leaderboard');

  // Navigation avec paramètres pour le quiz solo
  void goSoloQuiz({
    required List<String> categories,
    required int questions,
    required int difficulty,
  }) {
    final params = SoloQuizParams(
      categories: categories,
      questions: questions,
      difficulty: difficulty,
    ).toJson();

    // Utilise le NOM de la route ('solo-quiz') + queryParameters
    GoRouter.of(this).pushNamed(
      'solo-quiz',
      queryParameters: params,
    );
  }

  // Navigation avec retour
  void goBack() {
    final router = GoRouter.of(this);

    // Est-ce que GoRouter peut revenir en arrière ?
    if (router.canPop()) {
      router.pop();
      return;
    }

    // Sinon, on tente le Navigator
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
      return;
    }

    // 3) Plus rien à pop → on va à l'accueil
    goHome();
  }
}

// Utilitaire pour construire les query strings
String _buildQueryString(Map<String, dynamic> params) {
  return params.entries
      .map(
        (entry) =>
            '${entry.key}=${Uri.encodeComponent(entry.value.toString())}',
      )
      .join('&');
}
