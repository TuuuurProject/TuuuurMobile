import 'package:flutter_test/flutter_test.dart';
import 'package:tuuuur_flutter/api/auth/token_provider.dart';
import 'package:tuuuur_flutter/api/ranked/ranked_websocket_service.dart';
import 'package:tuuuur_flutter/stores/ranked_store.dart';
import 'package:tuuuur_flutter/stores/ranked_coordinator.dart';

class _FakeTokenProvider implements TokenProvider {
  @override
  String? get accessToken => 'fake-token-for-coord';

  @override
  DateTime? get accessTokenExpiresAt => DateTime.now().add(const Duration(hours: 1));

  @override
  Future<void> refreshIfNeeded() async {}
}

void main() {
  group('RankedCoordinator Tests', () {
    test('Coordinator creates store and service correctly via factory', () {
      final tokenProvider = _FakeTokenProvider();
      
      final coordinator = RankedCoordinator.create(
        tokenProvider: tokenProvider, 
        webSocketHubUrl: 'ws://test.url'
      );
      
      expect(coordinator.store, isA<RankedStore>());
      expect(coordinator.isConnected, isFalse);
      expect(coordinator.store.state, RankedGameState.idle);
    });

    test('Coordinator joinQueue uses store', () async {
      final tokenProvider = _FakeTokenProvider();
      final coordinator = RankedCoordinator.create(
        tokenProvider: tokenProvider, 
        webSocketHubUrl: 'ws://test.url'
      );

      await coordinator.joinQueue();
      expect(coordinator.store.state, isNot(RankedGameState.idle));
    });
    
    test('Coordinator disconnect resets store and stops service', () async {
      final tokenProvider = _FakeTokenProvider();
      final coordinator = RankedCoordinator.create(
        tokenProvider: tokenProvider, 
        webSocketHubUrl: 'ws://test.url'
      );

      // force some state to prove it resets
      coordinator.store.onError('fake error');
      
      await coordinator.disconnect();
      
      expect(coordinator.store.state, RankedGameState.idle);
    });
  });
}
