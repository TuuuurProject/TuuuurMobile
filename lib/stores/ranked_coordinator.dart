import 'dart:developer' as dev;
import '../api/ranked/ranked_websocket_service.dart';
import '../api/auth/token_provider.dart';
import 'ranked_store.dart';

/// Coordonnateur pour le système de Ranked
/// Gère la connexion WebSocket et expose le Store
class RankedCoordinator {
  final RankedWebSocketService _webSocketService;
  final RankedStore _store;

  RankedCoordinator({
    required RankedWebSocketService webSocketService,
    required RankedStore store,
  }) : _webSocketService = webSocketService,
       _store = store;

  /// Factory pour créer un RankedCoordinator complet
  factory RankedCoordinator.create({
    required TokenProvider tokenProvider,
    required String webSocketHubUrl,
  }) {
    final webSocketService = RankedWebSocketService(
      hubUrl: webSocketHubUrl,
      tokenProvider: tokenProvider,
    );
    final store = RankedStore(webSocketService: webSocketService);

    return RankedCoordinator(webSocketService: webSocketService, store: store);
  }

  /// Accès au store pour l'UI
  RankedStore get store => _store;

  /// Vérifie si le WebSocket est connecté
  bool get isConnected => _webSocketService.isConnected;

  // ==================== Actions de matchmaking et jeu ====================

  Future<void> disconnect() async {
    await _store.disconnect();
  }

  /// Rejoint la file d'attente
  Future<void> joinQueue() async {
    try {
      dev.log('Rejoindre la file d\'attente...', name: 'RankedCoordinator');
      await _store.joinQueue();
    } catch (e) {
      dev.log('Erreur joinQueue: $e', name: 'RankedCoordinator');
    }
  }

  /// Quitte la file d'attente
  Future<void> leaveQueue() async {
    try {
      dev.log('Quitter la file d\'attente...', name: 'RankedCoordinator');
      await _store.leaveQueue();
    } catch (e) {
      dev.log('Erreur leaveQueue: $e', name: 'RankedCoordinator');
    }
  }

  /// Sélectionne une réponse localement
  void selectAnswer(int answerId) {
    _store.selectAnswer(answerId);
  }

  /// Envoie la réponse sélectionnée au serveur
  Future<void> submitAnswer() async {
    await _store.submitAnswer();
  }

  // ==================== Nettoyage ====================

  /// Libère toutes les ressources
  Future<void> hardDispose() async {
    await _webSocketService.disconnect();
    _store.dispose();
  }
}
