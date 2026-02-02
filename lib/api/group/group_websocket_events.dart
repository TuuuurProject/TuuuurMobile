import 'group_models.dart';

/// Handles real-time WebSocket events for group parties
abstract class GroupWebSocketEventHandler {
  void onPlayerJoined(GroupUser user);

  void onPlayerLeft(GroupUser user);

  void onPartyDeleted(GroupUser deletedBy);

  void onPartyUpdated(GroupParty party);

  void onPartyStarted(GroupParty party);

  void onCountdown(int seconds);

  void onQuestionSend(GroupQuestion groupQuestion);

  void onQuestionAnswerSend(GroupQuestion groupQuestion);

  void onUserAnswer(GroupUser user);

  void onScoreUpdate(List<UserScore> userScores);

  void onPartyFinished(List<UserScore> userScores);

  void onError(String errorMessage);

  void onConnected();

  void onDisconnected();

  void onReconnecting();

  void onReconnected();
}