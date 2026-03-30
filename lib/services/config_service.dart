import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Typed wrapper around the global Hive [configBox].
///
/// Provides domain-grouped, type-safe accessors for every key stored in
/// `configBox`. The underlying box remains `Box<dynamic>` and is not changed.
/// This is a pure abstraction layer: reads and writes go through typed methods
/// but the stored data format is identical.
class ConfigService {
  final Box _box;

  ConfigService(this._box);

  // ---------------------------------------------------------------------------
  // Window (desktop)
  // ---------------------------------------------------------------------------

  /// Persisted window width (set on resize).
  double? get windowWidth => _box.get('windowWidth') as double?;
  set windowWidth(double? value) => _box.put('windowWidth', value);

  /// Persisted window height (set on resize).
  double? get windowHeight => _box.get('windowHeight') as double?;
  set windowHeight(double? value) => _box.put('windowHeight', value);

  /// Persisted window X position (set on move).
  double? get windowX => _box.get('windowX') as double?;
  set windowX(double? value) => _box.put('windowX', value);

  /// Persisted window Y position (set on move).
  double? get windowY => _box.get('windowY') as double?;
  set windowY(double? value) => _box.put('windowY', value);

  /// Whether the minimum window size constraint is bypassed.
  bool get bypassMinWindowSize => (_box.get('bypassMinWindowSize', defaultValue: false) as bool?) ?? false;
  set bypassMinWindowSize(bool value) => _box.put('bypassMinWindowSize', value);

  // ---------------------------------------------------------------------------
  // Desktop panels
  // ---------------------------------------------------------------------------

  /// Whether the contacts side-panel is open.
  bool get contactsPanelOpen => (_box.get('contactsPanelOpen', defaultValue: false) as bool?) ?? false;
  set contactsPanelOpen(bool value) => _box.put('contactsPanelOpen', value);

  /// Whether the activity side-panel is open.
  bool get activityPanelOpen => (_box.get('activityPanelOpen', defaultValue: true) as bool?) ?? true;
  set activityPanelOpen(bool value) => _box.put('activityPanelOpen', value);

  // ---------------------------------------------------------------------------
  // Contact ordering
  // ---------------------------------------------------------------------------

  /// Saved contact order (list of address strings).
  List<String> get contactOrder {
    final saved = _box.get('contactOrder');
    if (saved is List) return saved.cast<String>();
    return [];
  }

  set contactOrder(List<String> value) => _box.put('contactOrder', value);

  // ---------------------------------------------------------------------------
  // Network / endpoints
  // ---------------------------------------------------------------------------

  /// Persisted network name (e.g. 'g1', 'gdev', 'gtest').
  String? get selectedNetwork => _box.get('selectedNetwork') as String?;
  set selectedNetwork(String? value) => _box.put('selectedNetwork', value);

  /// Whether auto-endpoint discovery is enabled.
  bool? get autoEndpoint => _box.get('autoEndpoint') as bool?;
  set autoEndpoint(bool? value) => _box.put('autoEndpoint', value);

  /// Custom Duniter RPC endpoint (null when using auto).
  String? get customEndpoint => _box.get('customEndpoint') as String?;
  set customEndpoint(String? value) {
    if (value == null) {
      _box.delete('customEndpoint');
    } else {
      _box.put('customEndpoint', value);
    }
  }

  bool get hasCustomEndpoint => _box.containsKey('customEndpoint');

  /// Custom Squid/indexer endpoint (null when using auto).
  String? get customIndexer => _box.get('customIndexer') as String?;
  set customIndexer(String? value) {
    if (value == null) {
      _box.delete('customIndexer');
    } else {
      _box.put('customIndexer', value);
    }
  }

  bool get hasCustomIndexer => _box.containsKey('customIndexer');

  // ---------------------------------------------------------------------------
  // PIN security
  // ---------------------------------------------------------------------------

  /// Number of failed PIN attempts for the given safe.
  int getFailedAttempts(int safeNumber) {
    return (_box.get('pinFailedAttempts_$safeNumber') as int?) ?? 0;
  }

  Future<void> setFailedAttempts(int safeNumber, int value) {
    return _box.put('pinFailedAttempts_$safeNumber', value);
  }

  Future<void> deleteFailedAttempts(int safeNumber) {
    return _box.delete('pinFailedAttempts_$safeNumber');
  }

  /// Lockout-until timestamp (milliseconds since epoch) for the given safe.
  int? getLockoutUntil(int safeNumber) {
    return _box.get('pinLockoutUntil_$safeNumber') as int?;
  }

  Future<void> setLockoutUntil(int safeNumber, int millisSinceEpoch) {
    return _box.put('pinLockoutUntil_$safeNumber', millisSinceEpoch);
  }

  Future<void> deleteLockoutUntil(int safeNumber) {
    return _box.delete('pinLockoutUntil_$safeNumber');
  }

  /// Whether PIN caching is enabled.
  bool get isCacheChecked => (_box.get('isCacheChecked') as bool?) ?? false;
  set isCacheChecked(bool value) => _box.put('isCacheChecked', value);

