import 'dart:async';
import 'package:durt2/durt2.dart' show SafeEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/certification_queue_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/services/snackbar_service.dart';
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
    final bool? confirmed = await _confirmDeletingSafe(context, WalletNameService.displayName(safe.name));

    if (!(confirmed ?? false)) return;

    // IMPORTANT: Capturer le NavigatorState AVANT d'appeler deleteSafe
    // Car le context sera invalidé quand les widgets se rebuild après la suppression
    if (!context.mounted) return;
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
    } catch (e) {
      log.e('Failed to delete safe: $e');
      // Clear PIN on error for security
      PinCodeService.pinCode = '';

      // Show error message to user
      if (context.mounted) {
        SnackbarService.showError(context, message: 'failedDeleteSafe'.tr(args: [e.toString()]));
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
    // 1. Update states immediately (wallets already deleted by durt2)
    _ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(-1);
    _ref.read(walletsListProvider.notifier).clear();

    // 2. Navigate first - pushAndRemoveUntil unmounts old widgets, which auto-disposes
    //    stream providers. Non-autoDispose providers are invalidated after the frame.
    final routeBuilder = AppRoutes.getRoutes()[RouteNames.home]!;
    navigator.pushAndRemoveUntil(
      PageRouteBuilder(
        settings: const RouteSettings(name: RouteNames.home),
        pageBuilder: (context, animation, secondaryAnimation) => routeBuilder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );

    // 3. Yield to let the navigation frame complete before invalidating non-autoDispose providers
    await Future.delayed(const Duration(milliseconds: 300));
    _ref.read(walletActionsProvider.notifier).invalidateProviders();

    // 4. Refresh biometric in background (don't block UI)
    _ref.read(biometricProvider.notifier).refresh();
  }

  /// Handle case when safes remain after deletion
  Future<void> _handleSafesRemaining(NavigatorState navigator, dynamic walletService) async {
    final remainingSafes = walletService.safeBox.getAll();

    if (remainingSafes.isEmpty) {
      log.w('No remaining safes found after deletion');
      await _handleNoSafesRemaining(navigator, walletService);
      return;
    }

    // Navigate back first to unmount old widgets (reduces provider rebuild pressure)
    navigator.popUntil(ModalRoute.withName(RouteNames.home));

    // Small yield to let the navigation frame complete before invalidation cascade
    await Future.delayed(const Duration(milliseconds: 100));

    final newDefaultSafe = remainingSafes.first.number;
    try {
      await _ref.read(walletActionsProvider.notifier).switchSafe(newDefaultSafe);
    } catch (e) {
      log.e('Failed to switch to safe $newDefaultSafe: $e');
      _ref.read(walletsListProvider.notifier).clear();
    }

    // Refresh biometric in background (don't block UI)
    _ref.read(biometricProvider.notifier).refresh();
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
