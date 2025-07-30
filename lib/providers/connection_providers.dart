// ignore_for_file: avoid_print

import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/home_providers.dart';

/// Connection status notifier that listens to both Duniter and Squid streams
class ConnectionStatusNotifier extends StateNotifier<d.ConnectionStatus> {
  final Ref _ref;
  StreamSubscription<d.ConnectionStatus>? _duniterSubscription;
  StreamSubscription<d.ConnectionStatus>? _squidSubscription;

  d.ConnectionStatus _duniterStatus = d.ConnectionStatus.disconnected;
  d.ConnectionStatus _squidStatus = d.ConnectionStatus.disconnected;

  ConnectionStatusNotifier(this._ref) : super(d.ConnectionStatus.disconnected) {
    _initializeStreams();
  }

  void _initializeStreams() {
    try {
      final durt = d.Durt.i;

      // Listen to Duniter connection status
      _duniterSubscription = durt.duniterConnectionStatusStream.listen((status) {
        _duniterStatus = status;

        // Update home message based on Duniter status
        final homeMessageNotifier = _ref.read(homeMessageProvider.notifier);
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

        final homeMessageNotifier = _ref.read(homeMessageProvider.notifier);
        switch (status) {
          case d.ConnectionStatus.connected:
            // homeMessageNotifier.changeMessage("nodeAndIndexerSynced".tr(), true);
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

      // Set initial states
      _duniterStatus = durt.duniterConnectionStatus;
      _squidStatus = durt.squidConnectionStatus;
      _updateCombinedStatus();
    } catch (e) {
      state = d.ConnectionStatus.error;
      _ref.read(homeMessageProvider.notifier).changeMessage("networkConnectionError".tr());
    }
  }

  void _updateCombinedStatus() {
    // Priority order: connected > connecting > error > disconnected
    // We consider the app connected if either Duniter OR Squid is connected
    // We consider the app in error state if either has an error (genesis validation, etc.)

    d.ConnectionStatus newStatus;

    if (_duniterStatus == d.ConnectionStatus.connected || _squidStatus == d.ConnectionStatus.connected) {
      newStatus = d.ConnectionStatus.connected;
    } else if (_duniterStatus == d.ConnectionStatus.error || _squidStatus == d.ConnectionStatus.error) {
      newStatus = d.ConnectionStatus.error;
    } else if (_duniterStatus == d.ConnectionStatus.connecting || _squidStatus == d.ConnectionStatus.connecting) {
      newStatus = d.ConnectionStatus.connecting;
    } else {
      newStatus = d.ConnectionStatus.disconnected;
    }

    if (newStatus != state) {
      state = newStatus;
    }
  }

  /// Note: Stream reinitialization is no longer needed due to proxy streams

  @override
  void dispose() {
    _duniterSubscription?.cancel();
    _squidSubscription?.cancel();
    super.dispose();
  }
}

/// Connection status notifier for Duniter only
class DuniterConnectionStatusNotifier extends StateNotifier<d.ConnectionStatus> {
  StreamSubscription<d.ConnectionStatus>? _subscription;

  DuniterConnectionStatusNotifier() : super(d.ConnectionStatus.disconnected) {
    _initializeStream();
  }

  void _initializeStream() {
    try {
      final durt = d.Durt.i;

      // Set initial state
      state = durt.duniterConnectionStatus;

      // Listen to stream
      _subscription = durt.duniterConnectionStatusStream.listen((status) {
        state = status;
      });
    } catch (e) {
      state = d.ConnectionStatus.disconnected;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Connection status notifier for Squid only
class SquidConnectionStatusNotifier extends StateNotifier<d.ConnectionStatus> {
  StreamSubscription<d.ConnectionStatus>? _subscription;

  SquidConnectionStatusNotifier() : super(d.ConnectionStatus.disconnected) {
    _initializeStream();
  }

  void _initializeStream() {
    try {
      final durt = d.Durt.i;

      // Set initial state
      state = durt.squidConnectionStatus;

      // Listen to stream
      _subscription = durt.squidConnectionStatusStream.listen((status) {
        state = status;
      });
    } catch (e) {
      state = d.ConnectionStatus.disconnected;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Combined connection status provider (default)
final connectionStatusProvider = StateNotifierProvider<ConnectionStatusNotifier, d.ConnectionStatus>((ref) {
  return ConnectionStatusNotifier(ref);
});

/// Duniter-only connection status provider
final duniterConnectionStatusProvider = StateNotifierProvider<DuniterConnectionStatusNotifier, d.ConnectionStatus>((
  ref,
) {
  return DuniterConnectionStatusNotifier();
});

/// Squid-only connection status provider
final squidConnectionStatusProvider = StateNotifierProvider<SquidConnectionStatusNotifier, d.ConnectionStatus>((ref) {
  return SquidConnectionStatusNotifier();
});

/// Provides the current Squid endpoint as a string.
/// This can be used to rebuild widgets when the endpoint changes.
final squidEndpointProvider = Provider<String>((ref) {
  return d.Networks.squidEndpoint;
});

/// Provides loading state for Squid endpoint operations.
final squidLoadingProvider = StateProvider<bool>((ref) => false);

/// Provides a method to test a Squid endpoint and update loading state.
final squidEndpointTesterProvider = Provider<Future<bool> Function(String)>((ref) {
  return (String endpoint) async {
    // Set loading state
    ref.read(squidLoadingProvider.notifier).state = true;

    try {
      // Ensure the endpoint has the correct format with path
      String testEndpoint = endpoint;

      // If the endpoint doesn't have a path, add the default v1beta1/relay path
      if (!testEndpoint.contains('/v1beta1/relay') && !testEndpoint.contains('/v1/graphql')) {
        if (testEndpoint.startsWith('wss://') || testEndpoint.startsWith('ws://')) {
          testEndpoint = '$testEndpoint/v1beta1/relay';
        } else if (testEndpoint.startsWith('https://') || testEndpoint.startsWith('http://')) {
          testEndpoint = '$testEndpoint/v1beta1/relay';
        } else {
          // Add protocol and path
          testEndpoint = 'wss://$testEndpoint/v1beta1/relay';
        }
      }

      // Test the endpoint
      final result = await d.SquidService.testEndpoint(testEndpoint);
      return result;
    } finally {
      // Clear loading state
      ref.read(squidLoadingProvider.notifier).state = false;
    }
  };
});
