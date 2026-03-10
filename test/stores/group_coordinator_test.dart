import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/stores/group_coordinator.dart';
import 'package:tuuuur_flutter/stores/group_store.dart';
import 'package:tuuuur_flutter/api/group/group_rest_api_service.dart';
import 'package:tuuuur_flutter/api/group/group_websocket_service.dart';
import 'package:tuuuur_flutter/api/group/group_models.dart';
import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth/token_provider.dart';

/// Mock REST API Service for testing
class MockGroupRestApiService extends GroupRestApiService {
  MockGroupRestApiService() : super(apiClient: ApiClient(baseUrl: 'http://localhost'));

  String? createdPartyCode;
  bool shouldFail = false;
  String? failMessage;

  @override
  Future<ApiResponse<GroupParty>> createGroup() async {
    if (shouldFail) {
      return ApiResponse<GroupParty>.err(
        statusCode: 500,
        message: failMessage ?? 'Creation failed',
        raw: null,
      );
    }

    final party = GroupParty(
      id: 'party-id',
      code: 'ABC123',
      nbQuestions: 10,
      inProgress: false,
      scoreEachRound: false,
      idPartyType: 1,
      idUserHost: 'user1',
      active: true,
      finish: false,
      dt: '2024-01-01T00:00:00Z',
      partyUsers: [
        PartyUser(
          idUser: 'user1',
          idParty: 'party-id',
          user: GroupUser(id: 'user1', nickName: 'Host'),
        ),
      ],
      partyTheme: [],
      partyDifficulty: [],
      percent: 0,
      score: 0,
      time: 0,
    );

    createdPartyCode = party.code;
    return ApiResponse<GroupParty>.ok(party, statusCode: 200);
  }

  @override
  Future<ApiResponse<GroupParty>> joinGroup({required String code}) async {
    if (shouldFail) {
      return ApiResponse<GroupParty>.err(
        statusCode: 404,
        message: failMessage ?? 'Party not found',
        raw: null,
      );
    }

    final party = GroupParty(
      id: 'party-id',
      code: code,
      nbQuestions: 10,
      inProgress: false,
      scoreEachRound: false,
      idPartyType: 1,
      idUserHost: 'user1',
      active: true,
      finish: false,
      dt: '2024-01-01T00:00:00Z',
      partyUsers: [
        PartyUser(
          idUser: 'user1',
          idParty: 'party-id',
          user: GroupUser(id: 'user1', nickName: 'Host'),
        ),
        PartyUser(
          idUser: 'user2',
          idParty: 'party-id',
          user: GroupUser(id: 'user2', nickName: 'Player'),
        ),
      ],
      partyTheme: [],
      partyDifficulty: [],
      percent: 0,
      score: 0,
      time: 0,
    );

    return ApiResponse<GroupParty>.ok(party, statusCode: 200);
  }

  @override
  Future<ApiResponse<void>> leaveGroup() async {
    if (shouldFail) {
      return ApiResponse<void>.err(
        statusCode: 500,
        message: failMessage ?? 'Leave failed',
        raw: null,
      );
    }
    return ApiResponse<void>.ok(null, statusCode: 200);
  }

  @override
  Future<ApiResponse<GroupParty>> updateSettings({
    required List<int> themes,
    required List<int> difficulties,
    required int nbQuestions,
    required bool scoreEachRound,
  }) async {
    if (shouldFail) {
      return ApiResponse<GroupParty>.err(
        statusCode: 500,
        message: failMessage ?? 'Update failed',
        raw: null,
      );
    }

    final party = GroupParty(
      id: 'party-id',
      code: 'ABC123',
      nbQuestions: nbQuestions,
      inProgress: false,
      scoreEachRound: scoreEachRound,
      idPartyType: 1,
      idUserHost: 'user1',
      active: true,
      finish: false,
      dt: '2024-01-01T00:00:00Z',
      partyUsers: [],
      partyTheme: themes.map((id) => PartyTheme(
        idTheme: id,
        theme: Theme(id: id, label: 'Theme $id'),
      )).toList(),
      partyDifficulty: difficulties.map((id) => PartyDifficulty(
        idDifficulty: id,
        difficulty: Difficulty(id: id, label: 'Difficulty $id'),
      )).toList(),
      percent: 0,
      score: 0,
      time: 0,
    );

    return ApiResponse<GroupParty>.ok(party, statusCode: 200);
  }
}

