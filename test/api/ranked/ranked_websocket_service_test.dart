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
      // Because we don't have a real SignalR server running locally, we expect 
      // service.connect() to eventually time out or fail. But we can test 
      // the immediate state transition or catch the connection error.
      expect(service.connectionState, RankedConnectionState.disconnected);
      final connectFuture = service.connect(); // Starts connecting
      expect(service.connectionState, RankedConnectionState.connecting);

      await service.disconnect();
      expect(service.connectionState, RankedConnectionState.disconnected);
      
      try {
        await connectFuture;
      } catch (_) {}
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
  });
}
