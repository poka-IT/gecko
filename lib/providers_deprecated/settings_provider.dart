import 'package:flutter/material.dart';
import 'package:durt2/durt2.dart';
import 'package:durt2/objectbox.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';

// Helper to access Riverpod services
final _container = ProviderContainer();

/// Global provider for Universal Dividends toggle state
final universalDividendsToggleProvider = StateNotifierProvider<UniversalDividendsToggleNotifier, bool>((ref) {
  return UniversalDividendsToggleNotifier();
});

/// StateNotifier for managing the global Universal Dividends toggle state
class UniversalDividendsToggleNotifier extends StateNotifier<bool> {
  static const String _storageKey = 'include_universal_dividends_global';

  UniversalDividendsToggleNotifier() : super(false) {
    _loadFromStorage();
  }

  /// Load the toggle state from storage
  void _loadFromStorage() {
    try {
      final durt = _container.read(durtProvider);
      final storedValue = durt.configBox.getValue(_storageKey, defaultValue: 'false');
      state = storedValue == 'true';
    } catch (e) {
      log.e('Error loading UD toggle state: $e');
      state = false;
    }
  }

  /// Toggle the Universal Dividends state
  void toggle() {
    final newState = !state;
    state = newState;
    _saveToStorage();
  }

  /// Save the toggle state to storage
  void _saveToStorage() {
    try {
      final durt = _container.read(durtProvider);
      durt.configBox.putValue(_storageKey, state.toString());
    } catch (e) {
      log.e('Error saving UD toggle state: $e');
    }
  }
}

class SettingsProvider with ChangeNotifier {
  void reload() {
    notifyListeners();
  }

  /// Clear all application caches including endpoints, wallets, and transaction data
  Future<void> clearAllCaches() async {
    try {
      log.i('🧹 Starting cache cleanup...');

      // Clear WalletHeaderData cache
      await walletHeaderDataBox.clear();
      log.d('Cleared WalletHeaderData cache');

      // Clear G1WalletsList cache
      await g1WalletsBox.clear();
      log.d('Cleared G1WalletsList cache');

      // Clear transaction status cache (handled by app restart)
      log.d('Transaction status cache will be cleared on app restart');

      // Clear Squid and Duniter endpoint caches
      await _clearEndpointCaches();

      log.i('✅ All caches cleared successfully');
      reload(); // Notify listeners that caches have been cleared
    } catch (e) {
      log.e('❌ Error clearing caches: $e');
      rethrow;
    }
  }

  /// Private method to clear all endpoint caches
  Future<void> _clearEndpointCaches() async {
    final durt = _container.read(durtProvider);
    final networks = ['gdev', 'gtest', 'g1'];

    // 1. Clear ConnectionManager fast endpoint caches (ObjectBox)
    for (final network in networks) {
      await _clearConfigEntry(durt, 'fast_endpoints_rpc_$network');
      await _clearConfigEntry(durt, 'fast_endpoints_squid_$network');
    }
    log.d('✅ Cleared ConnectionManager fast endpoint caches');

    // 2. Clear BootstrapNodeService cache (ObjectBox)
    try {
      final bootstrapBox = durt.store.box<BootstrapEndpoint>();
      bootstrapBox.removeAll();
      log.d('✅ Cleared BootstrapNodeService ObjectBox cache');
    } catch (e) {
      log.w('⚠️ Error clearing BootstrapNodeService cache: $e');
    }

    // 3. Clear NetworkConfigService memory cache
    try {
      NetworkConfigService.clearCache();
      log.d('✅ Cleared NetworkConfigService memory cache');
    } catch (e) {
      log.w('⚠️ Error clearing NetworkConfigService cache: $e');
    }

    // 4. Clear static Networks lists
    Networks.listDuniterEndpoints.clear();
    Networks.listSquidEndpoints.clear();
    log.d('✅ Cleared static Networks endpoint lists');

    log.i('🧹 All endpoint caches cleared successfully');
  }

  /// Private method to clear a specific config entry
  Future<void> _clearConfigEntry(Durt durt, String cacheKey) async {
    final query = durt.configBox.query(Config_.key.equals(cacheKey)).build();
    final config = query.findFirst();
    query.close();

    if (config != null) {
      durt.configBox.remove(config.id);
      log.d('Cleared cache entry: $cacheKey');
    }
  }
}
