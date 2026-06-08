import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_module.dart';
import '../../stores/ranked_coordinator.dart';
import '../../stores/ranked_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/navigation_header.dart';
import '../../navigation/app_router.dart';

import 'ranked_join_view.dart';
import 'ranked_matchmaking_view.dart';
import 'ranked_duel_intro_view.dart';
import 'ranked_quiz_view.dart';
import 'ranked_results_view.dart';

class RankedMainPage extends StatefulWidget {
  const RankedMainPage({super.key});

  @override
  State<RankedMainPage> createState() => _RankedMainPageState();
}

class _RankedMainPageState extends State<RankedMainPage> {
  late final RankedCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = ApiModule.instance.rankedCoordinator;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _coordinator.store,
      child: const RankedMainContent(),
    );
  }
}

class RankedMainContent extends StatelessWidget {
  const RankedMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RankedStore>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        await ApiModule.instance.killRanked();

        if (context.mounted) {
          context.goHome();
        }
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: const NavigationHeader(),
        body: SafeArea(child: _buildContent(context, store)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RankedStore store) {
    final state = store.state;

    if (state == RankedGameState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Erreur :\n${store.errorMessage ?? "Inconnue"}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => store.clearError(), // Back to idle
              child: const Text('Retour'),
            ),
          ],
        ),
      );
    }

    switch (state) {
      case RankedGameState.idle:
        return const RankedJoinView();
      case RankedGameState.searching:
        return const RankedMatchmakingView();
      case RankedGameState.matchFound:
        return const RankedDuelIntroView();
      case RankedGameState.countdown:
      case RankedGameState.questionActive:
      case RankedGameState.answerReveal:
      case RankedGameState.scoreDisplay:
        return const RankedQuizView();
      case RankedGameState.finished:
        return const RankedResultsView();
      default:
        return const SizedBox.shrink();
    }
  }
}
