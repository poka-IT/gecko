import 'dart:io';
import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/trm_data_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/certification_queue_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

/// Service for handling complex wallet deletion operations
///
/// This service handles the complete wallet deletion flow including:
/// - Balance transfer to default wallet
/// - Transaction processing with status monitoring
/// - File cleanup
/// - Database removal
class WalletDeletionService {
  WalletDeletionService._internal();

  /// Delete a wallet with automatic balance transfer if needed
  ///
  /// Returns:
  /// - 0: Success
  /// - 1: Transaction failed (wallet not deleted)
  /// - 2: User cancelled
  /// Requires a [ref] to access providers from the widget tree.
  static Future<int> deleteWallet(BuildContext context, WalletEntity wallet, {required riverpod.WidgetRef ref}) async {
    // Find destination wallet in the SAME safe as the wallet being deleted
    // (not the active safe, which may differ in desktop mode)
    final safeNumber = wallet.safe.target?.number;
    final wallets = safeNumber != null
        ? ref.read(walletServiceProvider).getWalletDataList(safeNumber)
        : ref.read(walletsListProvider).wallets;
    final destinationWallet = wallets.where((w) => w.address != wallet.address).firstOrNull;
    final isLastWalletInSafe = destinationWallet == null;

    try {
      final walletBalance = await ref.read(storageServiceProvider).getBalance(wallet.address);

      // Show confirmation dialog with transfer details
      String confirmationMessage;
      if (walletBalance.transferableBalance > BigInt.zero && destinationWallet != null) {
        confirmationMessage = 'areYouSureToForgetWalletWithBalance'.tr(
          args: [
            WalletNameService.displayName(wallet.name),
            '${(walletBalance.transferableBalance.toDouble() / 100).toStringAsFixed(2)} ${Durt.i.network.symbol}',
            WalletNameService.displayName(destinationWallet.name),
          ],
        );
      } else {
        confirmationMessage = 'areYouSureToForgetWallet'.tr(args: [WalletNameService.displayName(wallet.name)]);
      }

      final answer = await showConfirmationDialog(
        // ignore: use_build_context_synchronously
        context: context,
        message: confirmationMessage,
        type: ConfirmationDialogType.warning,
      );

      if (!answer) {
        return 2; // User cancelled
      }

      // If wallet has balance and there's a destination, transfer funds first
      if (walletBalance.transferableBalance > BigInt.zero && destinationWallet != null) {
        // ignore: use_build_context_synchronously
        final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: wallet);
        if (capturedPin == null) {
          return 2; // PIN cancelled
        }

        final transferResult = await _transferWalletBalance(
          // ignore: use_build_context_synchronously
          context,
          ref,
          wallet,
          destinationWallet,
          capturedPin,
        );

        if (transferResult != 0) {
          return transferResult;
        }
      }

      // If this is the last wallet in the safe, delegate to SafeManager
      // which handles safe deletion, navigation, and switching to another safe
      if (isLastWalletInSafe) {
        final safe = wallet.safe.target;
        if (safe != null) {
          await _cleanupWalletFiles(wallet);
          // SafeManager.deleteSafe handles everything: deletion, navigation, safe switching
          // It already showed its own confirmation, but we already confirmed above,
          // so we call the internal deletion directly
          if (!context.mounted) return -1;
          await _deleteSafeDirectly(ref, safe, context);
          return 0;
        }
      }

      // Delete wallet files and data
      await _cleanupWalletFiles(wallet);
      await ref.read(walletServiceProvider).deleteWallet(wallet.address);

      // Navigate back
      if (context.mounted) {
        Navigator.pop(context);
      }

      return 0; // Success
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a safe directly (used when deleting the last wallet of a safe).
  /// Mirrors SafeManager's post-deletion logic for proper navigation and state cleanup,
  /// but skips the confirmation dialog (already confirmed by the caller).
  static Future<void> _deleteSafeDirectly(riverpod.WidgetRef ref, SafeEntity safe, BuildContext context) async {
    await _performSafeDeletion(ref, safe, context);
  }

  /// Perform safe deletion with proper navigation handling.
  /// Mirrors SafeManager.deleteSafe but skips the confirmation dialog.
  static Future<void> _performSafeDeletion(riverpod.WidgetRef ref, SafeEntity safe, BuildContext context) async {
    final navigator = Navigator.of(context);
    final walletService = ref.read(walletServiceProvider);

    // Delete certification queue data
    final walletsInSafe = walletService.getWalletDataList(safe.number);
    final addresses = walletsInSafe.map((w) => w.address).toList();
    await CertificationQueueService.deleteQueuesForAddresses(addresses);

    // Delete the safe
    await walletService.deleteSafe(safe.number);

    // Clear PIN
    PinCodeService.clearPin();

    // Handle navigation
    if (walletService.safeBox.isEmpty()) {
      // No safes left - update states before navigation to avoid rebuilds on stale providers
      ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(-1);
      ref.read(walletsListProvider.notifier).clear();

      navigator.pushNamedAndRemoveUntil(RouteNames.home, (route) => false);

      // Yield to let the navigation frame complete before invalidating non-autoDispose providers
      await Future.delayed(const Duration(milliseconds: 300));
      ref.read(walletActionsProvider.notifier).invalidateProviders();
    } else {
      // Safes remain - navigate first to unmount old widgets, then switch safe
      final remainingSafes = walletService.safeBox.getAll();
      if (remainingSafes.isEmpty) return;

      navigator.popUntil(ModalRoute.withName(RouteNames.home));
      await Future.delayed(const Duration(milliseconds: 100));

      final newDefaultSafe = remainingSafes.first.number;
      try {
        await ref.read(walletActionsProvider.notifier).switchSafe(newDefaultSafe);
      } catch (e) {
        ref.read(walletsListProvider.notifier).clear();
      }
    }
  }

  /// Transfer wallet balance to destination wallet
  static Future<int> _transferWalletBalance(
    BuildContext context,
    riverpod.WidgetRef ref,
    WalletEntity wallet,
    WalletEntity destinationWallet,
    String pinCode,
  ) async {
    // Show loading dialog while transaction is processing
    showConfirmationDialog(
      context: context,
      message: 'transferringFundsToWallet'.tr(args: [WalletNameService.displayName(destinationWallet.name)]),
      type: ConfirmationDialogType.info,
      customIcon: const CircularProgressIndicator(),
      barrierDismissible: false,
      hideCancelButton: true,
      hideConfirmButton: true,
    );

    try {
      final keypair = await ref
          .read(walletServiceProvider)
          .getKeyPairFromAddress(address: wallet.address, pinCode: pinCode);

      // Get display mode for transaction
      final displayMode = ref.read(currencyDisplayModeProvider);
      final isUdUnit = displayMode == CurrencyDisplayMode.du;

      final transactionStatus = ref
          .read(duniterServiceProvider)
          .pay(
            keypair: keypair,
            destAddress: destinationWallet.address,
            amount: -1, // Send all balance
            comment: 'GECKO:DELETEWALLET',
            isUd: isUdUnit,
          );

      // Wait for transaction completion and check if successful
      bool transactionSuccessful = false;
      String? errorMessage;

      await for (final status in transactionStatus) {
        switch (status.state) {
          case TransactionState.finalized:
            // Only consider success at finalized (not inBlock) because
            // execution errors are only checked definitively at finalized.
            transactionSuccessful = true;
            break;
          case TransactionState.inBlock:
            // inBlock is a progress indicator, not a terminal state.
            // Wait for finalized to confirm success.
            continue;
          case TransactionState.error || TransactionState.timeout || TransactionState.none:
            errorMessage = status.errorMessage ?? 'unknownError'.tr();
            break;
          case TransactionState.pending || TransactionState.futureNonce || TransactionState.retrying:
            continue;
        }
        // Exit the loop once we have a final state (success or error)
        break;
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (!transactionSuccessful) {
        // Show error dialog
        if (context.mounted) {
          await showConfirmationDialog(
            context: context,
            message: 'transactionFailedWalletNotDeleted'.tr(args: [errorMessage!]),
            type: ConfirmationDialogType.error,
          );
        }
        return 1; // Transaction failed
      }

      return 0; // Success
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      rethrow;
    }
  }

  /// Clean up wallet avatar files
  static Future<void> _cleanupWalletFiles(WalletEntity wallet) async {
    if (wallet.imagePath != null) {
      final avatarFile = File(wallet.imagePath!);
      if (await avatarFile.exists()) {
        await avatarFile.delete();
      }
    }
  }
}

/// Provider for WalletDeletionService
final walletDeletionServiceProvider = riverpod.Provider<WalletDeletionService>((ref) {
  return WalletDeletionService._internal();
});
