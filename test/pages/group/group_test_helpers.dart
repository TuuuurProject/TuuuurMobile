// Shared helpers for group page tests.
// Does NOT import flutter/material.dart to avoid 'Theme' name conflict.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/api/api_client.dart';
import 'package:tuuuur_flutter/api/auth/auth_models.dart';
import 'package:tuuuur_flutter/api/auth/token_provider.dart';
import 'package:tuuuur_flutter/api/group/group_models.dart';
import 'package:tuuuur_flutter/api/group/group_rest_api_service.dart';
import 'package:tuuuur_flutter/api/group/group_websocket_service.dart';
import 'package:tuuuur_flutter/stores/auth_store.dart';
import 'package:tuuuur_flutter/stores/group_coordinator.dart';
import 'package:tuuuur_flutter/stores/group_store.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Secure-storage MethodChannel mock
// ─────────────────────────────────────────────────────────────────────────────

const MethodChannel kSecureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
final Map<String, String> kSecureStore = {};

void setupSecureStorageMock() {
  kSecureStorageChannel.setMockMethodCallHandler((MethodCall call) async {
    final args =
        (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
    switch (call.method) {
      case 'write':
        final key = args['key'] as String?;
        final value = args['value'] as String?;
        if (key != null && value != null) kSecureStore[key] = value;
        return null;
      case 'read':
        final key = args['key'] as String?;
        return key == null ? null : kSecureStore[key];
      case 'delete':
        kSecureStore.remove(args['key'] as String? ?? '');
        return null;
      case 'deleteAll':
        kSecureStore.clear();
        return null;
      case 'readAll':
        return Map<String, String>.from(kSecureStore);
      case 'containsKey':
        final key = args['key'] as String?;
        return key != null && kSecureStore.containsKey(key);
      default:
        return null;
    }
  });
}

void tearDownSecureStorageMock() {
  kSecureStorageChannel.setMockMethodCallHandler(null);
}

/// Signs in AuthStore.instance with a test session.
Future<void> signInForTest({
  String userId = 'user-1',
  String nick = 'Tester',
}) async {
  final session = AuthSessionDto(
    user: UserDto(id: userId, nickName: nick, email: '$userId@test.com'),
    token: AuthTokenDto(
      token: 'test_token',
      refreshToken: 'test_refresh',
      validTo: DateTime.now().add(const Duration(hours: 1)),
      refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
    ),
    isGoogleUser: false,
    raw: {},
  );
  await AuthStore.instance.signInWithSession(session);
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake TokenProvider
// ─────────────────────────────────────────────────────────────────────────────

class FakeTokenProvider implements TokenProvider {
  @override
  String? get accessToken => 'fake-test-token';

  @override
  DateTime? get accessTokenExpiresAt =>
      DateTime.now().add(const Duration(hours: 1));

  @override
  Future<void> refreshIfNeeded() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake GroupWebSocketService – no actual network calls
// ─────────────────────────────────────────────────────────────────────────────

class FakeGroupWebSocketService extends GroupWebSocketService {
  FakeGroupWebSocketService()
      : super(
          hubUrl: 'http://localhost:1',
          tokenProvider: FakeTokenProvider(),
        );

  @override
  bool get isConnected => false;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> sendAnswer(int answerId) async {}

  @override
  Future<void> startGroupParty() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake GroupCoordinator – overrides all async API methods
// ─────────────────────────────────────────────────────────────────────────────

class FakeGroupCoordinator extends GroupCoordinator {
  bool createSuccess = true;
  bool joinSuccess = true;

  FakeGroupCoordinator({
    required GroupStore groupStore,
    required FakeGroupWebSocketService ws,
  }) : super(
         restApi: GroupRestApiService(
           apiClient: ApiClient(baseUrl: 'http://localhost:1'),
         ),
         webSocketService: ws,
         store: groupStore,
       );

  @override
  Future<String?> createAndJoinParty({String? currentUserId}) async {
    if (!createSuccess) return null;
    final userId = currentUserId ?? 'user-host-1';
    final party = makeGroupParty(code: '123456', hostUserId: userId);
    store.initializeParty(party, currentUserId: userId);
    return party.code;
  }

  @override
  Future<bool> joinParty(String code, {String? currentUserId}) async {
    if (!joinSuccess) return false;
    final party =
        makeGroupParty(code: code, hostUserId: 'other-host', id: 'party-join-1');
    store.initializeParty(party, currentUserId: currentUserId ?? 'user-1');
    return true;
  }

  @override
  Future<void> leaveParty() async {}

  @override
  Future<bool> updatePartySettings({
    required List<int> themes,
    required List<int> difficulties,
    required int nbQuestions,
    required bool scoreEachRound,
  }) async =>
      true;

  @override
  Future<void> startParty() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Test-data factories
// ─────────────────────────────────────────────────────────────────────────────

GroupUser makeGroupUser({
  String id = 'user-1',
  String nickName = 'Player1',
}) =>
    GroupUser(id: id, nickName: nickName);

/// Creates a minimal [GroupParty] for tests.
GroupParty makeGroupParty({
  String id = 'party-id-1',
  String code = '123456',
  String hostUserId = 'user-1',
  int nbQuestions = 10,
  bool inProgress = false,
  bool scoreEachRound = false,
  List<PartyUser>? users,
  List<PartyTheme>? themes,
  List<PartyDifficulty>? difficulties,
}) {
  final partyUsers = users ??
      [
        PartyUser(
          idUser: hostUserId,
          idParty: id,
          user: GroupUser(id: hostUserId, nickName: 'Host'),
        ),
      ];

  return GroupParty(
    id: id,
    code: code,
    nbQuestions: nbQuestions,
    inProgress: inProgress,
    scoreEachRound: scoreEachRound,
    idPartyType: 2,
    idUserHost: hostUserId,
    active: true,
    finish: false,
    dt: DateTime.now().toIso8601String(),
    partyUsers: partyUsers,
    partyTheme: themes ??
        [
          PartyTheme(
            idTheme: 1,
            theme: Theme(id: 1, label: 'Général'),
          ),
        ],
    partyDifficulty: difficulties ??
        [
          PartyDifficulty(
            idDifficulty: 2,
            difficulty: Difficulty(id: 2, label: 'Moyen'),
          ),
        ],
    percent: 0,
    score: 0,
    time: 0,
  );
}

/// Creates a [PartyTheme] for tests (avoids Theme name conflict in test files).
PartyTheme makePartyTheme({int id = 1, String label = 'Général'}) =>
    PartyTheme(idTheme: id, theme: Theme(id: id, label: label));

/// Creates a [PartyDifficulty] for tests.
PartyDifficulty makePartyDifficulty({int id = 2, String label = 'Moyen'}) =>
    PartyDifficulty(
      idDifficulty: id,
      difficulty: Difficulty(id: id, label: label),
    );

/// Creates a minimal [GroupQuestion] for tests.
GroupQuestion makeGroupQuestion({
  int questionId = 1,
  String label = 'Quelle est la capitale de la France ?',
  int correctAnswerId = 11,
  int wrongAnswerId = 12,
  int currentIndex = 0,
  int score = 10,
  bool withValidity = false,
}) =>
    GroupQuestion(
      currentIndex: currentIndex,
      score: score,
      question: Question(
        id: questionId,
        label: label,
        idDifficulty: 2,
        difficulty: Difficulty(id: 2, label: 'Moyen'),
        answer: [
          Answer(
            id: correctAnswerId,
            idQuestion: questionId,
            value: 'Paris',
            valid: withValidity ? true : null,
          ),
          Answer(
            id: wrongAnswerId,
            idQuestion: questionId,
            value: 'Lyon',
            valid: withValidity ? false : null,
          ),
        ],
      ),
    );

/// Creates a minimal [UserScore] for tests.
UserScore makeUserScore({
  String userId = 'user-1',
  String nickName = 'Player1',
  int score = 100,
}) =>
    UserScore(
      score: score,
      user: GroupUser(id: userId, nickName: nickName),
    );

/// Creates a minimal [QuestionHistory] for tests.
QuestionHistory makeQuestionHistory({
  bool wasCorrect = true,
  int scoreGained = 10,
  int? userAnswerId,
  int correctAnswerId = 11,
  int wrongAnswerId = 12,
  String questionLabel = 'Quelle est la capitale de la France ?',
}) =>
    QuestionHistory(
      groupQuestion: makeGroupQuestion(
        withValidity: true,
        correctAnswerId: correctAnswerId,
        wrongAnswerId: wrongAnswerId,
        label: questionLabel,
      ),
      userAnswerId: userAnswerId ?? correctAnswerId,
      wasCorrect: wasCorrect,
      scoreGained: scoreGained,
    );