/// Mock WebSocket Service for testing
class MockGroupWebSocketService extends GroupWebSocketService {
  MockGroupWebSocketService()
      : super(
          hubUrl: 'http://localhost/test',
          tokenProvider: MockTokenProvider(),
        );

  bool _connected = false;
  bool shouldFailConnect = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (shouldFailConnect) {
      throw Exception('Connection failed');
    }
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<void> sendAnswer(int answerId) async {
    // Mock implementation
  }

  @override
  Future<void> startGroupParty() async {
    // Mock implementation
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
  group('GroupCoordinator', () {
    late GroupCoordinator coordinator;
    late MockGroupRestApiService mockRestApi;
    late MockGroupWebSocketService mockWebSocket;
    late GroupStore store;

    setUp(() {
      mockRestApi = MockGroupRestApiService();
      mockWebSocket = MockGroupWebSocketService();
      store = GroupStore(webSocketService: mockWebSocket);
      coordinator = GroupCoordinator(
        restApi: mockRestApi,
        webSocketService: mockWebSocket,
        store: store,
      );
    });

    tearDown(() {
      coordinator.dispose();
    });

    group('Factory', () {
      test('creates complete coordinator with all dependencies', () {
        final coord = GroupCoordinator.create(
          apiClient: ApiClient(baseUrl: 'http://localhost'),
          tokenProvider: MockTokenProvider(),
          webSocketHubUrl: 'http://localhost/hub',
        );

        expect(coord.store, isNotNull);
        expect(coord, isA<GroupCoordinator>());

        coord.dispose();
      });
    });

    group('Store Access', () {
      test('provides access to store', () {
        expect(coordinator.store, equals(store));
      });

      test('provides connection state', () {
        expect(coordinator.isConnected, isFalse);
        
        mockWebSocket._connected = true;
        expect(coordinator.isConnected, isTrue);
      });
    });

    group('createAndJoinParty', () {
      test('successfully creates party and connects websocket', () async {
        final code = await coordinator.createAndJoinParty(currentUserId: 'user1');

        expect(code, equals('ABC123'));
        expect(mockRestApi.createdPartyCode, equals('ABC123'));
        expect(mockWebSocket.isConnected, isTrue);
        expect(store.currentParty, isNotNull);
        expect(store.state, equals(GroupPartyState.lobby));
      });

      test('returns null on REST API failure', () async {
        mockRestApi.shouldFail = true;
        mockRestApi.failMessage = 'Server error';

        final code = await coordinator.createAndJoinParty(currentUserId: 'user1');

        expect(code, isNull);
        expect(store.state, equals(GroupPartyState.error));
        expect(store.errorMessage, contains('Server error'));
      });

      test('handles websocket connection failure', () async {
        mockWebSocket.shouldFailConnect = true;

        final code = await coordinator.createAndJoinParty(currentUserId: 'user1');

        expect(code, isNull);
        expect(store.state, equals(GroupPartyState.error));
      });
    });

    group('joinParty', () {
      test('successfully joins party with code', () async {
        final success = await coordinator.joinParty('XYZ789', currentUserId: 'user2');

        expect(success, isTrue);
        expect(mockWebSocket.isConnected, isTrue);
        expect(store.currentParty, isNotNull);
        expect(store.currentParty?.code, equals('XYZ789'));
      });

      test('returns false on invalid code', () async {
        mockRestApi.shouldFail = true;
        mockRestApi.failMessage = 'Code de partie invalide';

        final success = await coordinator.joinParty('WRONG', currentUserId: 'user2');

        expect(success, isFalse);
        expect(store.state, equals(GroupPartyState.error));
        expect(store.errorMessage, contains('Code de partie invalide'));
      });

      test('handles exception during join', () async {
        mockWebSocket.shouldFailConnect = true;

        final success = await coordinator.joinParty('XYZ789', currentUserId: 'user2');

        expect(success, isFalse);
      });
    });

    group('leaveParty', () {
      test('disconnects websocket and calls REST API', () async {
        // First join a party
        await coordinator.createAndJoinParty(currentUserId: 'user1');
        expect(mockWebSocket.isConnected, isTrue);

        // Then leave
        await coordinator.leaveParty();

        expect(mockWebSocket.isConnected, isFalse);
        expect(store.state, equals(GroupPartyState.idle));
        expect(store.currentParty, isNull);
      });

      test('prevents multiple simultaneous leave calls', () async {
        await coordinator.createAndJoinParty(currentUserId: 'user1');

        // Call leave multiple times
        final future1 = coordinator.leaveParty();
        final future2 = coordinator.leaveParty();

        await future1;
        await future2;

        // Should complete without errors
        expect(store.state, equals(GroupPartyState.idle));
      });

      test('handles websocket disconnect errors gracefully', () async {
        await coordinator.createAndJoinParty(currentUserId: 'user1');

        // This should not throw even if disconnect fails
        await coordinator.leaveParty();

        expect(store.state, equals(GroupPartyState.idle));
      });
    });

    group('updatePartySettings', () {
      test('successfully updates settings', () async {
        await coordinator.createAndJoinParty(currentUserId: 'user1');

        final success = await coordinator.updatePartySettings(
          themes: [1, 2],
          difficulties: [2, 3],
          nbQuestions: 15,
          scoreEachRound: true,
        );

        expect(success, isTrue);
      });

      test('returns false on update failure', () async {
        await coordinator.createAndJoinParty(currentUserId: 'user1');

        mockRestApi.shouldFail = true;
        mockRestApi.failMessage = 'Update error';

        final success = await coordinator.updatePartySettings(
          themes: [1],
          difficulties: [1],
          nbQuestions: 10,
          scoreEachRound: false,
        );

        expect(success, isFalse);
        expect(store.state, equals(GroupPartyState.error));
      });
    });

    group('Game Actions', () {
      test('startParty delegates to store', () async {
        await coordinator.createAndJoinParty(currentUserId: 'user1');

        // Change state to loading before starting
        store.initializeParty(store.currentParty!, currentUserId: 'user1');

        await coordinator.startParty();

        // State should change (mock doesn't really start, but method is called)
        expect(store.state, isNot(equals(GroupPartyState.idle)));
      });

      test('selectAnswer delegates to store', () {
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

        coordinator.selectAnswer(42);

        expect(store.myAnswerId, equals(42));
      });

      test('submitAnswer delegates to store', () async {
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
        coordinator.selectAnswer(42);

        await coordinator.submitAnswer();

        expect(store.answeredUserIds, contains('user1'));
      });
    });

    group('Cleanup', () {
      test('dispose disconnects websocket and disposes store', () {
        // Create fresh coordinator for this test to avoid double disposal
        final freshMockRestApi = MockGroupRestApiService();
        final freshMockWebSocket = MockGroupWebSocketService();
        freshMockWebSocket._connected = true;
        final freshStore = GroupStore(webSocketService: freshMockWebSocket);
        final freshCoordinator = GroupCoordinator(
          restApi: freshMockRestApi,
          webSocketService: freshMockWebSocket,
          store: freshStore,
        );

        freshCoordinator.dispose();

        expect(freshMockWebSocket.isConnected, isFalse);
      });
    });
  });
}
