import 'package:durt2/durt2.dart';
import 'package:flutter/foundation.dart';

class BlockHeightProvider with ChangeNotifier {
  late ValueListenable<int> _blockHeightNotifier;

  BlockHeightProvider() {
    _blockHeightNotifier = Durt.i.storage.blockHeightNotifier;
    _blockHeightNotifier.addListener(_onBlockHeightChanged);
  }

  int get blockHeight => _blockHeightNotifier.value;

  void _onBlockHeightChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _blockHeightNotifier.removeListener(_onBlockHeightChanged);
    super.dispose();
  }
}
