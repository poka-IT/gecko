// ignore_for_file: avoid_print

import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/providers.dart';

/// Connection status notifier that listens to both Duniter and Squid streams
class ConnectionStatusNotifier extends Notifier<d.ConnectionStatus> {
  StreamSubscription<d.ConnectionStatus>? _duniterSubscription;
  StreamSubscription<d.ConnectionStatus>? _squidSubscription;

  d.ConnectionStatus _duniterStatus = d.ConnectionStatus.disconnected;
  d.ConnectionStatus _squidStatus = d.ConnectionStatus.disconnected;

  @override
  d.ConnectionStatus build() {
    ref.onDispose(() {
      _duniterSubscription?.cancel();
      _squidSubscription?.cancel();
    });

    // Get initial state synchronously
    final initialState = _getInitialState();

    // Defer stream subscriptions to avoid modifying other providers during build
    Future.microtask(() => _subscribeToStreams());

    return initialState;
  }

  d.ConnectionStatus _getInitialState() {
    try {
      final durt = d.Durt.i;
      _duniterStatus = durt.duniterConnectionStatus;
      _squidStatus = durt.squidConnectionStatus;
      return _computeCombinedStatus();
    } catch (e) {
      return d.ConnectionStatus.disconnected;
    }
  }

  void _subscribeToStreams() {
    try {
      final durt = d.Durt.i;

      // Listen to Duniter connection status
      _duniterSubscription = durt.duniterConnectionStatusStream.listen((status) {
        final previousStatus = _duniterStatus;
        _duniterStatus = status;

        // Invalidate balance providers when going from offline to online
        if (previousStatus != d.ConnectionStatus.connected && status == d.ConnectionStatus.connected) {
          ref.invalidate(persistentBalanceStreamProvider);
          ref.invalidate(balanceStreamProvider);
          ref.invalidate(persistentIdtyStatusStreamProvider);
          ref.invalidate(persistentCertificationStreamProvider);
          ref.invalidate(hybridIdtyStatusProvider);
          ref.invalidate(hybridCertificationProvider);

          // Invalidate genesisTimeProvider to force recalculation after reconnection
          // This ensures genesisTime is recalculated with the current network connection
          // and prevents incorrect date calculations (e.g., certification expiration dates)
          ref.invalidate(genesisTimeProvider);
        }

        // Update home message based on Duniter status
        final homeMessageNotifier = ref.read(homeMessageProvider.notifier);
        switch (status) {
          case d.ConnectionStatus.connecting:
            homeMessageNotifier.changeMessage("connecting".tr());
            break;
          case d.ConnectionStatus.connected:
            homeMessageNotifier.changeMessage("connected".tr(args: [durt.network.displayName]), true);
            break;
          case d.ConnectionStatus.error:
            homeMessageNotifier.changeMessage("networkGenesisError".tr());
            break;
          case d.ConnectionStatus.disconnected:
            homeMessageNotifier.changeMessage("networkConnectionError".tr());
            break;
        }

        _updateCombinedStatus();
      });

      // Listen to Squid connection status
      _squidSubscription = durt.squidConnectionStatusStream.listen((status) {
        _squidStatus = status;

        final homeMessageNotifier = ref.read(homeMessageProvider.notifier);
        switch (status) {
          case d.ConnectionStatus.connected:
            // Clear any previous Squid error message
            if (_duniterStatus == d.ConnectionStatus.connected) {
              homeMessageNotifier.changeMessage("connected".tr(args: [durt.network.displayName]), true);
            }
            break;
          case d.ConnectionStatus.disconnected:
            homeMessageNotifier.changeMessage("noValidIndexerFound".tr());
            break;
          case d.ConnectionStatus.error:
            homeMessageNotifier.changeMessage("indexerError".tr());
            break;
          case d.ConnectionStatus.connecting:
            break;
        }

        _updateCombinedStatus();
      });
    } catch (e) {
      state = d.ConnectionStatus.error;
      ref.read(homeMessageProvider.notifier).changeMessage("networkConnectionError".tr());
    }
  }

  d.ConnectionStatus _computeCombinedStatus() {
    // Priority order: connected > connecting > error > disconnected
    // We consider the app connected if either Duniter OR Squid is connected
    // We consider the app in error state if either has an error (genesis validation, etc.)

    if (_duniterStatus == d.ConnectionStatus.connected || _squidStatus == d.ConnectionStatus.connected) {
      return d.ConnectionStatus.connected;
    } else if (_duniterStatus == d.ConnectionStatus.error || _squidStatus == d.ConnectionStatus.error) {
      return d.ConnectionStatus.error;
    } else if (_duniterStatus == d.ConnectionStatus.connecting || _squidStatus == d.ConnectionStatus.connecting) {
      return d.ConnectionStatus.connecting;
    } else {
      return d.ConnectionStatus.disconnected;
    }
  }

  void _updateCombinedStatus() {
    final newStatus = _computeCombinedStatus();
    if (newStatus != state) {
      state = newStatus;
    }
  }

  /// Note: Stream reinitialization is no longer needed due to proxy streams
}

/// Connection status notifier for Duniter only
class DuniterConnectionStatusNotifier extends Notifier<d.ConnectionStatus> {
  StreamSubscription<d.ConnectionStatus>? _subscription;

  @override
  d.ConnectionStatus build() {
    ref.onDispose(() => _subscription?.cancel());

    // Get initial state synchronously
    final initialState = _getInitialState();

    // Defer stream subscription to avoid modifying state during build
    Future.microtask(() => _subscribeToStream());

    return initialState;
  }

