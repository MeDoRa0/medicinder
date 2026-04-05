import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivitySignalService {
  final Connectivity _connectivity;
  final StreamController<void> _reconnectController =
      StreamController<void>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  ConnectivitySignalService(this._connectivity) {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  Stream<void> get onReconnect => _reconnectController.stream;

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.any((result) => result != ConnectivityResult.none) &&
        !_reconnectController.isClosed) {
      _reconnectController.add(null);
    }
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _reconnectController.close();
  }
}
