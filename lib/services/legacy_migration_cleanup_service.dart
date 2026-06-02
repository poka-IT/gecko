import 'package:durt2/durt2.dart' show SafeType, WalletEntity, WalletService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';

/// Cleanup helper shared by every Cesium-v1 → v2 migration flow.
///
/// When a user previously imported their Cesium v1 account (id + password),
/// Gecko stores it as a dedicated [SafeType.legacy] safe whose wallet address
/// is the v2-derived address of that account. After migrating that account to
/// v2 (which empties it via `transferAll`), the legacy safe stays behind as an
/// orphan holding 0 Ğ1 — and, because safes are listed by number, the user can
/// land on this empty coffer instead of the migrated wallet when entering their
/// PIN. This service removes that orphan legacy safe and re-points the default
/// safe to the migrated wallet.
class LegacyMigrationCleanupService {
  /// Removes the now-empty legacy safe that was imported for the migrated
  /// account (if any) and re-points the default safe to the target wallet.
  ///
  /// [migratedFromAddress] is the v2-derived address the migration drained
  /// (i.e. `flowState.v2Address`). [targetAddress] is the wallet that received
  /// the funds/identity. Both lookups are best-effort: when the legacy account
  /// was never imported as a safe, there is simply nothing to remove.
  static Future<void> cleanupOrphanLegacySafe({
    required ProviderContainer container,
    required WalletService walletService,
    required String migratedFromAddress,
    required String targetAddress,
  }) async {
    try {
      final legacyWallet = _tryGetWallet(walletService, migratedFromAddress);
      final legacySafe = legacyWallet?.safe.target;

      // Nothing imported for this account → nothing to clean up.
      if (legacySafe == null) return;

      // Safety: only ever delete an actual legacy-type safe, never a regular
      // mnemonic safe that happens to share the address.
      if (legacySafe.safeType != SafeType.legacy) return;

      // Resolve the target wallet's safe so we can keep it as the active one.
      final targetSafe = _tryGetWallet(walletService, targetAddress)?.safe.target;

      // Safety: never delete the safe that received the migration.
      if (targetSafe != null && legacySafe.number == targetSafe.number) return;

      await walletService.deleteSafe(legacySafe.number);
      log.i('[LegacyCleanup] Orphan legacy safe ${legacySafe.number} deleted after migration');

      // Re-point the default safe to the migrated wallet so the user no longer
      // lands on the emptied legacy coffer when unlocking.
      final newDefault = targetSafe?.number;
      if (newDefault != null) {
        container.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(newDefault);
        await container.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: newDefault);
      } else {
        await container.read(walletsListProvider.notifier).loadWallets();
      }
    } catch (e) {
      log.e('[LegacyCleanup] Failed to remove orphan legacy safe after migration: $e');
    }
  }

  /// [WalletService.getWalletData] throws when the address is unknown; this
  /// wrapper turns that into a null so callers can branch cleanly.
  static WalletEntity? _tryGetWallet(WalletService walletService, String address) {
    try {
      return walletService.getWalletData(address);
    } catch (_) {
      return null;
    }
  }
}
