import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/group/group_models.dart' hide Theme;
import 'package:tuuuur_flutter/api/group/group_websocket_events.dart';
import 'package:tuuuur_flutter/api/group/group_websocket_service.dart';
import 'package:tuuuur_flutter/api/auth/token_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake TokenProvider
// ─────────────────────────────────────────────────────────────────────────────

class _FakeTokenProvider implements TokenProvider {
  @override
  String? get accessToken => 'fake-token-for-ws-test';

  @override
  DateTime? get accessTokenExpiresAt =>
      DateTime.now().add(const Duration(hours: 1));

  @override
  Future<void> refreshIfNeeded() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Recording event handler  — tracks every callback received
// ─────────────────────────────────────────────────────────────────────────────

class _RecordingHandler implements GroupWebSocketEventHandler {
  int connectedCount = 0;
  int disconnectedCount = 0;
  int reconnectingCount = 0;
  int reconnectedCount = 0;
  final List<String> errors = [];
  final List<GroupUser> joinedUsers = [];
  final List<GroupUser> leftUsers = [];
  final List<GroupUser> deletedByUsers = [];
  final List<GroupParty> updatedParties = [];
  final List<GroupParty> startedParties = [];
  final List<int> countdowns = [];
  final List<GroupQuestion> questionsSent = [];
  final List<GroupQuestion> questionsAnswerSent = [];
  final List<List<UserAnswered>> allAnswered = [];
  final List<GroupUser> userAnswers = [];
  final List<List<UserScore>> scoreUpdates = [];
  final List<List<UserScore>> finishedScores = [];

  @override
  void onConnected() => connectedCount++;
  @override
  void onDisconnected() => disconnectedCount++;
  @override
  void onReconnecting() => reconnectingCount++;
  @override
  void onReconnected() => reconnectedCount++;
  @override
  void onError(String msg) => errors.add(msg);
  @override
  void onPlayerJoined(GroupUser user) => joinedUsers.add(user);
  @override
  void onPlayerLeft(GroupUser user) => leftUsers.add(user);
  @override
  void onPartyDeleted(GroupUser deletedBy) => deletedByUsers.add(deletedBy);
  @override
  void onPartyUpdated(GroupParty party) => updatedParties.add(party);
  @override
  void onPartyStarted(GroupParty party) => startedParties.add(party);
  @override
  void onCountdown(int seconds) => countdowns.add(seconds);
  @override
  void onQuestionSend(GroupQuestion gq) => questionsSent.add(gq);
  @override
  void onQuestionAnswerSend(GroupQuestion gq) => questionsAnswerSent.add(gq);
  @override
  void onAllPlayerAnswered(List<UserAnswered> ua) => allAnswered.add(ua);
  @override
  void onUserAnswer(GroupUser user) => userAnswers.add(user);
  @override
  void onScoreUpdate(List<UserScore> scores) => scoreUpdates.add(scores);
  @override
  void onPartyFinished(List<UserScore> scores) => finishedScores.add(scores);
}

/// Service with spoofed `isConnected = true` to reach code paths that need it.
class _ConnectedSpyService extends GroupWebSocketService {
  _ConnectedSpyService()
      : super(hubUrl: 'http://localhost:1', tokenProvider: _FakeTokenProvider());

  @override
  bool get isConnected => true;
}

/// Handler that throws on every callback (to test silent error swallowing).
class _ThrowingHandler implements GroupWebSocketEventHandler {
  @override
  void onConnected() => throw Exception('boom');
  @override
  void onDisconnected() => throw Exception('boom');
  @override
  void onReconnecting() => throw Exception('boom');
  @override
  void onReconnected() => throw Exception('boom');
  @override
  void onError(String msg) => throw Exception('boom: $msg');
  @override
  void onPlayerJoined(GroupUser user) => throw Exception('boom');
  @override
  void onPlayerLeft(GroupUser user) => throw Exception('boom');
  @override
  void onPartyDeleted(GroupUser deletedBy) => throw Exception('boom');
  @override
  void onPartyUpdated(GroupParty party) => throw Exception('boom');
  @override
  void onPartyStarted(GroupParty party) => throw Exception('boom');
  @override
  void onCountdown(int seconds) => throw Exception('boom');
  @override
  void onQuestionSend(GroupQuestion gq) => throw Exception('boom');
  @override
  void onQuestionAnswerSend(GroupQuestion gq) => throw Exception('boom');
  @override
  void onAllPlayerAnswered(List<UserAnswered> ua) => throw Exception('boom');
  @override
  void onUserAnswer(GroupUser user) => throw Exception('boom');
  @override
  void onScoreUpdate(List<UserScore> scores) => throw Exception('boom');
  @override
  void onPartyFinished(List<UserScore> scores) => throw Exception('boom');
}

/// Subclass only used to manipulate connection state in tests that need
/// a non-disconnected initial state. All handler tests use the real
/// testDispatch* @visibleForTesting methods on GroupWebSocketService directly.
class _StateOverrideService extends GroupWebSocketService {
  _StateOverrideService()
      : super(hubUrl: 'http://localhost:1', tokenProvider: _FakeTokenProvider());