  // ---------------------------------------------------------------------------
  // Currency display
  // ---------------------------------------------------------------------------

  /// Legacy UD-unit flag.
  bool get isUdUnit => (_box.get('isUdUnit') as bool?) ?? false;
  set isUdUnit(bool value) => _box.put('isUdUnit', value);

  /// Currency display mode string (e.g. 'g1', 'du', 'quantitative').
  String get currencyDisplayMode => (_box.get('currencyDisplayMode') as String?) ?? 'g1';
  set currencyDisplayMode(String value) => _box.put('currencyDisplayMode', value);

  // ---------------------------------------------------------------------------
  // Text scaling
  // ---------------------------------------------------------------------------

  /// Persisted text-scale factor.
  double? get textScaleValue => _box.get('textScaleValue') as double?;
  set textScaleValue(double? value) => _box.put('textScaleValue', value);

  // ---------------------------------------------------------------------------
  // Preferences / toggles
  // ---------------------------------------------------------------------------

  /// Expert-mode toggle.
  bool get expertMode => (_box.get('expertMode') as bool?) ?? false;
  set expertMode(bool value) => _box.put('expertMode', value);

  /// Sentry error-reporting toggle (defaults to true).
  bool get sentryEnabled => (_box.get('sentryEnabled') as bool?) ?? true;
  set sentryEnabled(bool value) => _box.put('sentryEnabled', value);

  /// Whether mnemonics should be generated in English regardless of locale.
  bool get generateMnemonicsInEnglish => (_box.get('generateMnemonicsInEnglish') as bool?) ?? false;
  set generateMnemonicsInEnglish(bool value) => _box.put('generateMnemonicsInEnglish', value);

  /// Locale override (null = system locale).
  String? get localeOverride => _box.get('localeOverride') as String?;
  set localeOverride(String? value) {
    if (value == null) {
      _box.delete('localeOverride');
    } else {
      _box.put('localeOverride', value);
    }
  }

  // ---------------------------------------------------------------------------
  // Data version / migrations
  // ---------------------------------------------------------------------------

  /// Current data schema version.
  int? get dataVersion => _box.get('dataVersion') as int?;
  set dataVersion(int? value) => _box.put('dataVersion', value);

  /// Current wallet-header-data schema version.
  int? get walletHeaderDataVersion => _box.get('walletHeaderDataVersion') as int?;
  set walletHeaderDataVersion(int? value) => _box.put('walletHeaderDataVersion', value);

  /// Delete the legacy `defaultWallet` key.
  Future<void> deleteDefaultWallet() => _box.delete('defaultWallet');

  /// Clear the entire config box (used during data-version reset).
  Future<int> clearAll() => _box.clear();

  /// Wallet-name migration flag.
  bool get walletNameMigrationDone => (_box.get('wallet_name_migration_v1', defaultValue: false) as bool?) ?? false;
  set walletNameMigrationDone(bool value) => _box.put('wallet_name_migration_v1', value);

  // ---------------------------------------------------------------------------
  // App update dismissal
  // ---------------------------------------------------------------------------

  /// Dismissed update version string (App Store).
  String? get updateDismissedVersion => _box.get('updateDismissedVersion') as String?;
  set updateDismissedVersion(String? value) => _box.put('updateDismissedVersion', value);

  /// Dismissed update build number (sideloaded / desktop).
  int? get updateDismissedBuildNumber => _box.get('updateDismissedBuildNumber') as int?;
  set updateDismissedBuildNumber(int? value) => _box.put('updateDismissedBuildNumber', value);

  // ---------------------------------------------------------------------------
  // One-time dialogs / tutorials
  // ---------------------------------------------------------------------------

  /// Whether the Cesium import info dialog has been shown.
  bool get cesiumImportInfoShown => (_box.get('cesiumImportInfoShown') as bool?) ?? false;
  set cesiumImportInfoShown(bool value) => _box.put('cesiumImportInfoShown', value);

  /// Whether the draggable-wallet tutorial has been shown (global, all safes).
  bool get showDraggableTutorial => (_box.get('showDraggableTutorial_global') as bool?) ?? true;
  set showDraggableTutorial(bool value) => _box.put('showDraggableTutorial_global', value);

  // ---------------------------------------------------------------------------
  // Scan derivations
  // ---------------------------------------------------------------------------

  /// Number of derivation paths to scan during migration.
  int get scanDerivations => (_box.get('scanDerivations') as int?) ?? 20;
  set scanDerivations(int value) => _box.put('scanDerivations', value);

  // ---------------------------------------------------------------------------
  // Diagnostic helpers (read-only)
  // ---------------------------------------------------------------------------

  /// Number of keys in the box.
  int get keyCount => _box.keys.length;

  /// Number of values in the box.
  int get valueCount => _box.values.length;

  /// Whether the box is open.
  bool get isOpen => _box.isOpen;
}

/// Riverpod provider for [ConfigService].
///
/// Wraps the global [configBox] Hive box with typed accessors.
final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService(configBox);
});
