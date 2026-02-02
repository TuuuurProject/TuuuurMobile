import 'package:flutter/foundation.dart';
import '../api/group/group_models.dart';
import '../api/group/group_websocket_service.dart';
import '../api/group/group_websocket_events.dart';

/// Group party state
enum GroupPartyState {
  idle,
  loading,
  lobby,
  countdown,
  questionActive,
  answerReveal,
  scoreDisplay,
  finished,
  error,
}

/// Store to manage group mode state
class GroupStore extends ChangeNotifier implements GroupWebSocketEventHandler {
  final GroupWebSocketService _webSocketService;

  GroupPartyState _state = GroupPartyState.idle;
  GroupParty? _currentParty;
  GroupQuestion? _currentQuestion;
  List<UserScore> _currentScores = [];
  List<UserScore> _finalScores = [];
  String? _errorMessage;
  int? _countdownValue;
  Set<int> _answeredUserIds = {};
  int? _myAnswerId;
  Map<int, bool> _userAnswerCorrectness = {};
  int? _currentUserId;
  int _myTotalScore = 0;
  List<QuestionHistory> _questionsHistory = [];

  GroupStore({required GroupWebSocketService webSocketService})
    : _webSocketService = webSocketService {
    _webSocketService.addEventHandler(this);
  }

  // ==================== Getters ====================

  GroupPartyState get state => _state;
  GroupParty? get currentParty => _currentParty;
  GroupQuestion? get currentQuestion => _currentQuestion;
  List<UserScore> get currentScores => List.unmodifiable(_currentScores);
  List<UserScore> get finalScores => List.unmodifiable(_finalScores);
  String? get errorMessage => _errorMessage;
  int? get countdownValue => _countdownValue;
  bool get isConnected => _webSocketService.isConnected;
  Set<int> get answeredUserIds => Set.unmodifiable(_answeredUserIds);
  int? get myAnswerId => _myAnswerId;
  Map<int, bool> get userAnswerCorrectness => Map.unmodifiable(_userAnswerCorrectness);
  int get myTotalScore => _myTotalScore;
  List<QuestionHistory> get questionsHistory => List.unmodifiable(_questionsHistory);

  /// Returns list of players in the party
  List<GroupUser> get players {
    if (_currentParty == null) return [];
    return _currentParty!.partyUsers
        .where((pu) => pu.user != null)
        .map((pu) => pu.user!)
        .toList();
  }

  /// Checks if current user is host
  bool isHost(int userId) {
    return _currentParty?.idUserHost == userId;
  }

  // ==================== Actions publiques ====================

  /// Initializes store with party and current user ID
  void initializeParty(GroupParty party, {int? currentUserId}) {
    _currentParty = party;
    _currentUserId = currentUserId;
    _state = party.inProgress
        ? GroupPartyState.questionActive
        : GroupPartyState.lobby;
    _errorMessage = null;
    
    _myTotalScore = 0;
    _currentQuestion = null;
    _countdownValue = null;
    _answeredUserIds.clear();
    _myAnswerId = null;
    _userAnswerCorrectness.clear();
    _questionsHistory.clear();
    
    _currentScores = party.partyUsers
        .where((pu) => pu.user != null)
        .map((pu) => UserScore(user: pu.user!, score: 0))
        .toList();
    
    notifyListeners();
  }

  /// Resets the store
  void reset() {
    _state = GroupPartyState.idle;
    _currentParty = null;
    _currentQuestion = null;
    _currentScores = [];
    _finalScores = [];
    _errorMessage = null;
    _countdownValue = null;
    _answeredUserIds.clear();
    _myAnswerId = null;
    _userAnswerCorrectness.clear();
    _currentUserId = null;
    _myTotalScore = 0;
    _questionsHistory.clear();
    notifyListeners();
  }

  /// Clears error message
  void clearError() {
    _errorMessage = null;
    if (_state == GroupPartyState.error) {
      _state = GroupPartyState.idle;
    }
    notifyListeners();
  }

  /// Selects an answer (without sending to server)
  void selectAnswer(int answerId) {
    if (_state != GroupPartyState.questionActive) {
      return;
    }
    _myAnswerId = answerId;
    notifyListeners();
  }

  /// Submits selected answer to server
  Future<void> submitAnswer() async {
    if (_myAnswerId == null) {
      return;
    }

    if (_state != GroupPartyState.questionActive) {
      return;
    }

    try {
      if (_currentUserId != null) {
        _answeredUserIds.add(_currentUserId!);
        notifyListeners();
      }
      
      await _webSocketService.sendAnswer(_myAnswerId!);
    } on Exception catch (e) {
      if (_currentUserId != null) {
        _answeredUserIds.remove(_currentUserId!);
      }
      _errorMessage = 'Error sending answer';
      notifyListeners();
      rethrow;
    }
  }

  /// Starts the party (host only)
  Future<void> startParty() async {
    if (_state != GroupPartyState.lobby) {
      return;
    }

    try {
      _state = GroupPartyState.loading;
      notifyListeners();

      await _webSocketService.startGroupParty();
    } on Exception catch (e) {
      _state = GroupPartyState.error;
      _errorMessage = 'Error starting party';
      notifyListeners();
      rethrow;
    }
  }

