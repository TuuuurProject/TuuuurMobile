import 'dart:async';
import 'package:signalr_core/signalr_core.dart';
import 'group_models.dart';
import 'group_websocket_events.dart';
import '../auth/token_provider.dart';

/// WebSocket connection states
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// SignalR WebSocket service managing hub connection, events, and auto-reconnect
class GroupWebSocketService {
  HubConnection? _hubConnection;
  final String _hubUrl;
  final TokenProvider _tokenProvider;
  final List<GroupWebSocketEventHandler> _eventHandlers = [];
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;
  bool _manualDisconnect = false;

  GroupWebSocketService({
    required String hubUrl,
    required TokenProvider tokenProvider,
  }) : _hubUrl = hubUrl,
       _tokenProvider = tokenProvider;

  WebSocketConnectionState get connectionState => _connectionState;

  bool get isConnected =>
      _hubConnection != null &&
      _hubConnection!.state == HubConnectionState.connected;

  void addEventHandler(GroupWebSocketEventHandler handler) {
    if (!_eventHandlers.contains(handler)) {
      _eventHandlers.add(handler);
    }
  }

  void removeEventHandler(GroupWebSocketEventHandler handler) {
    _eventHandlers.remove(handler);
  }

  void _notifyHandlers(void Function(GroupWebSocketEventHandler) callback) {
    for (final handler in _eventHandlers) {
      try {
        callback(handler);
      } catch (e) {
        // Silently ignore handler errors
      }
    }
  }

