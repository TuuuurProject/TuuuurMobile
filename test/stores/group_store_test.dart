import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/stores/group_store.dart';
import 'package:tuuuur_flutter/api/group/group_models.dart';
import 'package:tuuuur_flutter/api/group/group_websocket_service.dart';
import 'package:tuuuur_flutter/api/auth/token_provider.dart';

/// Mock WebSocket Service for testing
class MockGroupWebSocketService extends GroupWebSocketService {
  MockGroupWebSocketService()
    : super(
        hubUrl: 'http://localhost/test',
        tokenProvider: MockTokenProvider(),
      );

  bool _connected = false;

  @override
  bool get isConnected => _connected;

  void setConnected(bool value) {
    _connected = value;
  }

  @override
  Future<void> sendAnswer(int answerId) async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> startGroupParty() async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }
}

/// Mock Token Provider for testing
class MockTokenProvider implements TokenProvider {
  @override
  String? get accessToken => 'mock_token';

  @override
  DateTime? get accessTokenExpiresAt => DateTime.now().add(Duration(hours: 1));

  @override
  Future<void> refreshIfNeeded() async {
    // Do nothing
  }
}

void main() {
  group('GroupStore', () {
    late GroupStore store;
    late MockGroupWebSocketService mockWebSocket;

    setUp(() {
      mockWebSocket = MockGroupWebSocketService();
      store = GroupStore(webSocketService: mockWebSocket);
    });

    tearDown(() {
      store.dispose();
    });

    group('Initial State', () {
      test('starts with idle state', () {
        expect(store.state, equals(GroupPartyState.idle));
      });

      test('starts with null party', () {
        expect(store.currentParty, isNull);
      });

      test('starts with null question', () {
        expect(store.currentQuestion, isNull);
      });

      test('starts with empty scores', () {
        expect(store.currentScores, isEmpty);
        expect(store.finalScores, isEmpty);
      });

      test('starts with no error', () {
        expect(store.errorMessage, isNull);
      });

      test('starts with empty answered users', () {
        expect(store.answeredUserIds, isEmpty);
      });

      test('starts with no selected answer', () {
        expect(store.myAnswerId, isNull);
      });

      test('starts with zero total score', () {
        expect(store.myTotalScore, equals(0));
      });

      test('starts with empty questions history', () {
        expect(store.questionsHistory, isEmpty);
      });
    });

    group('initializeParty', () {
      test('sets party and initializes scores', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final user2 = GroupUser(id: '2', nickName: 'Bob');
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: false,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [
            PartyUser(idUser: '1', idParty: 'party1', user: user1),
            PartyUser(idUser: '2', idParty: 'party1', user: user2),
          ],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );

        store.initializeParty(party, currentUserId: '1');

        expect(store.currentParty, equals(party));
        expect(store.state, equals(GroupPartyState.lobby));
        expect(store.currentScores.length, equals(2));
        expect(store.currentScores[0].score, equals(0));
        expect(store.errorMessage, isNull);
      });

      test('sets state to questionActive if party is inProgress', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: true,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [PartyUser(idUser: '1', idParty: 'party1', user: user1)],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );

        store.initializeParty(party, currentUserId: '1');

        expect(store.state, equals(GroupPartyState.questionActive));
      });

      test('resets all gameplay state', () {
        store.selectAnswer(1);
        store.initializeParty(
          GroupParty(
            id: 'party1',
            code: 'ABC123',
            nbQuestions: 10,
            inProgress: false,
            scoreEachRound: false,
            idPartyType: 1,
            idUserHost: '1',
            active: true,
            finish: false,
            dt: '2024-01-01T00:00:00Z',
            partyUsers: [],
            partyTheme: [],
            partyDifficulty: [],
            percent: 0,
            score: 0,
            time: 0,
          ),
        );

        expect(store.myAnswerId, isNull);
        expect(store.myTotalScore, equals(0));
        expect(store.answeredUserIds, isEmpty);
      });
    });

    group('reset', () {
      test('resets all state to initial values', () {
        // Set some state
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: false,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );
        store.initializeParty(party);

        // Reset
        store.reset();

        expect(store.state, equals(GroupPartyState.idle));
        expect(store.currentParty, isNull);
        expect(store.currentQuestion, isNull);
        expect(store.currentScores, isEmpty);
        expect(store.finalScores, isEmpty);
        expect(store.errorMessage, isNull);
        expect(store.myAnswerId, isNull);
        expect(store.myTotalScore, equals(0));
      });
    });

    group('clearError', () {
      test('clears error message', () {
        store.onError('Test error');
        expect(store.errorMessage, equals('Test error'));

        store.clearError();
        expect(store.errorMessage, isNull);
        expect(store.state, equals(GroupPartyState.idle));
      });

      test('resets state from error to idle', () {
        store.onError('Error');
        expect(store.state, equals(GroupPartyState.error));

        store.clearError();
        expect(store.state, equals(GroupPartyState.idle));
      });
    });

    group('returnToLobby', () {
      test('returns to lobby state and resets game state', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: false,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [PartyUser(idUser: '1', idParty: 'party1', user: user1)],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );

        store.initializeParty(party, currentUserId: '1');
        store.selectAnswer(1);
        store.onPartyStarted(party);

        store.returnToLobby();

        expect(store.state, equals(GroupPartyState.lobby));
        expect(store.currentQuestion, isNull);
        expect(store.myAnswerId, isNull);
        expect(store.myTotalScore, equals(0));
        expect(store.finalScores, isEmpty);
      });

      test('does nothing if no party', () {
        store.returnToLobby();
        expect(store.state, equals(GroupPartyState.idle));
      });
    });

    group('selectAnswer', () {
      test('selects answer when in questionActive state', () {
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: true,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );
        store.initializeParty(party);

        store.selectAnswer(42);

        expect(store.myAnswerId, equals(42));
      });

      test('does not select answer if not in questionActive state', () {
        store.selectAnswer(42);
        expect(store.myAnswerId, isNull);
      });
    });

    group('submitAnswer', () {
      test('does nothing if no answer selected', () async {
        await store.submitAnswer();
        expect(store.myAnswerId, isNull);
      });

      test('adds current user to answered users', () async {
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: true,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );
        store.initializeParty(party, currentUserId: 'user1');
        store.selectAnswer(42);

        await store.submitAnswer();

        expect(store.answeredUserIds, contains('user1'));
      });
    });

    group('Players', () {
      test('returns list of users from party', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final user2 = GroupUser(id: '2', nickName: 'Bob');
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: false,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [
            PartyUser(idUser: '1', idParty: 'party1', user: user1),
            PartyUser(idUser: '2', idParty: 'party1', user: user2),
          ],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );

        store.initializeParty(party);

        final players = store.players;
        expect(players.length, equals(2));
        expect(players[0].nickName, equals('Alice'));
        expect(players[1].nickName, equals('Bob'));
      });

      test('returns empty list if no party', () {
        expect(store.players, isEmpty);
      });
    });

    group('isHost', () {
      test('returns true if user is host', () {
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: false,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: 'user1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );

        store.initializeParty(party);

        expect(store.isHost('user1'), isTrue);
        expect(store.isHost('user2'), isFalse);
      });
    });

    group('WebSocket Event Handlers', () {
      test('onPlayerJoined adds new player to party', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: false,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [PartyUser(idUser: '1', idParty: 'party1', user: user1)],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );

        store.initializeParty(party);

        final newUser = GroupUser(id: '2', nickName: 'Bob');
        store.onPlayerJoined(newUser);

        expect(store.players.length, equals(2));
        expect(store.players[1].nickName, equals('Bob'));
      });

      test('onPlayerJoined does not add duplicate player', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: false,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [PartyUser(idUser: '1', idParty: 'party1', user: user1)],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );

        store.initializeParty(party);

        store.onPlayerJoined(user1);

        expect(store.players.length, equals(1));
      });

      test('onPlayerLeft removes player from party', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final user2 = GroupUser(id: '2', nickName: 'Bob');
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: false,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [
            PartyUser(idUser: '1', idParty: 'party1', user: user1),
            PartyUser(idUser: '2', idParty: 'party1', user: user2),
          ],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );

        store.initializeParty(party);

        store.onPlayerLeft(user2);

        expect(store.players.length, equals(1));
        expect(store.players[0].nickName, equals('Alice'));
      });

      test('onPartyDeleted sets error state', () {
        final host = GroupUser(id: '1', nickName: 'Host');
        store.onPartyDeleted(host);

        expect(store.state, equals(GroupPartyState.error));
        expect(store.errorMessage, contains('supprimée'));
      });

      test('onPartyStarted initializes game', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: true,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [PartyUser(idUser: '1', idParty: 'party1', user: user1)],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );

        store.onPartyStarted(party);

        expect(store.state, equals(GroupPartyState.countdown));
        expect(store.currentParty, equals(party));
        expect(store.myTotalScore, equals(0));
        expect(store.currentScores.length, equals(1));
      });

      test('onCountdown updates countdown value', () {
        store.onCountdown(3);

        expect(store.countdownValue, equals(3));
        expect(store.state, equals(GroupPartyState.countdown));
        expect(store.answeredUserIds, isEmpty);
      });

      test('onQuestionSend sets current question', () {
        final question = Question(
          id: 1,
          label: 'What is 2+2?',
          idDifficulty: 1,
          difficulty: Difficulty(id: 1, label: 'Easy'),
          answer: [
            Answer(id: 1, idQuestion: 1, value: '3'),
            Answer(id: 2, idQuestion: 1, value: '4', valid: true),
          ],
        );

        final groupQuestion = GroupQuestion(
          question: question,
          currentIndex: 1,
          score: 100,
        );

        store.onQuestionSend(groupQuestion);

        expect(store.currentQuestion, equals(groupQuestion));
        expect(store.state, equals(GroupPartyState.questionActive));
      });

      test('onQuestionAnswerSend reveals answer and updates score', () {
        final question = Question(
          id: 1,
          label: 'What is 2+2?',
          idDifficulty: 1,
          difficulty: Difficulty(id: 1, label: 'Easy'),
          answer: [
            Answer(id: 1, idQuestion: 1, value: '3'),
            Answer(id: 2, idQuestion: 1, value: '4', valid: true),
          ],
        );

        final groupQuestion = GroupQuestion(
          question: question,
          currentIndex: 1,
          score: 100,
        );

        // Initialize and select correct answer
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: true,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );
        store.initializeParty(party, currentUserId: '1');
        store.selectAnswer(2); // Correct answer

        store.onQuestionAnswerSend(groupQuestion);

        expect(store.state, equals(GroupPartyState.answerReveal));
        expect(store.myTotalScore, equals(100));
        expect(store.questionsHistory.length, equals(1));
        expect(store.questionsHistory[0].wasCorrect, isTrue);
      });

      test('onUserAnswer adds user to answered set', () {
        final user = GroupUser(id: '1', nickName: 'Alice');
        store.onUserAnswer(user);

        expect(store.answeredUserIds, contains('1'));
      });

      test('onAllPlayerAnswered updates user correctness map', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final user2 = GroupUser(id: '2', nickName: 'Bob');

        final userAnswers = [
          UserAnswered(user: user1, correct: true),
          UserAnswered(user: user2, correct: false),
        ];

        store.onAllPlayerAnswered(userAnswers);

        expect(store.userAnswerCorrectness['1'], isTrue);
        expect(store.userAnswerCorrectness['2'], isFalse);
      });

      test('onScoreUpdate updates current scores', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final scores = [UserScore(user: user1, score: 150)];

        store.onScoreUpdate(scores);

        expect(store.state, equals(GroupPartyState.scoreDisplay));
        expect(store.currentScores.length, equals(1));
        expect(store.currentScores[0].score, equals(150));
      });

      test('onPartyFinished sets final scores', () {
        final user1 = GroupUser(id: '1', nickName: 'Alice');
        final scores = [UserScore(user: user1, score: 500)];

        store.onPartyFinished(scores);

        expect(store.state, equals(GroupPartyState.finished));
        expect(store.finalScores.length, equals(1));
        expect(store.finalScores[0].score, equals(500));
      });

      test('onError sets error state and message', () {
        store.onError('Test error');

        expect(store.state, equals(GroupPartyState.error));
        expect(store.errorMessage, equals('Test error'));
      });

      test('onConnected notifies listeners', () {
        var notified = false;
        store.addListener(() => notified = true);

        store.onConnected();

        expect(notified, isTrue);
      });

      test('onDisconnected sets error if not idle', () {
        final party = GroupParty(
          id: 'party1',
          code: 'ABC123',
          nbQuestions: 10,
          inProgress: false,
          scoreEachRound: false,
          idPartyType: 1,
          idUserHost: '1',
          active: true,
          finish: false,
          dt: '2024-01-01T00:00:00Z',
          partyUsers: [],
          partyTheme: [],
          partyDifficulty: [],
          percent: 0,
          score: 0,
          time: 0,
        );
        store.initializeParty(party);

        store.onDisconnected();

        expect(store.state, equals(GroupPartyState.error));
        expect(store.errorMessage, contains('Connection lost'));
      });

      test('onReconnected clears connection error', () {
        store.onError('Connection lost');

        store.onReconnected();

        expect(store.errorMessage, isNull);
      });
    });
  });
}
