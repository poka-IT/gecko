import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/services/config_service.dart';

/// Service for managing default wallet names with `#` prefix convention.
///
/// Default names are stored as `#main`, `#2`, `#3`, `#legacy` etc.
/// They are translated dynamically at display time based on the current locale.
/// User-customized names are stored as plain text without the `#` prefix.
class WalletNameService {
  /// Default name for the main (root) wallet
  static String defaultMain() => '#main';

  /// Default name for the Nth wallet (2, 3, ...)
  static String defaultN(int n) => '#$n';

  /// Default name for legacy (v1) wallets
  static String defaultLegacy() => '#legacy';

  /// Check if a wallet name is a default (starts with `#`)
  static bool isDefault(String? name) => name != null && name.startsWith('#');

  /// Translate a wallet name for display.
  ///
  /// If the name starts with `#`, it is a default name and gets translated
  /// to the current locale. Otherwise, it is returned as-is.
  static String displayName(String? name) {
    if (name == null || name.isEmpty) return '';
    if (!name.startsWith('#')) return name;

    final key = name.substring(1); // Remove '#'

    if (key == 'main') {
      return 'walletNameMain'.tr();
    }
    if (key == 'legacy') {
      return 'walletNameLegacy'.tr();
    }

    // Try to parse as number: #2, #3, etc.
    final number = int.tryParse(key);
    if (number != null) {
      return 'walletNameN'.tr(args: ['$number']);
    }

    // Unknown default key, return as-is without '#'
    return key;
  }

  /// Check if a user-entered name uses the reserved `#` prefix
  static bool isReservedPrefix(String name) => name.startsWith('#');

  /// Known default names in all supported languages, used for migration.
  static final Set<String> _knownDefaults = {
    // FR
    'Mon portefeuille racine',
    'Mon portefeuille courant',
    'Portefeuille racine',
    'Portefeuille Obsolète',
    // EN
    'My root wallet',
    'My current wallet',
    'Root Wallet',
    'Root wallet',
    'Obsolete Wallet',
    'Legacy Wallet',
    'Legacy wallet',
    // ES
    'Mi billetera raíz',
    'Mi billetera actual',
    'Billetera raíz',
    'Billetera obsoleta',
    // IT
    'Il mio portafoglio radice',
    'Il mio portafoglio attuale',
    'Portafoglio radice',
    'Portafoglio Obsoleto',
    // DE
    'Mein Stammportemonnaie',
    'Mein aktuelles Portemonnaie',
    'Stammportemonnaie',
    'Veraltetes Portemonnaie',
  };

  /// Regex patterns for "Wallet N" / "Portefeuille N" etc. in all languages
  static final List<RegExp> _walletNPatterns = [
    RegExp(r'^Portefeuille (\d+)$'), // FR
    RegExp(r'^Wallet (\d+)$'), // EN
    RegExp(r'^Billetera (\d+)$'), // ES
    RegExp(r'^Portafoglio (\d+)$'), // IT
    RegExp(r'^Portemonnaie (\d+)$'), // DE
    RegExp(r'^Brieftasche (\d+)$'), // DE alt
  ];

  /// Migrate an old wallet name to the new `#` convention.
  ///
  /// Returns the migrated name if it matches a known default, or null if
  /// the name is custom and should not be changed.
  static String? migrateNameIfDefault(String? name) {
    if (name == null || name.isEmpty) return defaultMain();
    if (name.startsWith('#')) return null; // Already migrated

    // Check exact matches against known defaults
    if (_knownDefaults.contains(name)) {
      // Distinguish main/legacy
      final lower = name.toLowerCase();
      if (lower.contains('legacy') ||
          lower.contains('obsolet') ||
          lower.contains('obsolè') ||
          lower.contains('veraltet')) {
        return defaultLegacy();
      }
      return defaultMain();
    }

    // Check "Wallet N" patterns
    for (final pattern in _walletNPatterns) {
      final match = pattern.firstMatch(name);
      if (match != null) {
        final n = int.tryParse(match.group(1)!);
        if (n != null) return defaultN(n);
      }
    }

    return null; // Custom name, don't migrate
  }

  /// One-shot migration of existing wallet and safe names.
  ///
  /// Converts old translated names to the new `#` convention.
  /// Stores a flag in configBox to avoid re-execution.
  static void runMigration() {
    final config = ConfigService(configBox);
    if (config.walletNameMigrationDone) return;

    final walletService = Durt.i.wallets;
    final wallets = walletService.walletBox.getAll();

    for (final wallet in wallets) {
      final migrated = migrateNameIfDefault(wallet.name);
      if (migrated != null) {
        wallet.name = migrated;
        walletService.walletBox.put(wallet);
      }
    }

    // Also migrate safe names
    final safes = walletService.safeBox.getAll();
    for (final safe in safes) {
      final migrated = migrateNameIfDefault(safe.name);
      if (migrated != null) {
        safe.name = migrated;
        walletService.safeBox.put(safe);
      }
    }

    config.walletNameMigrationDone = true;
  }
}