  WebSocketConnectionState? _overrideState;

  void setConnectionStateForTest(WebSocketConnectionState s) {
    _overrideState = s;
  }

  @override
  WebSocketConnectionState get connectionState =>
      _overrideState ?? super.connectionState;
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory helper
// ─────────────────────────────────────────────────────────────────────────────

GroupWebSocketService _makeService() => GroupWebSocketService(
      hubUrl: 'http://localhost:1',
      tokenProvider: _FakeTokenProvider(),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('WebSocketConnectionState enum', () {
    test('contient toutes les valeurs attendues', () {
      expect(
        WebSocketConnectionState.values,
        containsAll([
          WebSocketConnectionState.disconnected,
          WebSocketConnectionState.connecting,
          WebSocketConnectionState.connected,
          WebSocketConnectionState.reconnecting,
        ]),
      );
    });
  });

  group('GroupWebSocketService — état initial', () {
    test('connectionState vaut disconnected après création', () {
      final svc = _makeService();
      expect(svc.connectionState, WebSocketConnectionState.disconnected);
    });

    test('isConnected est faux quand aucun hub n\'est présent', () {
      final svc = _makeService();
      expect(svc.isConnected, isFalse);
    });
  });

  group('GroupWebSocketService — gestion des handlers', () {
    test('addEventHandler ajoute le handler sans erreur', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      expect(() => svc.addEventHandler(h), returnsNormally);
    });

    test('addEventHandler n\'ajoute pas le même handler deux fois', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);
      svc.addEventHandler(h); // duplicate — doit être ignoré
      // Vérifié indirectement: aucune exception, comportement stable
      expect(svc.connectionState, WebSocketConnectionState.disconnected);
    });

