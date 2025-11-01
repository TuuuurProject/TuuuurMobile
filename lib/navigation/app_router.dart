import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_history.dart';

// Pages de l'application
import '../pages/home_page.dart';
import '../pages/solo/solo_select_page.dart';
import '../pages/solo/solo_quiz_page.dart';
import '../pages/group/group_mode_page.dart';
import '../pages/online/online_mode_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/auth/auth_login_page.dart';
import '../pages/auth/auth_register_page.dart';
import '../pages/leaderboard/leaderboard_page.dart';

// Modèles pour la navigation
class SoloQuizParams {
  final List<String> categories;
  final int questions;
  final bool shuffle;

  SoloQuizParams({
    required this.categories,
    required this.questions,
    required this.shuffle,
  });

  Map<String, dynamic> toJson() => {
    'categories': categories.join(','),
    'questions': questions.toString(),
    'shuffle': shuffle.toString(),
  };

  factory SoloQuizParams.fromJson(Map<String, String> params) {
    return SoloQuizParams(
      categories: params['categories']?.split(',') ?? ['general'],
      questions: int.tryParse(params['questions'] ?? '10') ?? 10,
      shuffle: params['shuffle'] == 'true',
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
          shuffle: params.shuffle,
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
      builder: (context, state) => const AuthLoginPage(),
    ),

    // Inscription
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const AuthRegisterPage(),
    ),

    // Classement
    GoRoute(
      path: '/leaderboard',
      name: 'leaderboard',
      builder: (context, state) => const LeaderboardPage(),
    ),
  ],

  observers: [ RouteHistory.instance ],

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
    required bool shuffle,
  }) {
    final params = SoloQuizParams(
      categories: categories,
      questions: questions,
      shuffle: shuffle,
    );
    go('/solo-quiz?${_buildQueryString(params.toJson())}');
  }

  // Navigation avec retour
  void goBack() {
    if (canPop()) {
      pop();
    } else {
      goHome();
    }
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
