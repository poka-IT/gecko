import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/currency_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/g1_genesis_service.dart';

/// Polls for the G1 genesis hash every 30s while connected to gtest.
/// When the hash becomes available, automatically switches to the G1 network.
class G1GenesisPollNotifier extends Notifier<void> {
  Timer? _pollTimer;

  @override
  void build() {
    ref.onDispose(() => _pollTimer?.cancel());
  }

  /// Start polling (called once from the home screen).
  /// Only polls while the current network is gtest.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  Future<void> _poll() async {
    // Only poll when on gtest
    if (ref.read(durtProvider).network != d.Networks.gtest) {
      _pollTimer?.cancel();
      return;
    }

    final available = await G1GenesisService.initializeAtStartup(configBox);
    if (!available) return;

    // Hash arrived — switch to G1 live
    _pollTimer?.cancel();
    await _switchToG1();
  }

  Future<void> _switchToG1() async {
    final durt = ref.read(durtProvider);
    if (durt.network == d.Networks.g1) return;

    try {
      // 1. Unsubscribe from current network
      if (durt.isConnected) {
        await ref.read(storageServiceProvider).unsubscribeFromCurrentBlockNumber();
        await ref.read(storageServiceProvider).unsubscribeFromUniversalDividend();
      }
      await walletHeaderDataBox.clear();
      await g1WalletsBox.clear();

      // 2. Clear endpoint config to force auto-discovery
      configBox.delete('customEndpoint');
      configBox.delete('customIndexer');
      configBox.put('autoEndpoint', true);

      // 3. Switch network in durt2
      await durt.switchNetwork(d.Networks.g1);
      configBox.put('selectedNetwork', d.Networks.g1.name);

      // 4. Reconnect
      await durt.connect(verbose: true);

      // 5. Invalidate providers (same as manual switch in settings)
      ref.invalidate(blockHeightProvider);
      ref.invalidate(currencyDataProvider);
      ref.invalidate(genesisTimeProvider);

      log.i('Auto-switched from gtest to G1 (genesis hash received)');
    } catch (e) {
      log.e('Failed to auto-switch to G1: $e');
    }
  }
}

final g1GenesisPollProvider = NotifierProvider<G1GenesisPollNotifier, void>(G1GenesisPollNotifier.new);
