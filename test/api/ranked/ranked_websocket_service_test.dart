import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/api/auth/token_provider.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_models.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_websocket_events.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_websocket_service.dart';

class _FakeTokenProvider implements TokenProvider {
  @override
  String? get accessToken => 'fake-access-token';

  @override
  DateTime? get accessTokenExpiresAt => DateTime.now().add(const Duration(hours: 1));

  @override
  Future<void> refreshIfNeeded() async {}
}

class _RecordingHandler implements RankedWebSocketEventHandler {
  int connectionErrorCount = 0;
  int opponentFoundCount = 0;
  int countdownCount = 0;
  int questionSendCount = 0;
  int questionAnswerSendCount = 0;
  int userAnswerCount = 0;
  int allPlayerAnsweredCount = 0;
  int scoreUpdateCount = 0;
  int partyFinishedCount = 0;
  int userWinCount = 0;
  int userLooseCount = 0;
  int errorCount = 0;

  @override
  void onConnectionError(String error) => connectionErrorCount++;

  @override
  void onOpponentFound(RankedUser opponent) => opponentFoundCount++;

  @override
  void onCountdown(int seconds) => countdownCount++;

  @override
  void onQuestionSend(RankedQuestion question) => questionSendCount++;

  @override
  void onQuestionAnswerSend(RankedQuestion question) => questionAnswerSendCount++;

  @override
  void onUserAnswer(RankedUser opponent) => userAnswerCount++;

  @override
  void onAllPlayerAnswered(List<RankedUserAnswered> userAnswers) => allPlayerAnsweredCount++;

  @override
  void onScoreUpdate(List<RankedUserScore> userScores) => scoreUpdateCount++;

  @override
  void onPartyFinished(List<RankedUserScore> userScores) => partyFinishedCount++;

  @override
  void onUserWin(int delta) => userWinCount++;

  @override
  void onUserLoose(int delta) => userLooseCount++;

  @override
  void onError(String errorMessage) => errorCount++;
}

/// Handler qui lève à chaque callback — pour tester l'isolation des erreurs.
class _ThrowingHandler implements RankedWebSocketEventHandler {
  @override
  void onConnectionError(String error) => throw Exception('boom');
  @override
  void onOpponentFound(RankedUser opponent) => throw Exception('boom');
  @override
  void onCountdown(int seconds) => throw Exception('boom');
  @override
  void onQuestionSend(RankedQuestion question) => throw Exception('boom');
  @override
  void onQuestionAnswerSend(RankedQuestion question) => throw Exception('boom');
  @override
  void onUserAnswer(RankedUser opponent) => throw Exception('boom');
  @override
  void onAllPlayerAnswered(List<RankedUserAnswered> userAnswers) =>
      throw Exception('boom');
  @override
  void onScoreUpdate(List<RankedUserScore> userScores) =>
      throw Exception('boom');
  @override
  void onPartyFinished(List<RankedUserScore> userScores) =>
      throw Exception('boom');
  @override
  void onUserWin(int delta) => throw Exception('boom');
  @override
  void onUserLoose(int delta) => throw Exception('boom');
  @override
  void onError(String errorMessage) => throw Exception('boom');
}