  d.ConnectionStatus _getInitialState() {
    try {
      return d.Durt.i.duniterConnectionStatus;
    } catch (e) {
      return d.ConnectionStatus.disconnected;
    }
  }

  void _subscribeToStream() {
    try {
      _subscription = d.Durt.i.duniterConnectionStatusStream.listen((status) {
        state = status;
      });
    } catch (e) {
      // Ignore subscription errors
    }
  }
}

/// Connection status notifier for Squid only
class SquidConnectionStatusNotifier extends Notifier<d.ConnectionStatus> {
  StreamSubscription<d.ConnectionStatus>? _subscription;

  @override
  d.ConnectionStatus build() {
    ref.onDispose(() => _subscription?.cancel());

    // Get initial state synchronously
    final initialState = _getInitialState();

    // Defer stream subscription to avoid modifying state during build
    Future.microtask(() => _subscribeToStream());

    return initialState;
  }

  d.ConnectionStatus _getInitialState() {
    try {
      return d.Durt.i.squidConnectionStatus;
    } catch (e) {
      return d.ConnectionStatus.disconnected;
    }
  }

  void _subscribeToStream() {
    try {
      _subscription = d.Durt.i.squidConnectionStatusStream.listen((status) {
        state = status;
      });
    } catch (e) {
      // Ignore subscription errors
    }
  }
}

/// Combined connection status provider (default)
final connectionStatusProvider = NotifierProvider<ConnectionStatusNotifier, d.ConnectionStatus>(
  ConnectionStatusNotifier.new,
);

/// Duniter-only connection status provider
final duniterConnectionStatusProvider = NotifierProvider<DuniterConnectionStatusNotifier, d.ConnectionStatus>(
  DuniterConnectionStatusNotifier.new,
);

/// Squid-only connection status provider
final squidConnectionStatusProvider = NotifierProvider<SquidConnectionStatusNotifier, d.ConnectionStatus>(
  SquidConnectionStatusNotifier.new,
);

/// Provides the current Squid endpoint as a string.
/// This can be used to rebuild widgets when the endpoint changes.
final squidEndpointProvider = Provider<String>((ref) {
  return d.Networks.squidEndpoint;
});

/// Notifier for Squid loading state
class SquidLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Provides loading state for Squid endpoint operations.
final squidLoadingProvider = NotifierProvider<SquidLoadingNotifier, bool>(SquidLoadingNotifier.new);

/// Storage state enum
enum StorageState {
  notInitialized, // Avant Durt.init() ou storage non prêt
  offlineMode, // Storage avec constantes par défaut
  onlineMode, // Storage connecté à la blockchain
}

/// Storage state notifier using durt2 streams
class StorageStateNotifier extends Notifier<StorageState> {
  StreamSubscription<d.ConnectionStatus>? _subscription;

  @override
  StorageState build() {
    ref.onDispose(() => _subscription?.cancel());

    // Get initial state synchronously
    final initialState = _getInitialState();

    // Defer stream subscription to avoid modifying other providers during build
    Future.microtask(() => _subscribeToStream());

    return initialState;
  }

  StorageState _getInitialState() {
    try {
      final durt = d.Durt.i;
      if (durt.duniterConnectionStatus == d.ConnectionStatus.connected) {
        return StorageState.onlineMode;
      } else if (durt.isStorageOfflineMode) {
        return StorageState.offlineMode;
      } else {
        return StorageState.notInitialized;
      }
    } catch (e) {
      return StorageState.notInitialized;
    }
  }

  void _subscribeToStream() {
    try {
      final durt = d.Durt.i;
      _subscription = durt.duniterConnectionStatusStream.listen((_) {
        _updateState(durt);
      });
    } catch (e) {
      // Ignore subscription errors
    }
  }

  void _updateState(d.Durt durt) {
    try {
      if (durt.duniterConnectionStatus == d.ConnectionStatus.connected) {
        state = StorageState.onlineMode;
      } else if (durt.isStorageOfflineMode) {
        state = StorageState.offlineMode;
      } else {
        state = StorageState.notInitialized;
      }
    } catch (e) {
      // Storage might not be initialized yet
      state = StorageState.notInitialized;
    }
  }
}

/// Storage state provider using durt2 streams
final storageStateProvider = NotifierProvider<StorageStateNotifier, StorageState>(StorageStateNotifier.new);

/// Provides a method to test a Squid endpoint and update loading state.
final squidEndpointTesterProvider = Provider<Future<bool> Function(String)>((ref) {
  return (String endpoint) async {
    // Set loading state
    ref.read(squidLoadingProvider.notifier).set(true);

    try {
      // Ensure the endpoint has the correct format with path
      String testEndpoint = endpoint;

      // If the endpoint doesn't have a path, add the default /v1/graphql path
      if (!testEndpoint.contains('/v1/graphql')) {
        if (testEndpoint.startsWith('wss://') || testEndpoint.startsWith('ws://')) {
          testEndpoint = '$testEndpoint/v1/graphql';
        } else if (testEndpoint.startsWith('https://') || testEndpoint.startsWith('http://')) {
          testEndpoint = '$testEndpoint/v1/graphql';
        } else {
          // Add protocol and path
          testEndpoint = 'wss://$testEndpoint/v1/graphql';
        }
      }

      // Test the endpoint
      final result = await d.SquidService.testEndpoint(testEndpoint);
      return result;
    } finally {
      // Clear loading state
      ref.read(squidLoadingProvider.notifier).set(false);
    }
  };
});