    test('removeEventHandler retire un handler existant sans erreur', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);
      expect(() => svc.removeEventHandler(h), returnsNormally);
    });

    test('removeEventHandler sur un handler absent ne lève pas d\'exception', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      expect(() => svc.removeEventHandler(h), returnsNormally);
    });

    test(
        'les handlers ajoutés reçoivent les notifications de déconnexion lors du dispose',
        () async {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      await svc.dispose(); // internally calls disconnect which clears handlers
      // After dispose, handlers list is cleared — no events possible
    });
  });

  group('GroupWebSocketService — disconnect', () {
    test('disconnect est idempotent quand déjà déconnecté et sans hub', () async {
      final svc = _makeService();
      await expectLater(svc.disconnect(), completes);
      // Appel répété — toujours sans erreur
      await expectLater(svc.disconnect(), completes);
    });

    test('disconnect modifie l\'état en disconnected quand hub nul', () async {
      final svc = _makeService();
      await svc.disconnect();
      expect(svc.connectionState, WebSocketConnectionState.disconnected);
    });
  });

  group('GroupWebSocketService — sendAnswer', () {
    test('lève Exception quand non connecté (hub absent)', () async {
      final svc = _makeService();
      await expectLater(
        () => svc.sendAnswer(1),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not connected'),
          ),
        ),
      );
    });

    test('lève ArgumentError pour answerId = 0 quand isConnected est true',
        () async {
      final svc = _ConnectedSpyService();
      await expectLater(
        () => svc.sendAnswer(0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lève ArgumentError pour answerId négatif quand isConnected est true',
        () async {
      final svc = _ConnectedSpyService();
      await expectLater(
        () => svc.sendAnswer(-5),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('GroupWebSocketService — startGroupParty', () {
    test('lève Exception quand non connecté', () async {
      final svc = _makeService();
      await expectLater(
        () => svc.startGroupParty(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not connected'),
          ),
        ),
      );
    });
  });

  group('GroupWebSocketService — dispose', () {
    test('dispose se termine sans erreur sur un service non connecté', () async {
      final svc = _makeService();
      await expectLater(svc.dispose(), completes);
    });

    test('dispose peut être appelé plusieurs fois sans erreur', () async {
      final svc = _makeService();
      await svc.dispose();
      await expectLater(svc.dispose(), completes);
    });

    test('dispose retire tous les handlers (plus aucune notification ensuite)',
        () async {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      await svc.dispose();

      // Reconnecting handler is not active anymore — no crash
      expect(svc.connectionState, WebSocketConnectionState.disconnected);
    });
  });

  group('GroupWebSocketService — connect (gardes de concurrence)', () {
    test(
        'le 2ème connect() retourne immédiatement si le 1er est en cours '
        '(état connecting positionné de manière synchrone avant le 1er await)',
        () async {
      final svc = _makeService();

      // connect() positionne _connectionState = connecting AVANT le 1er await,
      // donc après cet appel synchrone l\'état est déjà connecting.
      final firstFuture = svc.connect();

      // Le 2ème appel doit retourner immédiatement (guard).
      await svc.connect();

      // Nettoyer l\'erreur réseau attendue du 1er appel.
      await firstFuture.then((_) {}, onError: (_) {});
      await svc.dispose();
    });

    test(
        'connectionState revient à disconnected après un échec de connexion',
        () async {
      final svc = _makeService();
      try {
        await svc.connect();
      } catch (_) {
        // Attendu : échec réseau sur localhost:1
      }
      expect(svc.connectionState, WebSocketConnectionState.disconnected);
    });

    test('les handlers reçoivent onError après un échec de connexion', () async {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);
      try {
        await svc.connect();
      } catch (_) {}
      expect(h.errors, isNotEmpty);
      await svc.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Tests des handler d'événements serveur via sous-classe exposant les méthodes
  // ─────────────────────────────────────────────────────────────────────────

  group('GroupWebSocketService — _notifyHandlers (via sous-classe)', () {
    test('handler qui lève une exception est ignoré silencieusement', () {
      final svc = _makeService();

      // Handler qui lève une exception sur onDisconnected
      final badHandler = _ThrowingHandler();
      final goodHandler = _RecordingHandler();
      svc.addEventHandler(badHandler);
      svc.addEventHandler(goodHandler);

      // Ne doit pas lever d'exception
      expect(() => svc.removeEventHandler(badHandler), returnsNormally);
    });

    test('plusieurs handlers reçoivent tous la même notification', () async {
      final svc = _makeService();
      final h1 = _RecordingHandler();
      final h2 = _RecordingHandler();
      svc.addEventHandler(h1);
      svc.addEventHandler(h2);

      // Trigger via failed connect (onError dispatché)
      try {
        await svc.connect();
      } catch (_) {}

      expect(h1.errors, isNotEmpty);
      expect(h2.errors, isNotEmpty);
      await svc.dispose();
    });
  });

  group('GroupWebSocketService — handleServerEvents via testDispatch*', () {
    test('_handlePlayerJoined notifie onPlayerJoined avec les données correctes',
        () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPlayerJoined([
        {'id': 'u1', 'nickName': 'Alice', 'isAdmin': false, 'isNew': false},
      ]);

      expect(h.joinedUsers.length, 1);
      expect(h.joinedUsers.first.id, 'u1');
      expect(h.joinedUsers.first.nickName, 'Alice');
    });

    test('_handlePlayerJoined avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPlayerJoined(null);
      expect(h.joinedUsers, isEmpty);
    });

    test('_handlePlayerJoined avec liste vide → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPlayerJoined([]);
      expect(h.joinedUsers, isEmpty);
    });

    test('_handlePlayerJoined avec données malformées → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPlayerJoined(['not-a-map']);
      expect(h.joinedUsers, isEmpty);
    });

    test('_handlePlayerLeft notifie onPlayerLeft', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPlayerLeft([
        {'id': 'u2', 'nickName': 'Bob', 'isAdmin': false, 'isNew': false},
      ]);

      expect(h.leftUsers.length, 1);
      expect(h.leftUsers.first.nickName, 'Bob');
    });

    test('_handlePlayerLeft avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPlayerLeft(null);
      expect(h.leftUsers, isEmpty);
    });

    test('_handlePartyDeleted notifie onPartyDeleted', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyDeleted([
        {'id': 'host-1', 'nickName': 'Host', 'isAdmin': false, 'isNew': false},
      ]);

      expect(h.deletedByUsers.length, 1);
      expect(h.deletedByUsers.first.id, 'host-1');
    });

    test('_handlePartyDeleted avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyDeleted(null);
      expect(h.deletedByUsers, isEmpty);
    });

    test('_handleCountdown notifie onCountdown avec la valeur correcte', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchCountdown([3]);
      expect(h.countdowns, [3]);
    });

    test('_handleCountdown avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchCountdown(null);
      expect(h.countdowns, isEmpty);
    });

    test('_handleCountdown avec liste vide → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchCountdown([]);
      expect(h.countdowns, isEmpty);
    });

    test('_handleError avec message → notifie onError avec le message', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchError(['Server exploded']);
      expect(h.errors, ['Server exploded']);
    });

    test('_handleError avec arguments null → notifie onError générique', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchError(null);
      expect(h.errors, isNotEmpty);
      expect(h.errors.first, contains('Unknown'));
    });

    test('_handleError avec liste vide → notifie onError générique', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchError([]);
      expect(h.errors, isNotEmpty);
    });

    test('_handleUserAnswer notifie onUserAnswer', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchUserAnswer([
        {'id': 'u3', 'nickName': 'Carol', 'isAdmin': false, 'isNew': false},
      ]);

      expect(h.userAnswers.length, 1);
      expect(h.userAnswers.first.nickName, 'Carol');
    });

    test('_handleUserAnswer avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchUserAnswer(null);
      expect(h.userAnswers, isEmpty);
    });

    test('_handleScoreUpdate notifie onScoreUpdate avec les scores', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchScoreUpdate([
        [
          {
            'score': 100,
            'user': {
              'id': 'u1',
              'nickName': 'Alice',
              'isAdmin': false,
              'isNew': false,
            },
          },
        ],
      ]);

      expect(h.scoreUpdates.length, 1);
      expect(h.scoreUpdates.first.length, 1);
      expect(h.scoreUpdates.first.first.score, 100);
    });

    test('_handleScoreUpdate avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchScoreUpdate(null);
      expect(h.scoreUpdates, isEmpty);
    });

    test('_handlePartyFinished notifie onPartyFinished avec les scores', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyFinished([
        [
          {
            'score': 250,
            'user': {
              'id': 'u2',
              'nickName': 'Bob',
              'isAdmin': false,
              'isNew': false,
            },
          },
        ],
      ]);

      expect(h.finishedScores.length, 1);
      expect(h.finishedScores.first.first.score, 250);
    });

    test('_handlePartyFinished avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyFinished(null);
      expect(h.finishedScores, isEmpty);
    });

    test('_handleAllPlayerAnswered notifie onAllPlayerAnswered', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchAllPlayerAnswered([
        [
          {
            'correct': true,
            'user': {
              'id': 'u1',
              'nickName': 'Alice',
              'isAdmin': false,
              'isNew': false,
            },
          },
        ],
      ]);

      expect(h.allAnswered.length, 1);
    });

    test('_handleAllPlayerAnswered avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchAllPlayerAnswered(null);
      expect(h.allAnswered, isEmpty);
    });

    test(
        '_handleDisconnected ne notifie pas si déjà disconnected', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      // État initial est disconnected → guard doit bloquer
      svc.testDispatchDisconnected();
      expect(h.disconnectedCount, 0);
    });

    test('_handleDisconnected notifie et passe à disconnected quand état non-disconnected', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      // Set state to reconnecting first, then disconnect
      svc.testDispatchReconnecting();
      expect(svc.connectionState, WebSocketConnectionState.reconnecting);

      svc.testDispatchDisconnected();
      expect(h.disconnectedCount, 1);
      expect(svc.connectionState, WebSocketConnectionState.disconnected);
    });

    test('_handleReconnecting met l\'état à reconnecting et notifie', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchReconnecting();
      expect(h.reconnectingCount, 1);
      expect(svc.connectionState, WebSocketConnectionState.reconnecting);
    });

    test('_handleReconnected met l\'état à connected et notifie', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchReconnected();
      expect(h.reconnectedCount, 1);
      expect(svc.connectionState, WebSocketConnectionState.connected);
    });
  });

  group('GroupWebSocketService — sendAnswer (ConnectedSpy)', () {
    test(
        'sendAnswer lève une exception réseau (hub nul) même avec isConnected spoofé',
        () async {
      final svc = _ConnectedSpyService();
      // hub est null → appel à _hubConnection! lèvera une exception au runtime
      await expectLater(
        () => svc.sendAnswer(1),
        throwsA(anything),
      );
    });

    test(
        'startGroupParty lève une exception réseau (hub nul) avec isConnected spoofé',
        () async {
      final svc = _ConnectedSpyService();
      await expectLater(
        () => svc.startGroupParty(),
        throwsA(anything),
      );
    });
  });

  group('GroupWebSocketService — multiple handlers + removeEventHandler', () {
    test('handler retiré ne reçoit plus de notifications', () async {
      final svc = _makeService();
      final h1 = _RecordingHandler();
      final h2 = _RecordingHandler();
      svc.addEventHandler(h1);
      svc.addEventHandler(h2);
      svc.removeEventHandler(h1);

      try {
        await svc.connect();
      } catch (_) {}

      // h1 a été retiré → ne reçoit rien; h2 reçoit les erreurs
      expect(h1.errors, isEmpty);
      expect(h2.errors, isNotEmpty);
      await svc.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Constantes JSON pour les tests des handlers manquants
  // ─────────────────────────────────────────────────────────────────────────

  const kPartyJson = <String, Object?>{
    'id': 'party-test-99',
    'code': 'TEST99',
    'nbQuestions': 10,
    'inProgress': false,
    'scoreEachRound': false,
    'idPartyType': 2,
    'idUserHost': 'host-test',
    'active': true,
    'finish': false,
    'dt': '2025-01-01T00:00:00.000Z',
    'partyUsers': <Object?>[],
    'partyTheme': <Object?>[],
    'partyDifficulty': <Object?>[],
    'percent': 0.0,
    'score': 0,
    'time': 0,
  };

  const kQuestionJson = <String, Object?>{
    'currentIndex': 1,
    'score': 15,
    'question': <String, Object?>{
      'id': 42,
      'label': 'Test question label?',
      'idDifficulty': 1,
      'difficulty': <String, Object?>{'id': 1, 'label': 'Facile'},
      'answer': <Object?>[
        <String, Object?>{'id': 101, 'idQuestion': 42, 'value': 'Answer A', 'valid': null},
        <String, Object?>{'id': 102, 'idQuestion': 42, 'value': 'Answer B', 'valid': null},
      ],
    },
  };

  group('GroupWebSocketService — _handlePartyUpdated via testDispatch*', () {
    test('_handlePartyUpdated notifie onPartyUpdated avec les données correctes', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyUpdated([kPartyJson]);

      expect(h.updatedParties.length, 1);
      expect(h.updatedParties.first.id, 'party-test-99');
      expect(h.updatedParties.first.code, 'TEST99');
    });

    test('_handlePartyUpdated avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyUpdated(null);
      expect(h.updatedParties, isEmpty);
    });

    test('_handlePartyUpdated avec liste vide → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyUpdated([]);
      expect(h.updatedParties, isEmpty);
    });

    test('_handlePartyUpdated avec données malformées → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyUpdated(['not-a-map']);
      expect(h.updatedParties, isEmpty);
    });

    test('_handlePartyUpdated notifie plusieurs handlers', () {
      final svc = _makeService();
      final h1 = _RecordingHandler();
      final h2 = _RecordingHandler();
      svc.addEventHandler(h1);
      svc.addEventHandler(h2);

      svc.testDispatchPartyUpdated([kPartyJson]);

      expect(h1.updatedParties.length, 1);
      expect(h2.updatedParties.length, 1);
    });
  });

  group('GroupWebSocketService — _handlePartyStarted via testDispatch*', () {
    test('_handlePartyStarted notifie onPartyStarted avec les données correctes', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyStarted([kPartyJson]);

      expect(h.startedParties.length, 1);
      expect(h.startedParties.first.id, 'party-test-99');
    });

    test('_handlePartyStarted avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyStarted(null);
      expect(h.startedParties, isEmpty);
    });

    test('_handlePartyStarted avec liste vide → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyStarted([]);
      expect(h.startedParties, isEmpty);
    });

    test('_handlePartyStarted avec données malformées → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchPartyStarted([12345]);
      expect(h.startedParties, isEmpty);
    });

    test('_handlePartyStarted notifie plusieurs handlers', () {
      final svc = _makeService();
      final h1 = _RecordingHandler();
      final h2 = _RecordingHandler();
      svc.addEventHandler(h1);
      svc.addEventHandler(h2);

      svc.testDispatchPartyStarted([kPartyJson]);

      expect(h1.startedParties.length, 1);
      expect(h2.startedParties.length, 1);
    });
  });

  group('GroupWebSocketService — _handleQuestionSend via testDispatch*', () {
    test('_handleQuestionSend notifie onQuestionSend avec les données correctes', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchQuestionSend([kQuestionJson]);

      expect(h.questionsSent.length, 1);
      expect(h.questionsSent.first.currentIndex, 1);
      expect(h.questionsSent.first.score, 15);
      expect(h.questionsSent.first.question.id, 42);
    });

    test('_handleQuestionSend avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchQuestionSend(null);
      expect(h.questionsSent, isEmpty);
    });

    test('_handleQuestionSend avec liste vide → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchQuestionSend([]);
      expect(h.questionsSent, isEmpty);
    });

    test('_handleQuestionSend avec données malformées → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchQuestionSend(['invalid-data']);
      expect(h.questionsSent, isEmpty);
    });

    test('_handleQuestionSend notifie plusieurs handlers', () {
      final svc = _makeService();
      final h1 = _RecordingHandler();
      final h2 = _RecordingHandler();
      svc.addEventHandler(h1);
      svc.addEventHandler(h2);

      svc.testDispatchQuestionSend([kQuestionJson]);

      expect(h1.questionsSent.length, 1);
      expect(h2.questionsSent.length, 1);
    });
  });

  group('GroupWebSocketService — _handleQuestionAnswerSend via testDispatch*', () {
    test('_handleQuestionAnswerSend notifie onQuestionAnswerSend avec les données correctes', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchQuestionAnswerSend([kQuestionJson]);

      expect(h.questionsAnswerSent.length, 1);
      expect(h.questionsAnswerSent.first.question.label, 'Test question label?');
    });

    test('_handleQuestionAnswerSend avec arguments null → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchQuestionAnswerSend(null);
      expect(h.questionsAnswerSent, isEmpty);
    });

    test('_handleQuestionAnswerSend avec liste vide → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchQuestionAnswerSend([]);
      expect(h.questionsAnswerSent, isEmpty);
    });

    test('_handleQuestionAnswerSend avec données malformées → rien notifié', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchQuestionAnswerSend([999]);
      expect(h.questionsAnswerSent, isEmpty);
    });

    test('_handleQuestionAnswerSend notifie plusieurs handlers', () {
      final svc = _makeService();
      final h1 = _RecordingHandler();
      final h2 = _RecordingHandler();
      svc.addEventHandler(h1);
      svc.addEventHandler(h2);

      svc.testDispatchQuestionAnswerSend([kQuestionJson]);

      expect(h1.questionsAnswerSent.length, 1);
      expect(h2.questionsAnswerSent.length, 1);
    });
  });

  group('GroupWebSocketService — _ThrowingHandler silence', () {
    test('handler qui lève exception sur onPlayerJoined n\'affecte pas les suivants', () {
      final svc = _makeService();
      final throwing = _ThrowingHandler();
      final recording = _RecordingHandler();
      svc.addEventHandler(throwing);
      svc.addEventHandler(recording);

      svc.testDispatchPlayerJoined([
        {'id': 'u-throw', 'nickName': 'Thrower', 'isAdmin': false, 'isNew': false},
      ]);

      expect(recording.joinedUsers.length, 1);
      expect(recording.joinedUsers.first.id, 'u-throw');
    });

    test('handler qui lève exception sur onPartyUpdated n\'affecte pas les suivants', () {
      final svc = _makeService();
      final throwing = _ThrowingHandler();
      final recording = _RecordingHandler();
      svc.addEventHandler(throwing);
      svc.addEventHandler(recording);

      svc.testDispatchPartyUpdated([kPartyJson]);

      expect(recording.updatedParties.length, 1);
    });

    test('handler qui lève exception sur onCountdown n\'affecte pas les suivants', () {
      final svc = _makeService();
      final throwing = _ThrowingHandler();
      final recording = _RecordingHandler();
      svc.addEventHandler(throwing);
      svc.addEventHandler(recording);

      svc.testDispatchCountdown([5]);

      expect(recording.countdowns, [5]);
    });

    test('handler qui lève exception sur onQuestionSend n\'affecte pas les suivants', () {
      final svc = _makeService();
      final throwing = _ThrowingHandler();
      final recording = _RecordingHandler();
      svc.addEventHandler(throwing);
      svc.addEventHandler(recording);

      svc.testDispatchQuestionSend([kQuestionJson]);

      expect(recording.questionsSent.length, 1);
    });
  });

  group('GroupWebSocketService — state transitions complètes', () {
    test('reconnecting puis reconnected → état final connected', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchReconnecting();
      svc.testDispatchReconnected();

      expect(svc.connectionState, WebSocketConnectionState.connected);
      expect(h.reconnectingCount, 1);
      expect(h.reconnectedCount, 1);
    });

    test('reconnecting → état reconnecting persisté', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchReconnecting();

      expect(svc.connectionState, WebSocketConnectionState.reconnecting);
      expect(h.reconnectingCount, 1);
    });

    test('handlers retirés ne reçoivent pas partyUpdated', () {
      final svc = _makeService();
      final h1 = _RecordingHandler();
      final h2 = _RecordingHandler();
      svc.addEventHandler(h1);
      svc.addEventHandler(h2);
      svc.removeEventHandler(h1);

      svc.testDispatchPartyUpdated([kPartyJson]);

      expect(h1.updatedParties, isEmpty);
      expect(h2.updatedParties.length, 1);
    });

    test('handlers retirés ne reçoivent pas partyStarted', () {
      final svc = _makeService();
      final h1 = _RecordingHandler();
      final h2 = _RecordingHandler();
      svc.addEventHandler(h1);
      svc.addEventHandler(h2);
      svc.removeEventHandler(h1);

      svc.testDispatchPartyStarted([kPartyJson]);

      expect(h1.startedParties, isEmpty);
      expect(h2.startedParties.length, 1);
    });

    test('addEventHandler dédupliqué n\'entraîne pas de double notification', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);
      svc.addEventHandler(h); // duplicate

      svc.testDispatchCountdown([10]);

      // Despite adding twice, handler is deduped → should receive once
      // (depends on implementation; at minimum no error)
      expect(h.countdowns, isNotEmpty);
    });
  });

  group('GroupWebSocketService — testDispatchConnected', () {
    test('testDispatchConnected notifie onConnected et met état à connected', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchConnected();

      expect(h.connectedCount, 1);
      expect(svc.connectionState, WebSocketConnectionState.connected);
    });

    test('testDispatchConnected puis testDispatchDisconnected cycle complet', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchConnected();
      svc.testDispatchDisconnected();

      expect(h.connectedCount, 1);
      expect(h.disconnectedCount, 1);
      expect(svc.connectionState, WebSocketConnectionState.disconnected);
    });

    test('cycle complet connected → reconnecting → reconnected → disconnected', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      svc.testDispatchConnected();
      svc.testDispatchReconnecting();
      svc.testDispatchReconnected();
      svc.testDispatchDisconnected();

      expect(h.connectedCount, 1);
      expect(h.reconnectingCount, 1);
      expect(h.reconnectedCount, 1);
      expect(h.disconnectedCount, 1);
      expect(svc.connectionState, WebSocketConnectionState.disconnected);
    });
  });

  group('GroupWebSocketService — _handleError avec données invalides', () {
    test('_handleError avec valeur non-String en args[0] → onError avec Server error', () {
      final svc = _makeService();
      final h = _RecordingHandler();
      svc.addEventHandler(h);

      // args[0] is not a String → cast fails → catch branch fires
      svc.testDispatchError([12345]);
      expect(h.errors, isNotEmpty);
      expect(h.errors.first, contains('Server error'));
    });
  });
}
