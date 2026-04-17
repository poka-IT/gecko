import 'dart:io';
import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/storage_init_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      final storedValue = configBox.getValue(_storageKey, defaultValue: 'true');
      return storedValue == 'true';
    } catch (e) {
      log.e('Error loading UD toggle state: $e');
      return true;
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

/// Provider for managing the home background image visibility setting.
final backgroundImageProvider = NotifierProvider<BackgroundImageNotifier, bool>(BackgroundImageNotifier.new);

/// Notifier for the background image toggle.
class BackgroundImageNotifier extends Notifier<bool> {
  static const String _storageKey = 'showBackgroundImage';

  @override
  bool build() {
    try {
      final configBox = ref.read(configBoxProvider);
      final storedValue = configBox.getValue(_storageKey, defaultValue: 'true');
      return storedValue == 'true';
    } catch (e) {
      return true;
    }
  }

  void toggle() {
    state = !state;
    try {
      final configBox = ref.read(configBoxProvider);
      configBox.putValue(_storageKey, state.toString());
    } catch (e) {
      log.e('Error saving background image setting: $e');
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

      // Clear Riverpod persistent cache (SQLite)
      await _clearRiverpodPersistCache();

      // Clear Squid and Duniter endpoint caches
      await _clearEndpointCaches();

      log.i('✅ All caches cleared successfully');
    } catch (e) {
      log.e('❌ Error clearing caches: $e');
      rethrow;
    }
  }

  /// Clear Riverpod persistent SQLite cache (transaction history, certifications, etc.)
  Future<void> _clearRiverpodPersistCache() async {
    try {
      // On Linux/Windows, sqflite is not available — no persistent cache to clear
      if (Platform.isLinux || Platform.isWindows) {
        log.d('Riverpod SQLite cache: not persistent on this platform, skip clear');
        return;
      }

      // On macOS desktop, use ~/.gecko/cache/riverpod.db
      // On mobile, use the platform default database path
      final desktopPath = await StorageInitService().desktopRiverpodCachePath();
      final dbPath = desktopPath ?? join(await getDatabasesPath(), 'gecko_riverpod_cache.db');

      final db = await openDatabase(dbPath);
      await db.delete('riverpod');
      await db.close();
      log.d('Cleared Riverpod persist cache');
    } catch (e) {
      log.w('Error clearing Riverpod persist cache: $e');
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
