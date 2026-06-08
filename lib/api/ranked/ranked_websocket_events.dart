import 'ranked_models.dart';

/// Define the callbacks that the UI / Store can listen to
abstract class RankedWebSocketEventHandler {
  /// When a connection error happens or auth fails
  void onConnectionError(String error);

  /// Phase d'attente
  void onOpponentFound(RankedUser opponent);

  /// Phase de Question
  void onCountdown(int seconds);
  void onQuestionSend(RankedQuestion question);

  /// Nouveau : question réhydratée avec answer.valid renseigné
  void onQuestionAnswerSend(RankedQuestion question);

  /// Phase de Réponse
  void onUserAnswer(RankedUser opponent);
  void onAllPlayerAnswered(List<RankedUserAnswered> userAnswers);
  void onScoreUpdate(List<RankedUserScore> userScores);

  /// Phase de Fin de Partie
  void onPartyFinished(List<RankedUserScore> userScores);
  void onUserWin(int delta);
  void onUserLoose(int delta);

  /// Erreurs in-game
  void onError(String errorMessage);
}
