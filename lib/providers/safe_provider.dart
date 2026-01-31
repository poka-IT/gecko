// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:durt2/durt2.dart' show SafeEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/certification_queue_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

/// Safe management operations provider
final safeManagerProvider = Provider<SafeManager>((ref) {
  return SafeManager(ref);
});

/// Safe manager class for handling safe operations
class SafeManager {
  final Ref _ref;

  SafeManager(this._ref);

  /// Delete a safe with proper confirmation and cleanup
  Future<void> deleteSafe(BuildContext context, SafeEntity safe) async {
    final bool? confirmed = await _confirmDeletingSafe(context, safe.name);

    if (!(confirmed ?? false)) return;

    // IMPORTANT: Capturer le NavigatorState AVANT d'appeler deleteSafe
    // Car le context sera invalidé quand les widgets se rebuild après la suppression
    final navigator = Navigator.of(context);

    try {
      // IMPORTANT: Delete certification queue data BEFORE deleting the safe
      // Otherwise we lose access to the wallet addresses
      final walletService = _ref.read(walletServiceProvider);
      final walletsInSafe = walletService.getWalletDataList(safe.number);
      final addresses = walletsInSafe.map((w) => w.address).toList();

      log.d('🗑️ [SafeManager] Deleting certification queues for ${addresses.length} wallet addresses');
      await CertificationQueueService.deleteQueuesForAddresses(addresses);

      // Delete the safe from storage
      await walletService.deleteSafe(safe.number);

      // Clear the PIN for security after successful deletion
      PinCodeService.pinCode = '';

      // Handle navigation based on whether safes remain
      await _handlePostDeletionNavigation(navigator, walletService);

      // Add a small delay to ensure all async operations complete
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      log.e('Failed to delete safe: $e');
      // Clear PIN on error for security
      PinCodeService.pinCode = '';

      // Show error message to user
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete safe: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  /// Handle navigation and state updates after safe deletion
  Future<void> _handlePostDeletionNavigation(NavigatorState navigator, dynamic walletService) async {
    if (walletService.safeBox.isEmpty()) {
      await _handleNoSafesRemaining(navigator, walletService);
    } else {
      await _handleSafesRemaining(navigator, walletService);
    }
  }

  /// Handle case when no safes remain after deletion
  Future<void> _handleNoSafesRemaining(NavigatorState navigator, dynamic walletService) async {
    // 1. Navigate FIRST with captured NavigatorState (before context becomes invalid)
    navigator.pushNamedAndRemoveUntil(RouteNames.home, (route) => false);

    // 2. Small delay to let navigation start and unmount old widgets
    await Future.delayed(const Duration(milliseconds: 50));

    // 3. Invalidate stream providers BEFORE modifying states
    _ref.read(walletActionsProvider.notifier).invalidateProviders();

    // 4. Update states (wallets already deleted by durt2)
    _ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(-1);
    _ref.read(walletsListProvider.notifier).clear();

    // 5. Refresh biometric provider after navigation
    await _ref.read(biometricProvider.notifier).refresh();
  }

  /// Handle case when safes remain after deletion
  Future<void> _handleSafesRemaining(NavigatorState navigator, dynamic walletService) async {
    final remainingSafes = walletService.safeBox.getAll();

    if (remainingSafes.isEmpty) {
      // Edge case: no safes left after deletion (race condition)
      log.w('No remaining safes found after deletion');
      await _handleNoSafesRemaining(navigator, walletService);
      return;
    }

    final newDefaultSafe = remainingSafes.first.number;
    _ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(newDefaultSafe);
    // Invalidate identity providers to ensure they use the new safe
    _ref.invalidate(idtyWalletAsyncProvider);
    _ref.invalidate(identityWalletsAsyncProvider);

    // Reload wallets for the new default safe
    try {
      await _ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: newDefaultSafe);
    } catch (e) {
      log.e('Failed to reload wallets for safe $newDefaultSafe: $e');
      // If we can't reload wallets, at least clear the list to prevent stale data
      _ref.read(walletsListProvider.notifier).clear();
    }

    // Force refresh of biometric provider after safe state changes
    await _ref.read(biometricProvider.notifier).refresh();

    // Navigate back to wallets home
    navigator.popUntil(ModalRoute.withName(RouteNames.home));
  }

  /// Show confirmation dialog for safe deletion
  Future<bool?> _confirmDeletingSafe(BuildContext context, String walletName) async {
    return showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.warning,
      message: 'areYouSureToForgetSafe'.tr(args: [walletName]),
    );
  }
}
