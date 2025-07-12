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
  return UniversalDividendsToggleNotifier(ref);
});

/// StateNotifier for managing the global Universal Dividends toggle state
class UniversalDividendsToggleNotifier extends StateNotifier<bool> {
  static const String _storageKey = 'include_universal_dividends_global';
  final Ref ref;

  UniversalDividendsToggleNotifier(this.ref) : super(false) {
    _loadFromStorage();
  }

  /// Load the toggle state from storage
  void _loadFromStorage() {
    try {
      final durt = ref.read(durtProvider);
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

  /// Set the Universal Dividends state
  void setIncludeUniversalDividends(bool include) {
    if (state != include) {
      state = include;
      _saveToStorage();
    }
  }

  /// Save the toggle state to storage
  void _saveToStorage() {
    try {
      final durt = ref.read(durtProvider);
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

  /// Clear only endpoint caches (Squid and Duniter RPC)
  Future<void> clearEndpointCaches() async {
    try {
      log.i('🧹 Clearing endpoint caches...');
      await _clearEndpointCaches();
      log.i('✅ Endpoint caches cleared successfully');
      reload();
    } catch (e) {
      log.e('❌ Error clearing endpoint caches: $e');
      rethrow;
    }
  }

  /// Private method to clear all endpoint caches
  Future<void> _clearEndpointCaches() async {
    final durt = _container.read(durtProvider);
    final networks = ['gdev', 'gtest', 'g1'];

    for (final network in networks) {
      // Clear new fast endpoint caches
      await _clearConfigEntry(durt, 'fast_endpoints_rpc_$network');
      await _clearConfigEntry(durt, 'fast_endpoints_squid_$network');
    }

    log.d('Cleared all legacy and new endpoint caches');
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

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    try {
      final rpcCount = Networks.listDuniterEndpoints.length;
      final squidCount = Networks.listSquidEndpoints.length;

      return {
        'discoveredRpcEndpoints': rpcCount,
        'discoveredSquidEndpoints': squidCount,
        'status': 'Cache stats retrieved successfully (no caching)',
      };
    } catch (e) {
      log.e('Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }
}
