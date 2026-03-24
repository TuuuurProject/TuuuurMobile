import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/api/auth/token_provider.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_models.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_websocket_events.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_websocket_service.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';

class MockRankedWebSocketService extends RankedWebSocketService {
  MockRankedWebSocketService()
      : super(
          hubUrl: 'http://localhost/hub',
          tokenProvider: _FakeTokenProvider(),
        );

  int disconnectCount = 0;
  int joinSearchCount = 0;
  int leaveSearchCount = 0;
  int sendAnswerCount = 0;
  int connectCount = 0;
  
  int? lastAnswerSent;

  @override
  bool get isConnected => true;

  @override
  Future<void> joinSearchOpponent() async {
    joinSearchCount++;
  }

  @override
  Future<void> leaveSearchOpponent() async {
    leaveSearchCount++;
  }

  @override
  Future<void> sendAnswer(int answerId) async {
    sendAnswerCount++;
    lastAnswerSent = answerId;
  }

  @override
  Future<void> disconnect() async {
    disconnectCount++;
  }

  @override
  Future<void> connect() async {
    connectCount++;
  }
}

class _FakeTokenProvider implements TokenProvider {
  @override
  String? get accessToken => 'fake-token';

  @override
  DateTime? get accessTokenExpiresAt => DateTime.now().add(const Duration(hours: 1));

  @override
  Future<void> refreshIfNeeded() async {}
}

void main() {
  group('RankedStore Tests', () {
    late MockRankedWebSocketService mockService;
    late RankedStore store;

    setUp(() {
      mockService = MockRankedWebSocketService();
      store = RankedStore(webSocketService: mockService);
    });

    test('Initial state is idle', () {
      expect(store.state, RankedGameState.idle);
      expect(store.opponent, isNull);
    });

    test('joinQueue changes state to searching and calls service', () async {
      await store.joinQueue();
      expect(store.state, RankedGameState.searching);
      expect(mockService.joinSearchCount, 1);
    });

    test('leaveQueue changes state back to idle', () async {
      await store.leaveQueue();
      expect(store.state, RankedGameState.idle);
      expect(mockService.leaveSearchCount, 1);
    });

    test('onOpponentFound transitions to matchFound with opponent info', () {
      final user = RankedUser(id: '1', nickName: 'S1mple', globalElo: 2800);
      store.onOpponentFound(user);
      expect(store.state, RankedGameState.matchFound);
      expect(store.opponent, equals(user));
    });

    test('onCountdown updates countdown state', () {
      store.onOpponentFound(const RankedUser(id: '1', nickName: 'P', globalElo: 1000));
      store.onCountdown(3);
      expect(store.state, RankedGameState.countdown);
      expect(store.countdownValue, 3);
    });

    test('onQuestionSend resets answer state and goes to questionActive', () {
      store.onOpponentFound(const RankedUser(id: '1', nickName: 'P', globalElo: 1000));
      final tempQ = RankedQuestion(
        question: RankedQuestionBase(id: 1, label: 'Hey', idDifficulty: 1, answer: []),
        currentIndex: 0,
        score: 0,
        multiplier: 1,
      );
      
      store.onQuestionSend(tempQ);
      expect(store.state, RankedGameState.questionActive);
      expect(store.currentQuestion, tempQ);
      expect(store.myAnswerId, isNull);
      expect(store.hasAnswered, isFalse);
    });

    test('submitAnswer updates state to true and calls service', () async {
      store.onOpponentFound(const RankedUser(id: '1', nickName: 'P', globalElo: 1000));
      final tempQ = RankedQuestion(
        question: RankedQuestionBase(id: 1, label: 'Hey', idDifficulty: 1, answer: []),
        currentIndex: 0,
        score: 0,
        multiplier: 1,
      );
      store.onQuestionSend(tempQ);
      
      store.selectAnswer(42);
      expect(store.myAnswerId, 42);
      
      await store.submitAnswer();
      expect(store.hasAnswered, isTrue);
      expect(mockService.sendAnswerCount, 1);
      expect(mockService.lastAnswerSent, 42);
    });
    
    test('onScoreUpdate sets the scores correctly', () {
      store.onOpponentFound(const RankedUser(id: '1', nickName: 'P', globalElo: 1000));
      final playerUser = RankedUser(id: 'me', nickName: 'Player', globalElo: 1000);
      final oppUser = RankedUser(id: '1', nickName: 'Oppo', globalElo: 1000);
      
      final scores = [
         RankedUserScore(score: 50, user: playerUser),
         RankedUserScore(score: 25, user: oppUser),
      ];
      
      store.onScoreUpdate(scores);
      expect(store.state, RankedGameState.scoreDisplay);
    });
    
    test('onError sets state to error and message', () {
      store.onError("Server disconnect");
      expect(store.state, RankedGameState.error);
      expect(store.errorMessage, "Server disconnect");
    });
    
    test('onConnectionError handles connection errors similarly', () {
      store.onConnectionError('Unauthorized');
      expect(store.state, RankedGameState.error);
      expect(store.errorMessage, 'Connection closed: Unauthorized');
    });

    test('reset cleans up state correctly', () {
      store.reset();
      expect(store.state, RankedGameState.idle);
      expect(store.opponent, isNull);
      expect(store.currentQuestion, isNull);
    });
  });
}
