import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivitySignalService {
  final Connectivity _connectivity;
  final StreamController<void> _reconnectController =
      StreamController<void>.broadcast();

  ConnectivitySignalService(this._connectivity) {
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  Stream<void> get onReconnect => _reconnectController.stream;

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.any((result) => result != ConnectivityResult.none)) {
      _reconnectController.add(null);
    }
  }

  void dispose() {
    _reconnectController.close();
  }
}
