import 'dart:async';
import 'dart:developer' as dev;
import 'package:meta/meta.dart';
import 'package:signalr_core/signalr_core.dart';
import '../../api/auth/token_provider.dart';
import 'ranked_models.dart';
import 'ranked_websocket_events.dart';

enum RankedConnectionState { disconnected, connecting, connected, reconnecting }

class RankedWebSocketService {
  HubConnection? _hubConnection;
  int _connectionGeneration = 0;
  final String _hubUrl;
  final TokenProvider _tokenProvider;
  final List<RankedWebSocketEventHandler> _eventHandlers = [];
  RankedConnectionState _connectionState = RankedConnectionState.disconnected;
  bool _manualDisconnect = false;

  RankedWebSocketService({
    required String hubUrl,
    required TokenProvider tokenProvider,
  }) : _hubUrl = hubUrl,
       _tokenProvider = tokenProvider;

  RankedConnectionState get connectionState => _connectionState;

  bool get isConnected =>
      _hubConnection != null &&
      _hubConnection!.state == HubConnectionState.connected;

  void addEventHandler(RankedWebSocketEventHandler handler) {
    if (!_eventHandlers.contains(handler)) {
      _eventHandlers.add(handler);
    }
  }

  void removeEventHandler(RankedWebSocketEventHandler handler) {
    _eventHandlers.remove(handler);
  }

  void _notifyHandlers(void Function(RankedWebSocketEventHandler) callback) {
    if (_connectionState == RankedConnectionState.disconnected) return;
    for (final handler in _eventHandlers) {
      try {
        callback(handler);
      } catch (e) {
        // Silently ignore handler errors
      }
    }
  }