void main() {
  group('RankedWebSocketService', () {
    late _FakeTokenProvider fakeTokenProvider;
    late RankedWebSocketService service;
    late _RecordingHandler handler;

    setUp(() {
      fakeTokenProvider = _FakeTokenProvider();
      service = RankedWebSocketService(
        hubUrl: 'http://localhost/ranked-hub',
        tokenProvider: fakeTokenProvider,
      );
      handler = _RecordingHandler();
    });

    test('Initial State is disconnected', () {
      expect(service.connectionState, RankedConnectionState.disconnected);
      expect(service.isConnected, isFalse);
    });

    test('addEventHandler / removeEventHandler', () {
      service.addEventHandler(handler);
      service.removeEventHandler(handler);
      // Mostly ensuring no crashes.
    });

    test('connect and disconnect updates internal state correctly', () async {
      // Sans serveur SignalR réel, connect() finit par échouer (connexion
      // refusée). On attache le gestionnaire d'erreur IMMÉDIATEMENT (via
      // catchError) pour ne pas laisser le future échouer sans listener
      // pendant le disconnect ci-dessous — sinon, en CI où le refus est
      // instantané, Dart le signale comme "unhandled async error" et fait
      // planter le test. On ne teste ici que les transitions d'état.
      expect(service.connectionState, RankedConnectionState.disconnected);

      final connectFuture = service.connect().catchError((_) {});
      expect(service.connectionState, RankedConnectionState.connecting);

      await service.disconnect();
      expect(service.connectionState, RankedConnectionState.disconnected);

      await connectFuture;
    });

    test('joinSearchOpponent throws if not connected', () async {
      expect(
        () async => await service.joinSearchOpponent(),
        throwsA(isA<Exception>()),
      );
    });

    test('leaveSearchOpponent does not throw if disconnected', () async {
      await service.leaveSearchOpponent(); // Should return immediately
    });

    test('sendAnswer throws if not connected', () async {
      expect(
        () async => await service.sendAnswer(1),
        throwsA(isA<Exception>()),
      );
    });

    // ───────────────────────── Évènements serveur ─────────────────────────
    group('handlers serveur (testDispatch*)', () {
      setUp(() {
        service.testSetConnectionState(RankedConnectionState.connected);
        service.addEventHandler(handler);
      });

      test('OnOpponentFound notifie onOpponentFound', () {
        service.testDispatchOpponentFound([
          {'id': 'u1', 'nickName': 'Bob', 'globalElo': 1200},
        ]);
        expect(handler.opponentFoundCount, 1);
      });

      test('OnOpponentFound accepte une Map non typée', () {
        service.testDispatchOpponentFound([
          <dynamic, dynamic>{'id': 'u1', 'nickName': 'Bob', 'globalElo': 1200},
        ]);
        expect(handler.opponentFoundCount, 1);
      });

      test('OnCountdown notifie onCountdown', () {
        service.testDispatchCountdown([5]);
        expect(handler.countdownCount, 1);
      });

      test('OnQuestionSend notifie onQuestionSend', () {
        service.testDispatchQuestionSend([
          {
            'question': {
              'id': 1,
              'label': 'Q',
              'idDifficulty': 2,
              'answer': [
                {'id': 1, 'value': 'A', 'valid': true},
              ],
            },
            'currentIndex': 0,
            'score': 10,
            'multiplier': 1.0,
          },
        ]);
        expect(handler.questionSendCount, 1);
      });

      test('OnQuestionAnswerSend notifie onQuestionAnswerSend', () {
        service.testDispatchQuestionAnswerSend([
          {
            'question': {
              'id': 1,
              'label': 'Q',
              'idDifficulty': 2,
              'answer': <dynamic>[],
            },
            'currentIndex': 0,
            'score': 10,
            'multiplier': 1.0,
          },
        ]);
        expect(handler.questionAnswerSendCount, 1);
      });

      test('OnUserAnswer notifie onUserAnswer', () {
        service.testDispatchUserAnswer([
          {'id': 'u2', 'nickName': 'Carol', 'globalElo': 1000},
        ]);
        expect(handler.userAnswerCount, 1);
      });

      test('OnAllPlayerAnswered notifie onAllPlayerAnswered', () {
        service.testDispatchAllPlayerAnswered([
          [
            {
              'correct': true,
              'user': {'id': 'u1', 'nickName': 'A', 'globalElo': 1500},
            },
          ],
        ]);
        expect(handler.allPlayerAnsweredCount, 1);
      });

      test('OnScoreUpdate notifie onScoreUpdate', () {
        service.testDispatchScoreUpdate([
          [
            {
              'score': 10,
              'user': {'id': 'u1', 'nickName': 'A', 'globalElo': 1500},
            },
          ],
        ]);
        expect(handler.scoreUpdateCount, 1);
      });

      test('OnPartyFinished notifie onPartyFinished', () {
        service.testDispatchPartyFinished([
          [
            {
              'score': 20,
              'user': {'id': 'u1', 'nickName': 'A', 'globalElo': 1500},
            },
          ],
        ]);
        expect(handler.partyFinishedCount, 1);
      });

      test('OnUserWin notifie onUserWin', () {
        service.testDispatchUserWin([25]);
        expect(handler.userWinCount, 1);
      });

      test('OnUserLoose notifie onUserLoose', () {
        service.testDispatchUserLoose([10]);
        expect(handler.userLooseCount, 1);
      });

      test('OnError notifie onError', () {
        service.testDispatchError(['Erreur serveur']);
        expect(handler.errorCount, 1);
      });

      test('args null ou vides → aucun handler notifié', () {
        service.testDispatchCountdown(null);
        service.testDispatchCountdown([]);
        service.testDispatchOpponentFound(null);
        service.testDispatchScoreUpdate([]);
        service.testDispatchError([]);

        expect(handler.countdownCount, 0);
        expect(handler.opponentFoundCount, 0);
        expect(handler.scoreUpdateCount, 0);
        expect(handler.errorCount, 0);
      });

      test('payloads malformés → erreurs de parsing ignorées', () {
        service.testDispatchOpponentFound(['pas une map']);
        service.testDispatchCountdown(['pas un nombre']);
        service.testDispatchQuestionSend(['x']);
        service.testDispatchQuestionAnswerSend(['x']);
        service.testDispatchUserAnswer(['x']);
        service.testDispatchAllPlayerAnswered(['x']);
        service.testDispatchScoreUpdate(['x']);
        service.testDispatchPartyFinished(['x']);
        service.testDispatchUserWin(['x']);
        service.testDispatchUserLoose(['x']);

        expect(handler.opponentFoundCount, 0);
        expect(handler.countdownCount, 0);
        expect(handler.questionSendCount, 0);
        expect(handler.questionAnswerSendCount, 0);
        expect(handler.userAnswerCount, 0);
        expect(handler.allPlayerAnsweredCount, 0);
        expect(handler.scoreUpdateCount, 0);
        expect(handler.partyFinishedCount, 0);
        expect(handler.userWinCount, 0);
        expect(handler.userLooseCount, 0);
      });
    });

    // ───────────────────────── _notifyHandlers ────────────────────────────
    group('_notifyHandlers', () {
      test('ne notifie pas quand le service est déconnecté', () {
        // État par défaut : disconnected
        service.addEventHandler(handler);
        service.testDispatchCountdown([5]);
        expect(handler.countdownCount, 0);
      });

      test('isole les exceptions levées par un handler', () {
        service.testSetConnectionState(RankedConnectionState.connected);
        service.addEventHandler(_ThrowingHandler());
        service.addEventHandler(handler);

        service.testDispatchCountdown([7]);

        // Le handler qui lève est ignoré, l'autre est tout de même notifié.
        expect(handler.countdownCount, 1);
      });

      test('addEventHandler ignore les doublons', () {
        service.testSetConnectionState(RankedConnectionState.connected);
        service.addEventHandler(handler);
        service.addEventHandler(handler); // doublon ignoré

        service.testDispatchCountdown([1]);

        expect(handler.countdownCount, 1);
      });
    });
  });
}