  // ==================== GroupWebSocketEventHandler Implementation ====================

  @override
  void onPlayerJoined(GroupUser user) {
    if (_currentParty != null) {
      final updatedUsers = List<PartyUser>.from(_currentParty!.partyUsers)
        ..add(PartyUser(
          idParty: _currentParty!.id,
          idUser: user.id,
          user: user,
        ));
      
      _currentParty = _currentParty!.copyWith(partyUsers: updatedUsers);
      
      notifyListeners();
    }
  }

  @override
  void onPlayerLeft(GroupUser user) {
    if (_currentParty != null) {
      final updatedUsers = List<PartyUser>.from(_currentParty!.partyUsers)
        ..add(PartyUser(
          idParty: _currentParty!.id,
          idUser: user.id,
          user: user,
        ));
      
      _currentParty = _currentParty!.copyWith(partyUsers: updatedUsers);
      
      notifyListeners();
    }
  }

  @override
  void onPartyDeleted(GroupUser deletedBy) {
    _state = GroupPartyState.error;
    _errorMessage = 'La partie a été supprimée par l\'hôte.';
    notifyListeners();
  }

  @override
  void onPartyUpdated(GroupParty party) {
    if (_currentParty != null) {
      _currentParty = party;
    }
    
    notifyListeners();
  }

  @override
  void onPartyStarted(GroupParty party) {
    _currentParty = party;
    _state = GroupPartyState.countdown;
    
    _myTotalScore = 0;
    _currentQuestion = null;
    _countdownValue = null;
    _answeredUserIds.clear();
    _myAnswerId = null;
    _userAnswerCorrectness.clear();
    _finalScores = [];
    _questionsHistory.clear();
    
    _currentScores = party.partyUsers
        .where((pu) => pu.user != null)
        .map((pu) => UserScore(user: pu.user!, score: 0))
        .toList();
    
    notifyListeners();
  }

  @override
  void onCountdown(int seconds) {
    _countdownValue = seconds;
    _state = GroupPartyState.countdown;
    _answeredUserIds.clear();
    _myAnswerId = null;
    _userAnswerCorrectness.clear();
    notifyListeners();
  }

  @override
  void onQuestionSend(GroupQuestion groupQuestion) {
    _currentQuestion = groupQuestion;
    _state = GroupPartyState.questionActive;
    _countdownValue = null;
    notifyListeners();
  }

  @override
  void onQuestionAnswerSend(GroupQuestion groupQuestion) {
    _currentQuestion = groupQuestion;
    _state = GroupPartyState.answerReveal;
    
    bool wasCorrect = false;
    int scoreGained = 0;
    
    if (_myAnswerId != null) {
      final correctAnswer = groupQuestion.question.answer.firstWhere(
        (a) => a.valid == true,
        orElse: () => groupQuestion.question.answer.first,
      );
      wasCorrect = _myAnswerId == correctAnswer.id;
      if (wasCorrect) {
        scoreGained = groupQuestion.score;
        _myTotalScore += scoreGained;
      }
    }
    
    _questionsHistory.add(
      QuestionHistory(
        groupQuestion: groupQuestion,
        userAnswerId: _myAnswerId,
        wasCorrect: wasCorrect,
        scoreGained: scoreGained,
      ),
    );
    
    notifyListeners();
  }

  @override
  void onUserAnswer(GroupUser user) {
    _answeredUserIds.add(user.id);
    notifyListeners();
  }

  @override
  void onScoreUpdate(List<UserScore> userScores) {
    if (_currentQuestion != null) {
      final questionScore = _currentQuestion!.score;
      
      for (final newScore in userScores) {
        final userId = newScore.user.id;
        
        final oldScore = _currentScores
            .where((s) => s.user.id == userId)
            .map((s) => s.score)
            .firstOrNull;
        
        final previousScore = oldScore ?? 0;
        final scoreDiff = newScore.score - previousScore;
        _userAnswerCorrectness[userId] = scoreDiff > 0;
        
        if (_currentUserId != null && userId == _currentUserId) {
          _myTotalScore = newScore.score;
        }
      }
    }
    
    _currentScores = userScores;
    _state = GroupPartyState.scoreDisplay;
    notifyListeners();
  }

  @override
  void onPartyFinished(List<UserScore> userScores) {
    _finalScores = userScores;
    _state = GroupPartyState.finished;
    notifyListeners();
  }

  @override
  void onError(String errorMessage) {
    _errorMessage = errorMessage;
    _state = GroupPartyState.error;
    notifyListeners();
  }

  @override
  void onConnected() {
    notifyListeners();
  }

  @override
  void onDisconnected() {
    if (_state != GroupPartyState.idle) {
      _state = GroupPartyState.error;
      _errorMessage = 'Connection lost';
      notifyListeners();
    }
  }

  @override
  void onReconnecting() {
    notifyListeners();
  }

  @override
  void onReconnected() {
    if (_state == GroupPartyState.error &&
        _errorMessage?.contains('lost') == true) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  // ==================== Cleanup ====================

  @override
  void dispose() {
    _webSocketService.removeEventHandler(this);
    super.dispose();
  }
}
