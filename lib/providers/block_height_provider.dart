import 'dart:ui';

import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';

/// Provides the current block height from the connected Duniter node.
///
/// Returns 0 when disconnected, and updates reactively when connected.
/// The provider automatically handles connection status changes and starts/stops
/// listening to block height updates accordingly.
final blockHeightProvider = NotifierProvider<BlockHeightNotifier, int>(BlockHeightNotifier.new);

/// Notifier that manages block height state and connection status changes
class BlockHeightNotifier extends Notifier<int> {
  VoidCallback? _currentListener;

  @override
  int build() {
    _init();
    // Try to get initial block height if already connected
    return _getInitialBlockHeight();
  }

  int _getInitialBlockHeight() {
    try {
      final status = ref.read(duniterConnectionStatusProvider);
      if (status == d.ConnectionStatus.connected) {
        final storageService = ref.read(storageServiceProvider);
        return storageService.blockHeightNotifier.value;
      }
    } catch (e) {
      // Ignore errors during initialization
    }
    return 0;
  }

  void _init() {
    // Watch connection status using the stream-based provider
    ref.listen(duniterConnectionStatusProvider, (previous, next) {
      _handleConnectionStatusChange(next);
    });

    // Initialize with current connection status
    final currentStatus = ref.read(duniterConnectionStatusProvider);
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

      // Remove previous listener if any
      if (_currentListener != null) {
        blockHeightNotifier.removeListener(_currentListener!);
      }

      // Set initial value
      state = blockHeightNotifier.value;

      // Listen to changes
      _currentListener = () {
        state = blockHeightNotifier.value;
      };
      blockHeightNotifier.addListener(_currentListener!);

      // Clean up listener when disposed
      ref.onDispose(() {
        if (_currentListener != null) {
          blockHeightNotifier.removeListener(_currentListener!);
          _currentListener = null;
        }
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
