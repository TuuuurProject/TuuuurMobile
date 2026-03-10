import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;
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
  Set<String> _answeredUserIds = {};
  int? _myAnswerId;
  Map<String, bool> _userAnswerCorrectness = {};
  String? _currentUserId;
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
  Set<String> get answeredUserIds => Set.unmodifiable(_answeredUserIds);
  int? get myAnswerId => _myAnswerId;
  Map<String, bool> get userAnswerCorrectness => Map.unmodifiable(_userAnswerCorrectness);
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
  bool isHost(String userId) {
    return _currentParty?.idUserHost == userId;
  }

  // ==================== Actions publiques ====================

  /// Initializes store with party and current user ID
  void initializeParty(GroupParty party, {String? currentUserId}) {
    dev.log('initializeParty: currentUserId=$currentUserId', name: 'GroupStore');
    dev.log('Party users: ${party.partyUsers.map((pu) => "${pu.user?.nickName ?? 'null'} (idUser: ${pu.idUser}, user.id: ${pu.user?.id})").join(", ")}', name: 'GroupStore');
    
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

  /// Returns to lobby state after a finished game, keeping the party intact
  void returnToLobby() {
    if (_currentParty == null) return;
    
    // Reset game state but keep party information
    _state = GroupPartyState.lobby;
    _currentQuestion = null;
    _countdownValue = null;
    _answeredUserIds.clear();
    _myAnswerId = null;
    _userAnswerCorrectness.clear();
    _myTotalScore = 0;
    _questionsHistory.clear();
    _finalScores = [];
    _errorMessage = null;
    
    // Reset scores for all players
    _currentScores = _currentParty!.partyUsers
        .where((pu) => pu.user != null)
        .map((pu) => UserScore(user: pu.user!, score: 0))
        .toList();
    
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
      dev.log('onPlayerJoined: ${user.nickName} (${user.id})', name: 'GroupStore');
      dev.log('Current players: ${_currentParty!.partyUsers.map((pu) => "${pu.user?.nickName ?? 'null'} (idUser: ${pu.idUser}, user.id: ${pu.user?.id})").join(", ")}', name: 'GroupStore');
      
      // Vérifier si le joueur n'est pas déjà dans la liste
      // On vérifie à la fois idUser et user.id pour être sûr
      final alreadyExists = _currentParty!.partyUsers.any((pu) => 
        pu.idUser == user.id || pu.user?.id == user.id
      );
      
      dev.log('Player already exists: $alreadyExists', name: 'GroupStore');
      
      if (!alreadyExists) {
        dev.log('Adding player to list', name: 'GroupStore');
        final updatedUsers = List<PartyUser>.from(_currentParty!.partyUsers)
          ..add(PartyUser(
            idParty: _currentParty!.id,
            idUser: user.id,
            user: user,
          ));
        
        _currentParty = _currentParty!.copyWith(partyUsers: updatedUsers);
        
        notifyListeners();
      } else {
        dev.log('Player already in list, skipping', name: 'GroupStore');
      }
    }
  }

  @override
  void onPlayerLeft(GroupUser user) {
    if (_currentParty != null) {
      dev.log('onPlayerLeft: ${user.nickName} (${user.id})', name: 'GroupStore');
      
      // Retirer le joueur de la liste
      final updatedUsers = _currentParty!.partyUsers
          .where((pu) => pu.idUser != user.id && pu.user?.id != user.id)
          .toList();
      
      dev.log('Removed player. Remaining: ${updatedUsers.length} players', name: 'GroupStore');
      
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
  void onAllPlayerAnswered(List<UserAnswered> userAnswered) {
    // Mettre à jour _userAnswerCorrectness avec les résultats reçus du serveur
    _userAnswerCorrectness.clear();
    for (final userAnswer in userAnswered) {
      _userAnswerCorrectness[userAnswer.user.id] = userAnswer.correct;
    }
    
    notifyListeners();
  }

  @override
  void onScoreUpdate(List<UserScore> userScores) {
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
