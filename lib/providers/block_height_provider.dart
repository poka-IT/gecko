import 'dart:async';
import 'package:durt2/durt2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

class BlockHeightProvider with ChangeNotifier {
  late ProviderContainer _container;
  ValueListenable<int>? _blockHeightNotifier;
  StreamSubscription<ConnectionStatus>? _connectionStatusSubscription;

  BlockHeightProvider() {
    _container = ProviderContainer();
    _checkAndStartListening();
    _connectionStatusSubscription = _container.read(durtProvider).connectionStatusStream.listen((_) {
      _checkAndStartListening();
    });
  }

  int get blockHeight => _blockHeightNotifier?.value ?? 0;

  void _checkAndStartListening() {
    final isConnected = _container.read(durtProvider).connectionStatus == ConnectionStatus.connected;

    if (isConnected && _blockHeightNotifier == null) {
      // Start listening
      _blockHeightNotifier = _container.read(storageServiceProvider).blockHeightNotifier;
      _blockHeightNotifier!.addListener(_onBlockHeightChanged);
      notifyListeners();
    } else if (!isConnected && _blockHeightNotifier != null) {
      // Stop listening
      _blockHeightNotifier!.removeListener(_onBlockHeightChanged);
      _blockHeightNotifier = null;
      notifyListeners();
    }
  }

  void _onBlockHeightChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionStatusSubscription?.cancel();
    _blockHeightNotifier?.removeListener(_onBlockHeightChanged);
    _container.dispose();
    super.dispose();
  }
}
