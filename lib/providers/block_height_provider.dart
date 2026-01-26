import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';

/// Provides the current block height from the connected Duniter node.
///
/// Returns 0 when disconnected, and updates reactively when connected.
/// The provider automatically handles connection status changes and starts/stops
/// listening to block height updates accordingly.
final blockHeightProvider = NotifierProvider<BlockHeightNotifier, int>(BlockHeightNotifier.new);

/// Notifier that manages block height state and connection status changes
class BlockHeightNotifier extends Notifier<int> {
  @override
  int build() {
    _init();
    return 0;
  }

  void _init() {
    // Watch connection status and update accordingly
    ref.listen(durtConnectionStatusProvider, (previous, next) {
      _handleConnectionStatusChange(next);
    });

    // Initialize with current connection status
    final currentStatus = ref.read(durtConnectionStatusProvider);
    _handleConnectionStatusChange(currentStatus);
  }

  void _handleConnectionStatusChange(d.ConnectionStatus status) {
    if (status == d.ConnectionStatus.connected) {
      _startListening();
    } else {
      _stopListening();
    }
  }

  void _startListening() {
    try {
      final storageService = ref.read(storageServiceProvider);
      final blockHeightNotifier = storageService.blockHeightNotifier;

      // Set initial value
      state = blockHeightNotifier.value;

      // Listen to changes
      void listener() {
        state = blockHeightNotifier.value;
      }

      blockHeightNotifier.addListener(listener);

      // Clean up listener when disposed
      ref.onDispose(() {
        blockHeightNotifier.removeListener(listener);
      });
    } catch (e) {
      // If there's an error, set state to 0
      state = 0;
    }
  }

  void _stopListening() {
    state = 0;
  }

  /// Refresh the block height by reinitializing the provider
  void refresh() {
    _init();
  }
}

/// Provides the current Duniter connection status
final durtConnectionStatusProvider = Provider<d.ConnectionStatus>((ref) {
  final durt = ref.watch(durtProvider);
  return durt.duniterConnectionStatus;
});
