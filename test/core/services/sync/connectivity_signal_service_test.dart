import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/connectivity_signal_service.dart';

class _FakeConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  void emit(List<ConnectivityResult> results) => _controller.add(results);

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;

  // --- Stub required interface methods ---
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.none];

  Future<void> close() => _controller.close();
}

void main() {
  group('ConnectivitySignalService', () {
    test('emits on onReconnect when connectivity is restored', () async {
      final fakeConnectivity = _FakeConnectivity();
      final service = ConnectivitySignalService(fakeConnectivity);

      final reconnectEvents = <void>[];
      final subscription = service.onReconnect.listen((_) {
        reconnectEvents.add(null);
      });

      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(reconnectEvents, hasLength(1));

      await subscription.cancel();
      await service.dispose();
      await fakeConnectivity.close();
    });

    test('emits multiple times for multiple connectivity restore events', () async {
      final fakeConnectivity = _FakeConnectivity();
      final service = ConnectivitySignalService(fakeConnectivity);

      final reconnectEvents = <void>[];
      final subscription = service.onReconnect.listen((_) {
        reconnectEvents.add(null);
      });

      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      fakeConnectivity.emit([ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);

      expect(reconnectEvents, hasLength(2));

      await subscription.cancel();
      await service.dispose();
      await fakeConnectivity.close();
    });

    test('does not emit on onReconnect when connectivity is none', () async {
      final fakeConnectivity = _FakeConnectivity();
      final service = ConnectivitySignalService(fakeConnectivity);

      final reconnectEvents = <void>[];
      final subscription = service.onReconnect.listen((_) {
        reconnectEvents.add(null);
      });

      fakeConnectivity.emit([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      expect(reconnectEvents, isEmpty);

      await subscription.cancel();
      await service.dispose();
      await fakeConnectivity.close();
    });

    test('emits when at least one result is non-none in a multi-result list', () async {
      final fakeConnectivity = _FakeConnectivity();
      final service = ConnectivitySignalService(fakeConnectivity);

      final reconnectEvents = <void>[];
      final subscription = service.onReconnect.listen((_) {
        reconnectEvents.add(null);
      });

      fakeConnectivity.emit([ConnectivityResult.none, ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(reconnectEvents, hasLength(1));

      await subscription.cancel();
      await service.dispose();
      await fakeConnectivity.close();
    });

    test('does not emit after dispose', () async {
      final fakeConnectivity = _FakeConnectivity();
      final service = ConnectivitySignalService(fakeConnectivity);

      final reconnectEvents = <void>[];
      final subscription = service.onReconnect.listen((_) {
        reconnectEvents.add(null);
      });

      await service.dispose();

      // Emitting after dispose should not trigger events (controller is closed)
      try {
        fakeConnectivity.emit([ConnectivityResult.wifi]);
      } catch (_) {
        // Connectivity subscription is already cancelled; ignore
      }
      await Future<void>.delayed(Duration.zero);

      expect(reconnectEvents, isEmpty);

      await subscription.cancel();
      await fakeConnectivity.close();
    });

    test('onReconnect stream is broadcast and supports multiple listeners', () async {
      final fakeConnectivity = _FakeConnectivity();
      final service = ConnectivitySignalService(fakeConnectivity);

      final listener1 = <void>[];
      final listener2 = <void>[];
      final sub1 = service.onReconnect.listen((_) => listener1.add(null));
      final sub2 = service.onReconnect.listen((_) => listener2.add(null));

      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(listener1, hasLength(1));
      expect(listener2, hasLength(1));

      await sub1.cancel();
      await sub2.cancel();
      await service.dispose();
      await fakeConnectivity.close();
    });
  });
}