  Future<void> connect() async {
    if (_connectionState == WebSocketConnectionState.connected ||
        _connectionState == WebSocketConnectionState.connecting) {
      return;
    }

    try {
      if (_hubConnection != null) {
        try {
          _unregisterServerEvents();
          _hubConnection?.stop()?.timeout(
            const Duration(milliseconds: 500),
            onTimeout: () {},
          ).catchError((_) {});
          _hubConnection = null;
        } catch (e) {
          _hubConnection = null;
        }
      }

      _connectionState = WebSocketConnectionState.connecting;

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            HttpConnectionOptions(
              accessTokenFactory: () async {
                final token = _tokenProvider.accessToken;
                if (token == null || token.isEmpty) {
                  throw Exception('Missing token for SignalR');
                }
                return token;
              },
              transport: HttpTransportType.longPolling,
            ),
          )
          .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
          .build();

      _hubConnection!.onclose((error) {
        if (_manualDisconnect) return;
        _handleDisconnected();
      });

      _hubConnection!.onreconnecting((error) {
        if (_manualDisconnect) return;
        _handleReconnecting();
      });

      _hubConnection!.onreconnected((connectionId) {
        if (_manualDisconnect) return;
        _handleReconnected();
      });

      _hubConnection!.serverTimeoutInMilliseconds = const Duration(hours: 1).inMilliseconds;
      _hubConnection!.keepAliveIntervalInMilliseconds = 15000;

      _registerServerEvents();

      await _hubConnection!.start()?.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('WebSocket connection timeout');
        },
      );

      _connectionState = WebSocketConnectionState.connected;
      _notifyHandlers((h) => h.onConnected());
    } on TimeoutException catch (e) {
      _connectionState = WebSocketConnectionState.disconnected;
      _notifyHandlers((h) => h.onError('Connection timeout'));
      rethrow;
    } catch (e) {
      _connectionState = WebSocketConnectionState.disconnected;
      _notifyHandlers((h) => h.onError('Connection error: $e'));
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connectionState == WebSocketConnectionState.disconnected &&
        _hubConnection == null) {
      return;
    }

    final hub = _hubConnection;

    _manualDisconnect = true;
    _connectionState = WebSocketConnectionState.disconnected;
    _unregisterServerEvents();
    _hubConnection = null;
    _notifyHandlers((h) => h.onDisconnected());

    if (hub != null) {
      try {
        await hub.stop()?.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      } catch (e) {
        // Ignore errors during disconnect
      }
    }

    _manualDisconnect = false;
  }

  void _registerServerEvents() {
    final hub = _hubConnection;
    if (hub == null) return;

    hub.on('OnPlayerJoined', _handlePlayerJoined);
    hub.on('OnPlayerLeft', _handlePlayerLeft);
    hub.on('OnPartyDeleted', _handlePartyDeleted);
    hub.on('OnPartyUpdated', _handlePartyUpdated);

    hub.on('OnPartyStarted', _handlePartyStarted);
    hub.on('onPartyStarted', _handlePartyStarted);
    hub.on('PartyStarted', _handlePartyStarted);
    hub.on('partyStarted', _handlePartyStarted);

    hub.on('OnCountdown', _handleCountdown);
    hub.on('OnQuestionSend', _handleQuestionSend);
    hub.on('OnQuestionAnswerSend', _handleQuestionAnswerSend);
    hub.on('OnUserAnswer', _handleUserAnswer);
    hub.on('OnScoreUpdate', _handleScoreUpdate);
    hub.on('OnPartyFinished', _handlePartyFinished);
    hub.on('OnError', _handleError);
  }

  void _unregisterServerEvents() {
    final hub = _hubConnection;
    if (hub == null) return;

    hub.off('OnPlayerJoined', method: _handlePlayerJoined);
    hub.off('OnPlayerLeft', method: _handlePlayerLeft);
    hub.off('OnPartyDeleted', method: _handlePartyDeleted);
    hub.off('OnPartyUpdated', method: _handlePartyUpdated);

    hub.off('OnPartyStarted', method: _handlePartyStarted);
    hub.off('onPartyStarted', method: _handlePartyStarted);
    hub.off('PartyStarted', method: _handlePartyStarted);
    hub.off('partyStarted', method: _handlePartyStarted);

    hub.off('OnCountdown', method: _handleCountdown);
    hub.off('OnQuestionSend', method: _handleQuestionSend);
    hub.off('OnQuestionAnswerSend', method: _handleQuestionAnswerSend);
    hub.off('OnUserAnswer', method: _handleUserAnswer);
    hub.off('OnScoreUpdate', method: _handleScoreUpdate);
    hub.off('OnPartyFinished', method: _handlePartyFinished);
    hub.off('OnError', method: _handleError);
  }

  // ==================== Connection Event Handlers ====================

  void _handleDisconnected() {
    if (_connectionState == WebSocketConnectionState.disconnected) {
      return;
    }
    
    _connectionState = WebSocketConnectionState.disconnected;
    _notifyHandlers((h) => h.onDisconnected());
  }

  void _handleReconnecting() {
    _connectionState = WebSocketConnectionState.reconnecting;
    _notifyHandlers((h) => h.onReconnecting());
  }

  void _handleReconnected() {
    _connectionState = WebSocketConnectionState.connected;
    _notifyHandlers((h) => h.onReconnected());
  }

  // ==================== Server Event Handlers ====================

  void _handlePlayerJoined(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final user = GroupUser.fromJson(arguments[0] as Map<String, dynamic>);
      _notifyHandlers((h) => h.onPlayerJoined(user));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handlePlayerLeft(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final user = GroupUser.fromJson(arguments[0] as Map<String, dynamic>);
      _notifyHandlers((h) => h.onPlayerLeft(user));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handlePartyDeleted(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final user = GroupUser.fromJson(arguments[0] as Map<String, dynamic>);
      _notifyHandlers((h) => h.onPartyDeleted(user));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handlePartyUpdated(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final party = GroupParty.fromJson(arguments[0] as Map<String, dynamic>);
      _notifyHandlers((h) => h.onPartyUpdated(party));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handlePartyStarted(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return;
    }
    try {
      final party = GroupParty.fromJson(arguments[0] as Map<String, dynamic>);
      _notifyHandlers((h) => h.onPartyStarted(party));
    } catch (e, stackTrace) {
      // Ignore parsing errors
    }
  }

  void _handleCountdown(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final seconds = arguments[0] as int;
      _notifyHandlers((h) => h.onCountdown(seconds));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handleQuestionSend(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final groupQuestion = GroupQuestion.fromJson(
        arguments[0] as Map<String, dynamic>,
      );
      _notifyHandlers((h) => h.onQuestionSend(groupQuestion));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handleQuestionAnswerSend(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final groupQuestion = GroupQuestion.fromJson(
        arguments[0] as Map<String, dynamic>,
      );
      _notifyHandlers((h) => h.onQuestionAnswerSend(groupQuestion));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handleUserAnswer(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final user = GroupUser.fromJson(arguments[0] as Map<String, dynamic>);
      _notifyHandlers((h) => h.onUserAnswer(user));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handleScoreUpdate(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final userScoresList = arguments[0] as List<dynamic>;
      final userScores = userScoresList
          .map((e) => UserScore.fromJson(e as Map<String, dynamic>))
          .toList();
      _notifyHandlers((h) => h.onScoreUpdate(userScores));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handlePartyFinished(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final userScoresList = arguments[0] as List<dynamic>;
      final userScores = userScoresList
          .map((e) => UserScore.fromJson(e as Map<String, dynamic>))
          .toList();
      _notifyHandlers((h) => h.onPartyFinished(userScores));
    } catch (e) {
      // Ignore parsing errors
    }
  }

  void _handleError(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      _notifyHandlers((h) => h.onError('Unknown server error'));
      return;
    }
    try {
      final errorMessage = arguments[0] as String;
      _notifyHandlers((h) => h.onError(errorMessage));
    } catch (e) {
      _notifyHandlers((h) => h.onError('Server error: $e'));
    }
  }

  // ==================== Invocable Methods (Client → Server) ====================

  /// Host only
  Future<void> startGroupParty() async {
    if (!isConnected) {
      throw Exception('WebSocket not connected');
    }

    try {
      await _hubConnection!
          .invoke('StartGroupParty')
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      const error = 'Timeout starting party';
      _notifyHandlers((h) => h.onError(error));
      rethrow;
    } catch (e) {
      _notifyHandlers(
        (h) => h.onError('Error starting party: $e'),
      );
      rethrow;
    }
  }

  Future<void> sendAnswer(int answerId) async {
    if (!isConnected) {
      throw Exception('WebSocket not connected');
    }

    if (answerId <= 0) {
      throw ArgumentError('answerId must be a positive integer');
    }

    try {
      await _hubConnection!
          .invoke('SendAnswer', args: [answerId])
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      const error = 'Timeout sending answer';
      _notifyHandlers((h) => h.onError(error));
      rethrow;
    } catch (e) {
      _notifyHandlers(
        (h) => h.onError('Error sending answer: $e'),
      );
      rethrow;
    }
  }

  Future<void> dispose() async {
    await disconnect();
    _eventHandlers.clear();
    _hubConnection = null;
  }
}
