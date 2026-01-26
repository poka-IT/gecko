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

    try {
      // Delete the safe from storage
      await _ref.read(walletServiceProvider).deleteSafe(safe.number);

      // Clear the PIN for security after successful deletion
      PinCodeService.pinCode = '';

      // Handle navigation based on whether safes remain
      final walletService = _ref.read(walletServiceProvider);
      // ignore: use_build_context_synchronously
      await _handlePostDeletionNavigation(context, walletService);

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
  Future<void> _handlePostDeletionNavigation(
    BuildContext context,
    dynamic walletService,
  ) async {
    if (walletService.safeBox.isEmpty()) {
      await _handleNoSafesRemaining(context, walletService);
    } else {
      await _handleSafesRemaining(context, walletService);
    }
  }

  /// Handle case when no safes remain after deletion
  Future<void> _handleNoSafesRemaining(
    BuildContext context,
    dynamic walletService,
  ) async {
    walletService.setDefaultSafeBoxNumber(-1);
    _ref.read(walletsListProvider.notifier).clear();

    // Force refresh of biometric provider after safe state changes
    await _ref.read(biometricProvider.notifier).refresh();

    // Navigate to home since no safes exist
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, RouteNames.home, (route) => false);
    }
  }

  /// Handle case when safes remain after deletion
  Future<void> _handleSafesRemaining(
    BuildContext context,
    dynamic walletService,
  ) async {
    final remainingSafes = walletService.safeBox.getAll();

    if (remainingSafes.isEmpty) {
      // Edge case: no safes left after deletion (race condition)
      log.w('No remaining safes found after deletion');
      await _handleNoSafesRemaining(context, walletService);
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
    if (context.mounted) {
      Navigator.popUntil(context, ModalRoute.withName(RouteNames.home));
    }
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
