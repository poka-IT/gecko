import 'dart:async';
import 'package:flutter/material.dart';
import 'package:durt2/durt2.dart' show ConnectionStatus;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

class ConnectionProvider with ChangeNotifier {
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  late StreamSubscription<ConnectionStatus> _connectionStatusSubscription;
  late ProviderContainer _container;

  ConnectionProvider() {
    _container = ProviderContainer();
    final durt = _container.read(durtProvider);
    _connectionStatus = durt.connectionStatus;
    _connectionStatusSubscription = durt.connectionStatusStream.listen((status) {
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
    _container.dispose();
    super.dispose();
  }
}
