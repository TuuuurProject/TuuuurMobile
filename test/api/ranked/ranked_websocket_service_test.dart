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
  });
}
