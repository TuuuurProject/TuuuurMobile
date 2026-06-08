import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/api/auth/token_provider.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_websocket_service.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_models.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';
import 'package:tuuuur_flutter/stores/ranked_coordinator.dart';

class _FakeTokenProvider implements TokenProvider {
  @override
  String? get accessToken => 'fake-token-for-coord';

  @override
  DateTime? get accessTokenExpiresAt => DateTime.now().add(const Duration(hours: 1));

  @override
  Future<void> refreshIfNeeded() async {}
}

void main() {
  group('RankedCoordinator Tests', () {
    test('Coordinator creates store and service correctly via factory', () {
      final tokenProvider = _FakeTokenProvider();
      
      final coordinator = RankedCoordinator.create(
        tokenProvider: tokenProvider, 
        webSocketHubUrl: 'ws://test.url'
      );
      
      expect(coordinator.store, isA<RankedStore>());
      expect(coordinator.isConnected, isFalse);
      expect(coordinator.store.state, RankedGameState.idle);
    });

    test('Coordinator joinQueue uses store', () async {
      final tokenProvider = _FakeTokenProvider();
      final coordinator = RankedCoordinator.create(
        tokenProvider: tokenProvider, 
        webSocketHubUrl: 'ws://test.url'
      );

      await coordinator.joinQueue();
      expect(coordinator.store.state, isNot(RankedGameState.idle));
    });
    
    test('Coordinator disconnect resets store and stops service', () async {
      final tokenProvider = _FakeTokenProvider();
      final coordinator = RankedCoordinator.create(
        tokenProvider: tokenProvider, 
        webSocketHubUrl: 'ws://test.url'
      );

      coordinator.store.onError('fake error');
      await coordinator.disconnect();
      expect(coordinator.store.state, RankedGameState.idle);
    });
  });

  group('RankedStore Events test', () {
    late RankedStore store;

    setUp(() {
      final tokenProvider = _FakeTokenProvider();
      final coordinator = RankedCoordinator.create(
        tokenProvider: tokenProvider, 
        webSocketHubUrl: 'ws://test.url'
      );
      store = coordinator.store;
    });

    test('onConnectionError sets state to error', () {
      store.onConnectionError('ws error test');
      expect(store.state, RankedGameState.error);
      expect(store.errorMessage, contains('ws error test'));
    });

    test('onOpponentFound sets matchFound state and stores opponent', () {
      final opponent = RankedUser(id: '1', email: 'a@a.com', nickName: 'Bob', globalElo: 100);
      store.onOpponentFound(opponent);
      expect(store.state, RankedGameState.matchFound);
      expect(store.opponent?.nickName, 'Bob');
    });

    test('onCountdown updates state to countdown and resets answer variables', () {
      store.onOpponentFound(RankedUser(id: '1', email: 'a@a.com', nickName: 'Bob', globalElo: 100)); // In a match
      store.selectAnswer(123); // Make some dummy changes to test reset
      store.onCountdown(5);
      
      expect(store.state, RankedGameState.countdown);
      expect(store.countdownValue, 5);
      expect(store.hasAnswered, isFalse);
      expect(store.opponentHasAnswered, isFalse);
      expect(store.myAnswerId, isNull);
    });

    test('onQuestionSend sets questionActive state', () {
      store.onOpponentFound(RankedUser(id: '1', email: 'a@a.com', nickName: 'Bob', globalElo: 100));
      
      final question = RankedQuestion(
        question: RankedQuestionBase(
          id: 1, label: '2+2?', idDifficulty: 1, answer: []
        ),
        score: 10,
        currentIndex: 0,
        multiplier: 1.0,
      );
      store.onQuestionSend(question);
      
      expect(store.state, RankedGameState.questionActive);
      expect(store.currentQuestion?.question.label, '2+2?');
      expect(store.hasAnswered, isFalse);
    });

    test('selectAnswer and submitAnswer works', () async {
      store.onOpponentFound(RankedUser(id: '1', email: 'a@a.com', nickName: 'Bob', globalElo: 100));
      store.onQuestionSend(RankedQuestion(
        question: RankedQuestionBase(id: 1, label: 'x', answer: [], idDifficulty: 1),
        score: 10,
        currentIndex: 0,
        multiplier: 1.0,
      ));

      store.selectAnswer(42);
      expect(store.myAnswerId, 42);

      // submitAnswer fails normally since webSocket isn't connected to real backend
      await store.submitAnswer();
      // Normally state resets to false if error, let's see. We are not mocking webSocket service throwing, wait webSocket will throw "Exception('Not connected')".
      // So hasAnswered will be false and errorMessage will be "Error sending answer"
      expect(store.hasAnswered, isFalse);
      expect(store.errorMessage, 'Error sending answer');
    });
  });
}
