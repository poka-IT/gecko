import 'dart:async';
import 'package:durt2/durt2.dart';
import 'package:flutter/foundation.dart';

class BlockHeightProvider with ChangeNotifier {
  ValueListenable<int>? _blockHeightNotifier;
  StreamSubscription<ConnectionStatus>? _connectionStatusSubscription;

  BlockHeightProvider() {
    _checkAndStartListening();
    _connectionStatusSubscription = Durt.i.connectionStatusStream.listen((_) {
      _checkAndStartListening();
    });
  }

  int get blockHeight => _blockHeightNotifier?.value ?? 0;

  void _checkAndStartListening() {
    final isConnected = Durt.i.connectionStatus == ConnectionStatus.connected;

    if (isConnected && _blockHeightNotifier == null) {
      // Start listening
      _blockHeightNotifier = Durt.i.storage.blockHeightNotifier;
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
    super.dispose();
  }
}