  Future<void> connect() async {
    if (_connectionState == RankedConnectionState.connected ||
        _connectionState == RankedConnectionState.connecting) {
      return;
    }

    final oldHub = _hubConnection;
    if (oldHub != null) {
      try {
        _unregisterServerEvents(oldHub);
        await oldHub.stop().timeout(const Duration(seconds: 2), onTimeout: () {});
      } catch (_) {}
      _hubConnection = null;
    }

    _manualDisconnect = false;
    _connectionState = RankedConnectionState.connecting;

    final generation = ++_connectionGeneration;

    final hub = HubConnectionBuilder()
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

    _hubConnection = hub;

    hub.onclose((error) {
      if (_hubConnection != hub) return;
      if (_manualDisconnect) return;
      _connectionState = RankedConnectionState.disconnected;
      if (error != null) {
        _notifyHandlers((h) => h.onConnectionError(error.toString()));
      }
    });

    hub.onreconnecting((error) {
      if (_hubConnection != hub) return;
      if (_manualDisconnect) return;
      _connectionState = RankedConnectionState.reconnecting;
    });

    hub.onreconnected((connectionId) {
      if (_hubConnection != hub) return;
      if (_manualDisconnect) return;
      _connectionState = RankedConnectionState.connected;
    });

    hub.serverTimeoutInMilliseconds = const Duration(hours: 1).inMilliseconds;
    hub.keepAliveIntervalInMilliseconds = 15000;

    _registerServerEvents(hub, generation);

    await hub.start()?.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('WebSocket connection timeout');
      },
    );

    if (_hubConnection != hub || _connectionGeneration != generation) {
      try {
        await hub.stop();
      } catch (_) {}
      return;
    }

    _connectionState = RankedConnectionState.connected;
  }

  Future<void> disconnect() async {
    final oldHub = _hubConnection;

    _manualDisconnect = true;
    _connectionGeneration++; // invalide immédiatement tous les anciens callbacks
    _connectionState = RankedConnectionState.disconnected;

    if (oldHub != null) {
      _unregisterServerEvents(oldHub);
    }

    _hubConnection = null;

    if (oldHub != null) {
      try {
        await oldHub.stop().timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      } catch (_) {}
    }
  }

  // ==================== Actions (Client -> Server) ====================

  Future<void> joinSearchOpponent() async {
    if (!isConnected) throw Exception('Not connected');
    await _hubConnection!.invoke('JoinSearchOpponent', args: []);
  }

  Future<void> leaveSearchOpponent() async {
    if (!isConnected) return;
    await _hubConnection!.invoke('LeaveSearchOpponent', args: []);
  }

  Future<void> sendAnswer(int answerId) async {
    if (!isConnected) throw Exception('Not connected');
    dev.log('Sending answer $answerId to server', name: 'RankedService');
    print('Sending answer $answerId to server');
    await _hubConnection!.invoke('SendAnswer', args: [answerId]);
  }

  // ==================== Events (Server -> Client) ====================

  void _registerServerEvents(HubConnection hub, int generation) {
    bool isStale() =>
        _hubConnection != hub ||
        _connectionGeneration != generation ||
        _connectionState == RankedConnectionState.disconnected;

    hub.on('OnOpponentFound', (args) {
      if (isStale()) return;
      _handleOpponentFound(args);
    });

    hub.on('OnCountdown', (args) {
      if (isStale()) return;
      _handleCountdown(args);
    });

    hub.on('OnQuestionSend', (args) {
      if (isStale()) return;
      _handleQuestionSend(args);
    });

    hub.on('OnQuestionAnswerSend', (args) {
      if (isStale()) return;
      _handleQuestionAnswerSend(args);
    });

    hub.on('OnUserAnswer', (args) {
      if (isStale()) return;
      _handleUserAnswer(args);
    });

    hub.on('OnAllPlayerAnswered', (args) {
      if (isStale()) return;
      _handleAllPlayerAnswered(args);
    });

    hub.on('OnScoreUpdate', (args) {
      if (isStale()) return;
      _handleScoreUpdate(args);
    });

    hub.on('OnPartyFinished', (args) {
      if (isStale()) return;
      _handlePartyFinished(args);
    });

    hub.on('OnUserWin', (args) {
      if (isStale()) return;
      _handleUserWin(args);
    });

    hub.on('OnUserLoose', (args) {
      if (isStale()) return;
      _handleUserLoose(args);
    });

    hub.on('OnError', (args) {
      if (isStale()) return;
      _handleError(args);
    });
  }

  void _unregisterServerEvents(HubConnection hub) {
    try {
      hub.off('OnOpponentFound');
      hub.off('OnCountdown');
      hub.off('OnQuestionSend');
      hub.off('OnQuestionAnswerSend'); // NOUVEAU
      hub.off('OnUserAnswer');
      hub.off('OnAllPlayerAnswered');
      hub.off('OnScoreUpdate');
      hub.off('OnPartyFinished');
      hub.off('OnUserWin');
      hub.off('OnUserLoose');
      hub.off('OnError');
    } catch (_) {}
  }

  // ==================== Handlers ====================

  Map<String, dynamic> _toJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw FormatException('Expected Map but got ${value.runtimeType}');
  }

  void _handleOpponentFound(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final user = RankedUser.fromJson(_toJsonMap(args.first));
      _notifyHandlers((h) => h.onOpponentFound(user));
    } catch (e) {
      // Ignored parsing error
    }
  }

  void _handleCountdown(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final seconds = (args.first as num).toInt();
      _notifyHandlers((h) => h.onCountdown(seconds));
    } catch (e) { 
      dev.log("Error parsing: `$e", name: "RankedService"); 
      print("Error parsing: `$e");
    }
  }

  void _handleQuestionSend(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final question = RankedQuestion.fromJson(_toJsonMap(args.first));
      _notifyHandlers((h) => h.onQuestionSend(question));
    } catch (e, st) {
      dev.log(
        "Error parsing OnQuestionSend: $e",
        name: "RankedService",
        error: e,
        stackTrace: st,
      );
      print("Error parsing OnQuestionSend: $e");
    }
  }

  void _handleQuestionAnswerSend(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final question = RankedQuestion.fromJson(_toJsonMap(args.first));
      _notifyHandlers((h) => h.onQuestionAnswerSend(question));
    } catch (e, st) {
      dev.log(
        "Error parsing OnQuestionAnswerSend: $e",
        name: "RankedService",
        error: e,
        stackTrace: st,
      );
      print("Error parsing OnQuestionAnswerSend: $e");
    }
  }

  void _handleUserAnswer(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final user = RankedUser.fromJson(_toJsonMap(args.first));
      _notifyHandlers((h) => h.onUserAnswer(user));
    } catch (e) { 
      dev.log("Error parsing: `$e", name: "RankedService"); 
      print("Error parsing: `$e");
    }
  }

  void _handleAllPlayerAnswered(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;

    try {
      final arr = args.first as List<dynamic>;
      final answers = arr
          .map((e) => RankedUserAnswered.fromJson(_toJsonMap(e)))
          .toList();
      _notifyHandlers((h) => h.onAllPlayerAnswered(answers));
    } catch (e) { 
      dev.log("Error parsing: `$e", name: "RankedService"); 
      print("Error parsing: `$e");
    }
  }

  void _handleScoreUpdate(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final arr = args.first as List<dynamic>;
      final scores = arr
          .map((e) => RankedUserScore.fromJson(_toJsonMap(e)))
          .toList();
      _notifyHandlers((h) => h.onScoreUpdate(scores));
    } catch (e) { 
      dev.log("Error parsing: `$e", name: "RankedService"); 
      print("Error parsing: `$e");
    }
  }

  void _handlePartyFinished(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final arr = args.first as List<dynamic>;
      final scores = arr
          .map((e) => RankedUserScore.fromJson(_toJsonMap(e)))
          .toList();
      _notifyHandlers((h) => h.onPartyFinished(scores));
    } catch (e, st) {
      dev.log(
        "Error parsing OnPartyFinished: $e",
        name: "RankedService",
        error: e,
        stackTrace: st,
      );
      print("Error parsing OnPartyFinished: $e");
    }
  }

  void _handleUserWin(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final delta = (args.first as num).toInt();
      _notifyHandlers((h) => h.onUserWin(delta));
    } catch (e) { 
      dev.log("Error parsing: `$e", name: "RankedService");
      print("Error parsing: `$e");
    }
  }

  void _handleUserLoose(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final delta = (args.first as num).toInt();
      _notifyHandlers((h) => h.onUserLoose(delta));
    } catch (e) { 
      dev.log("Error parsing: `$e", name: "RankedService");
      print("Error parsing: `$e");
    }
  }

  void _handleError(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
    final message = args.first.toString();
    _notifyHandlers((h) => h.onError(message));
  }

  // ==================== Test seams (@visibleForTesting) ====================
  // Ces points d'entrée permettent de tester la logique de parsing/dispatch des
  // évènements serveur sans connexion SignalR réelle (même convention que
  // GroupWebSocketService).

  @visibleForTesting
  void testSetConnectionState(RankedConnectionState state) =>
      _connectionState = state;

  @visibleForTesting
  void testDispatchOpponentFound(List<dynamic>? args) =>
      _handleOpponentFound(args);

  @visibleForTesting
  void testDispatchCountdown(List<dynamic>? args) => _handleCountdown(args);

  @visibleForTesting
  void testDispatchQuestionSend(List<dynamic>? args) =>
      _handleQuestionSend(args);

  @visibleForTesting
  void testDispatchQuestionAnswerSend(List<dynamic>? args) =>
      _handleQuestionAnswerSend(args);

  @visibleForTesting
  void testDispatchUserAnswer(List<dynamic>? args) => _handleUserAnswer(args);

  @visibleForTesting
  void testDispatchAllPlayerAnswered(List<dynamic>? args) =>
      _handleAllPlayerAnswered(args);

  @visibleForTesting
  void testDispatchScoreUpdate(List<dynamic>? args) => _handleScoreUpdate(args);

  @visibleForTesting
  void testDispatchPartyFinished(List<dynamic>? args) =>
      _handlePartyFinished(args);

  @visibleForTesting
  void testDispatchUserWin(List<dynamic>? args) => _handleUserWin(args);

  @visibleForTesting
  void testDispatchUserLoose(List<dynamic>? args) => _handleUserLoose(args);

  @visibleForTesting
  void testDispatchError(List<dynamic>? args) => _handleError(args);
}
