import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';

/// Provider for managing Universal Dividends toggle state with persistent storage.
///
/// This provider handles the global toggle state for including Universal Dividends
/// in calculations and persists the state using Durt's config storage.
final universalDividendsToggleProvider = NotifierProvider<UniversalDividendsToggleNotifier, bool>(
  UniversalDividendsToggleNotifier.new,
);

/// Notifier for managing the global Universal Dividends toggle state.
///
/// Automatically loads the state from storage on initialization and saves
/// changes back to storage when the toggle is modified.
class UniversalDividendsToggleNotifier extends Notifier<bool> {
  static const String _storageKey = 'include_universal_dividends_global';

  @override
  bool build() {
    return _loadFromStorage();
  }

  /// Load the toggle state from persistent storage
  bool _loadFromStorage() {
    try {
      final configBox = ref.read(configBoxProvider);
      final storedValue = configBox.getValue(_storageKey, defaultValue: 'false');
      return storedValue == 'true';
    } catch (e) {
      log.e('Error loading UD toggle state: $e');
      return false;
    }
  }

  /// Toggle the Universal Dividends state and persist to storage
  void toggle() {
    final newState = !state;
    state = newState;
    _saveToStorage();
  }

  /// Save the current toggle state to persistent storage
  void _saveToStorage() {
    try {
      final configBox = ref.read(configBoxProvider);
      configBox.putValue(_storageKey, state.toString());
    } catch (e) {
      log.e('Error saving UD toggle state: $e');
    }
  }
}

/// Provider for settings-related operations like cache management.
///
/// This provider offers functionality to clear various application caches
/// including endpoints, wallets, and transaction data.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref);
});

/// Service class for managing application settings and cache operations.
///
/// Provides methods to clear different types of caches and manage
/// application-wide settings that don't require reactive state.
class SettingsService {
  final Ref _ref;

  SettingsService(this._ref);

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
    } catch (e) {
      log.e('❌ Error clearing caches: $e');
      rethrow;
    }
  }

  /// Private method to clear all endpoint caches
  Future<void> _clearEndpointCaches() async {
    final durt = _ref.read(durtProvider);
    final networks = ['gdev', 'gtest', 'g1'];

    // 1. Clear ConnectionManager fast endpoint caches (ObjectBox)
    for (final network in networks) {
      await _clearConfigEntry(durt, 'fast_endpoints_rpc_$network');
      await _clearConfigEntry(durt, 'fast_endpoints_squid_$network');
    }
    log.d('✅ Cleared ConnectionManager fast endpoint caches');

    // 2. Clear BootstrapNodeService cache (ObjectBox)
    try {
      final bootstrapBox = durt.store.box<d.BootstrapEndpoint>();
      bootstrapBox.removeAll();
      log.d('✅ Cleared BootstrapNodeService ObjectBox cache');
    } catch (e) {
      log.w('⚠️ Error clearing BootstrapNodeService cache: $e');
    }

    // 3. Clear NetworkConfigService memory cache
    try {
      d.NetworkConfigService.clearCache();
      log.d('✅ Cleared NetworkConfigService memory cache');
    } catch (e) {
      log.w('⚠️ Error clearing NetworkConfigService cache: $e');
    }

    // 4. Clear static Networks lists
    d.Networks.listDuniterEndpoints.clear();
    d.Networks.listSquidEndpoints.clear();
    log.d('✅ Cleared static Networks endpoint lists');

    log.i('🧹 All endpoint caches cleared successfully');
  }

  /// Private method to clear a specific config entry
  Future<void> _clearConfigEntry(d.Durt durt, String cacheKey) async {
    final query = durt.configBox.query(Config_.key.equals(cacheKey)).build();
    final config = query.findFirst();
    query.close();

    if (config != null) {
      durt.configBox.remove(config.id);
      log.d('Cleared cache entry: $cacheKey');
    }
  }
}
