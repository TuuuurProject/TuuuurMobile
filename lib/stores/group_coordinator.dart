import 'dart:developer' as dev;
import '../api/api_client.dart';
import '../api/group/group_rest_api_service.dart';
import '../api/group/group_websocket_service.dart';
import '../api/auth/token_provider.dart';
import 'group_store.dart';

/// Coordonnateur pour le système de groupe
/// Gère l'intégration entre l'API REST, le WebSocket et le Store
/// 
/// Ce service simplifie l'utilisation du système de groupe en:
/// - Coordonnant les appels API REST et WebSocket
/// - Gérant la connexion/déconnexion automatique du WebSocket
/// - Synchronisant l'état entre l'API et le Store
class GroupCoordinator {
  final GroupRestApiService _restApi;
  final GroupWebSocketService _webSocketService;
  final GroupStore _store;
  bool _isLeaving = false;

  GroupCoordinator({
    required GroupRestApiService restApi,
    required GroupWebSocketService webSocketService,
    required GroupStore store,
  })  : _restApi = restApi,
        _webSocketService = webSocketService,
        _store = store;

  /// Factory pour créer un GroupCoordinator complet
  factory GroupCoordinator.create({
    required ApiClient apiClient,
    required TokenProvider tokenProvider,
    required String webSocketHubUrl,
  }) {
    final restApi = GroupRestApiService(apiClient: apiClient);
    final webSocketService = GroupWebSocketService(
      hubUrl: webSocketHubUrl,
      tokenProvider: tokenProvider,
    );
    final store = GroupStore(webSocketService: webSocketService);

    return GroupCoordinator(
      restApi: restApi,
      webSocketService: webSocketService,
      store: store,
    );
  }

  /// Accès au store pour les widgets
  GroupStore get store => _store;

  /// Vérifie si le WebSocket est connecté
  bool get isConnected => _webSocketService.isConnected;

  // ==================== Flux complet de création de partie ====================

  /// Crée une nouvelle partie et se connecte au WebSocket
  /// 
  /// 1. Appelle l'API REST pour créer la partie
  /// 2. Initialise le store avec la partie créée
  /// 3. Connecte au WebSocket
  /// 
  /// Retourne le code de la partie en cas de succès
  Future<String?> createAndJoinParty({int? currentUserId}) async {
    try {
      dev.log('Création de la partie...', name: 'GroupCoordinator');

      // 1. Créer la partie via l'API REST
      final response = await _restApi.createGroup();
      if (!response.ok || response.data == null) {
        dev.log('Erreur création: ${response.message}', name: 'GroupCoordinator');
        _store.onError(response.message ?? 'Erreur lors de la création de la partie');
        return null;
      }

      final party = response.data!;
      dev.log('Partie créée: ${party.code}', name: 'GroupCoordinator');

      // 2. Initialiser le store
      _store.initializeParty(party, currentUserId: currentUserId);

      // 3. Connecter le WebSocket
      await _webSocketService.connect();

      return party.code;
    } catch (e) {
      dev.log('Erreur createAndJoinParty: $e', name: 'GroupCoordinator');
      _store.onError('Erreur: $e');
      return null;
    }
  }

  /// Rejoint une partie existante avec un code et se connecte au WebSocket
  /// 
  /// 1. Appelle l'API REST pour rejoindre la partie
  /// 2. Initialise le store avec la partie rejointe
  /// 3. Connecte au WebSocket
  /// 
  /// Retourne true en cas de succès
  Future<bool> joinParty(String code, {int? currentUserId}) async {
    try {
      dev.log('Rejoindre la partie: $code', name: 'GroupCoordinator');

      // 1. Rejoindre via l'API REST
      final response = await _restApi.joinGroup(code: code);
      if (!response.ok || response.data == null) {
        dev.log('Erreur join: ${response.message}', name: 'GroupCoordinator');
        _store.onError(response.message ?? 'Code de partie invalide');
        return false;
      }

      final party = response.data!;
      dev.log('Partie rejointe: ${party.code}', name: 'GroupCoordinator');

      // 2. Initialiser le store
      _store.initializeParty(party, currentUserId: currentUserId);

      // 3. Connecter le WebSocket
      await _webSocketService.connect();

      return true;
    } catch (e) {
      dev.log('Erreur joinParty: $e', name: 'GroupCoordinator');
      _store.onError('Erreur: $e');
      return false;
    }
  }

  /// Quitte la partie actuelle et se déconnecte du WebSocket
  Future<void> leaveParty() async {
    // Éviter les appels multiples
    if (_isLeaving) {
      dev.log('leaveParty() déjà en cours, appel ignoré', name: 'GroupCoordinator');
      return;
    }

    try {
      _isLeaving = true;
      dev.log('Quitter la partie', name: 'GroupCoordinator');

      // 1. Déconnecter le WebSocket proprement (await pour s'assurer que c'est fini)
      try {
        await _webSocketService.disconnect();
      } catch (e) {
        dev.log('Erreur déconnexion WebSocket (ignorée): $e', name: 'GroupCoordinator');
      }

      // 2. Quitter via l'API REST
      await _restApi.leaveGroup();

      // 3. Réinitialiser le store
      _store.reset();
    } catch (e) {
      dev.log('Erreur leaveParty: $e', name: 'GroupCoordinator');
    } finally {
      _isLeaving = false;
    }
  }

  // ==================== Gestion des paramètres ====================

  /// Met à jour les paramètres de la partie (hôte uniquement)
  /// Les changements seront notifiés via WebSocket (OnPartyUpdated)
  Future<bool> updatePartySettings({
    required List<int> themes,
    required List<int> difficulties,
    required int nbQuestions,
    required bool scoreEachRound,
  }) async {
    try {
      dev.log('Mise à jour des paramètres', name: 'GroupCoordinator');

      final response = await _restApi.updateSettings(
        themes: themes,
        difficulties: difficulties,
        nbQuestions: nbQuestions,
        scoreEachRound: scoreEachRound,
      );

      if (!response.ok) {
        dev.log('Erreur updateSettings: ${response.message}', name: 'GroupCoordinator');
        _store.onError(response.message ?? 'Erreur lors de la mise à jour');
        return false;
      }

      // Le WebSocket notifiera OnPartyUpdated avec les nouvelles valeurs
      return true;
    } catch (e) {
      dev.log('Erreur updatePartySettings: $e', name: 'GroupCoordinator');
      _store.onError('Erreur: $e');
      return false;
    }
  }

  // ==================== Actions de jeu ====================

  /// Démarre la partie (hôte uniquement)
  /// Délègue au store qui appelle le WebSocket
  Future<void> startParty() async {
    await _store.startParty();
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
  void dispose() {
    _webSocketService.disconnect();
    _store.dispose();
  }
}
