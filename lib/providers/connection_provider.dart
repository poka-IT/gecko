import 'dart:async';
import 'package:flutter/material.dart';
import 'package:durt2/durt2.dart' show Durt, ConnectionStatus;

class ConnectionProvider with ChangeNotifier {
  ConnectionStatus _connectionStatus = Durt.i.connectionStatus;
  late StreamSubscription<ConnectionStatus> _connectionStatusSubscription;

  ConnectionProvider() {
    _connectionStatusSubscription = Durt.i.connectionStatusStream.listen((status) {
      if (_connectionStatus != status) {
        _connectionStatus = status;
        notifyListeners();
      }
    });
  }

  ConnectionStatus get connectionStatus => _connectionStatus;

  @override
  void dispose() {
    _connectionStatusSubscription.cancel();
    super.dispose();
  }
}
