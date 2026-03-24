import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;
import '../api/ranked/ranked_models.dart';
import '../api/ranked/ranked_websocket_service.dart';
import '../api/ranked/ranked_websocket_events.dart';

/// Ranked match state
enum RankedGameState {
  idle,
  searching,
  matchFound,
  countdown,
  questionActive,
  answerReveal,
  scoreDisplay,
  finished,
  error,
}

class RankedQuestionHistory {
  final RankedQuestion question;
  final int? userAnswerId;
  final bool wasCorrect;
  final int scoreGained;

  const RankedQuestionHistory({
    required this.question,
    required this.userAnswerId,
    required this.wasCorrect,
    required this.scoreGained,
  });
}

/// Store to manage ranked mode state
class RankedStore extends ChangeNotifier
    implements RankedWebSocketEventHandler {
  final RankedWebSocketService _webSocketService;

  RankedGameState _state = RankedGameState.idle;

  RankedUser? _opponent;
  RankedQuestion? _currentQuestion;

  List<RankedUserScore> _currentScores = [];
  List<RankedUserScore> _finalScores = [];

  String? _errorMessage;
  int? _countdownValue;

  // Track if we answered and who answered
  bool _hasAnswered = false;
  bool _opponentHasAnswered = false;
  int? _myAnswerId;

  // Track results of current turn
  Map<String, bool> _userAnswerCorrectness = {};

  // Final delta details
  int? _eloDelta;
  bool? _isWinner; // true if win, false if loose

  int? _lastTurnScoreDelta;
  int? get lastTurnScoreDelta => _lastTurnScoreDelta;

  final List<RankedQuestionHistory> _questionsHistory = [];
  List<RankedQuestionHistory> get questionsHistory =>
      List.unmodifiable(_questionsHistory);

  RankedStore({required RankedWebSocketService webSocketService})
    : _webSocketService = webSocketService {
    _webSocketService.addEventHandler(this);
  }

  // ==================== Getters ====================

  RankedGameState get state => _state;
  RankedUser? get opponent => _opponent;
  RankedQuestion? get currentQuestion => _currentQuestion;
  List<RankedUserScore> get currentScores => List.unmodifiable(_currentScores);
  List<RankedUserScore> get finalScores => List.unmodifiable(_finalScores);
  String? get errorMessage => _errorMessage;
  int? get countdownValue => _countdownValue;
  bool get isConnected => _webSocketService.isConnected;
  bool get hasAnswered => _hasAnswered;
  bool get opponentHasAnswered => _opponentHasAnswered;
  int? get myAnswerId => _myAnswerId;
  Map<String, bool> get userAnswerCorrectness =>
      Map.unmodifiable(_userAnswerCorrectness);
  int? get eloDelta => _eloDelta;
  bool? get isWinner => _isWinner;

  // ==================== Public Actions ====================

  /// Start searching for an opponent
  Future<void> joinQueue() async {
    try {
      reset();
      _state = RankedGameState.searching;
      notifyListeners();

      if (!_webSocketService.isConnected) {
        await _webSocketService.connect();
      }
      await _webSocketService.joinSearchOpponent();
    } catch (e) {
      _state = RankedGameState.error;
      _errorMessage = 'Failed to join matchmaking: $e';
      notifyListeners();
    }
  }

  /// Leave the matchmaking queue
  Future<void> leaveQueue() async {
    try {
      await _webSocketService.leaveSearchOpponent();
      reset();
    } catch (e) {
      dev.log('Error leaving queue: $e', name: 'RankedStore');
      print('Error leaving queue: $e');
    }
  }

  /// Disconnects from the WebSocket and resets the store
  Future<void> disconnect() async {
    try {
      await _webSocketService.disconnect();
      reset();
      print(
        'RESETTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTRESETTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTRESETTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTRESETTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT',
      );
    } catch (e) {
      dev.log('Error disconnecting: $e', name: 'RankedStore');
      print('Error disconnecting: $e');
    }
  }

  /// Selects an answer (without sending to server, just local UI state)
  void selectAnswer(int answerId) {
    dev.log('selectAnswer called with $answerId', name: 'RankedStore');
    print('selectAnswer called with $answerId');
    if (_state != RankedGameState.questionActive || _hasAnswered) {
      return;
    }
    _myAnswerId = answerId;
    notifyListeners();
  }

  /// Submits selected answer to server
  Future<void> submitAnswer() async {
    dev.log(
      'submitAnswer called. myAnswerId: $_myAnswerId, hasAnswered: $_hasAnswered',
      name: 'RankedStore',
    );
    print(
      'submitAnswer called. myAnswerId: $_myAnswerId, hasAnswered: $_hasAnswered',
    );
    if (_myAnswerId == null || _hasAnswered) {
      return;
    }

    if (_state != RankedGameState.questionActive) {
      dev.log(
        'submitAnswer ignored due to state: $_state',
        name: 'RankedStore',
      );
      print('submitAnswer ignored due to state: $_state');
      return;
    }

    try {
      _hasAnswered = true;
      notifyListeners();

      await _webSocketService.sendAnswer(_myAnswerId!);
    } on Exception catch (e) {
      dev.log('submitAnswer error: $e', name: 'RankedStore');
      print('submitAnswer error: $e');
      _hasAnswered = false;
      _errorMessage = 'Error sending answer';
      notifyListeners();
    }
  }

  /// Reset the game state
  void reset() {
    _state = RankedGameState.idle;
    _opponent = null;
    _currentQuestion = null;
    _currentScores = [];
    _finalScores = [];
    _errorMessage = null;
    _countdownValue = null;
    _hasAnswered = false;
    _opponentHasAnswered = false;
    _myAnswerId = null;
    _userAnswerCorrectness.clear();
    _eloDelta = null;
    _isWinner = null;
    _lastTurnScoreDelta = null; // NOUVEAU
    _questionsHistory.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == RankedGameState.error) {
      _state = RankedGameState.idle;
    }
    notifyListeners();
  }

  // ==================== RankedWebSocketEventHandler Implementation ====================

  bool get _isInMatch => _opponent != null;

  @override
  void onConnectionError(String error) {
    dev.log('Connection error: $error', name: 'RankedStore');
    print('Connection error: $error');
    _state = RankedGameState.error;
    _errorMessage = 'Connection closed: $error';
    notifyListeners();
  }

  @override
  void onOpponentFound(RankedUser opponent) {
    dev.log('onOpponentFound: ${opponent.nickName}', name: 'RankedStore');
    print('onOpponentFound: ${opponent.nickName}');
    _opponent = opponent;
    _state = RankedGameState.matchFound;
    notifyListeners();
  }

  @override
  void onCountdown(int seconds) {
    if (!_isInMatch) return;
    dev.log('onCountdown: $seconds', name: 'RankedStore');
    print('onCountdown: $seconds');
    _countdownValue = seconds;
    _state = RankedGameState.countdown;

    // Clear old turn data when a new countdown sequence starts for a question
    _hasAnswered = false;
    _opponentHasAnswered = false;
    _myAnswerId = null;
    _userAnswerCorrectness.clear();
    _lastTurnScoreDelta = null; // NOUVEAU

    notifyListeners();
  }

  @override
  void onQuestionSend(RankedQuestion question) {
    if (!_isInMatch) return;
    dev.log('onQuestionSend: ${question.question.label}', name: 'RankedStore');
    print('onQuestionSend: ${question.question.label}');
    _currentQuestion = question;
    _state = RankedGameState.questionActive;
    _hasAnswered = false;
    _opponentHasAnswered = false;
    _myAnswerId = null;
    _userAnswerCorrectness.clear();
    _lastTurnScoreDelta = null; // NOUVEAU
    notifyListeners();
  }

  @override
  void onQuestionAnswerSend(RankedQuestion question) {
    if (!_isInMatch) return;
    dev.log(
      'onQuestionAnswerSend: ${question.question.label}',
      name: 'RankedStore',
    );
    print('onQuestionAnswerSend: ${question.question.label}');

    _currentQuestion = question;
    _lastTurnScoreDelta = question.score;

    bool wasCorrect = false;

    if (_myAnswerId != null) {
      for (final answer in question.question.answer) {
        if (answer.id == _myAnswerId) {
          wasCorrect = answer.valid == true;
          break;
        }
      }
    }

    _questionsHistory.add(
      RankedQuestionHistory(
        question: question,
        userAnswerId: _myAnswerId,
        wasCorrect: wasCorrect,
        scoreGained: wasCorrect ? question.score : 0,
      ),
    );

    _state = RankedGameState.answerReveal;
    notifyListeners();
  }

  @override
  void onUserAnswer(RankedUser opponent) {
    if (!_isInMatch) return;
    dev.log(
      'onUserAnswer: ${opponent.nickName} have answered',
      name: 'RankedStore',
    );
    print('onUserAnswer: ${opponent.nickName} have answered');
    if (_opponent != null && opponent.id == _opponent!.id) {
      _opponentHasAnswered = true;
      notifyListeners();
    }
  }

  @override
  void onAllPlayerAnswered(List<RankedUserAnswered> userAnswers) {
    if (!_isInMatch) return;
    dev.log('onAllPlayerAnswered received', name: 'RankedStore');
    print('onAllPlayerAnswered received');

    _userAnswerCorrectness.clear();
    for (var answer in userAnswers) {
      _userAnswerCorrectness[answer.user.id] = answer.correct;
    }

    // IMPORTANT :
    // on ne passe PAS en answerReveal ici.
    // On attend OnQuestionAnswerSend pour avoir answer.valid.
    notifyListeners();
  }

  @override
  void onScoreUpdate(List<RankedUserScore> userScores) {
    if (!_isInMatch) return;
    dev.log('onScoreUpdate received', name: 'RankedStore');
    print('onScoreUpdate received');
    _state = RankedGameState.scoreDisplay;
    _currentScores = userScores;
    notifyListeners();
  }

  @override
  void onPartyFinished(List<RankedUserScore> userScores) {
    if (!_isInMatch) return;
    dev.log('onPartyFinished received', name: 'RankedStore');
    print('onPartyFinished received');
    _state = RankedGameState.finished;
    _finalScores = userScores;
    notifyListeners();
  }

  @override
  void onUserWin(int delta) {
    if (!_isInMatch) return;
    dev.log('onUserWin received, +$delta', name: 'RankedStore');
    print('onUserWin received, +$delta');
    _isWinner = true;
    _eloDelta = delta.abs();
    _state = RankedGameState.finished;
    notifyListeners();
  }

  @override
  void onUserLoose(int delta) {
    if (!_isInMatch) return;
    dev.log('onUserLoose received, -$delta', name: 'RankedStore');
    print('onUserLoose received, -$delta');
    _isWinner = false;
    _eloDelta = delta.abs();
    _state = RankedGameState.finished;
    notifyListeners();
  }

  @override
  void onError(String errorMessage) {
    dev.log('onError: $errorMessage', name: 'RankedStore');
    print('onError: $errorMessage');
    _state = RankedGameState.error;
    _errorMessage = errorMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService.removeEventHandler(this);
    super.dispose();
  }
}
