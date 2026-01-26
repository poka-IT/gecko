import 'dart:io';
import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/trm_data_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
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
  static Future<int> deleteWallet(BuildContext context, WalletEntity wallet) async {
    // Get required providers
    final container = riverpod.ProviderContainer();
    final defaultWallet = container.read(defaultWalletProvider);

    try {
      final walletBalance = await container.read(storageServiceProvider).getBalance(wallet.address);

      // Show confirmation dialog with transfer details
      String confirmationMessage;
      if (walletBalance.transferableBalance > BigInt.zero) {
        confirmationMessage = 'areYouSureToForgetWalletWithBalance'.tr(
          args: [
            wallet.name!,
            '${(walletBalance.transferableBalance.toDouble() / 100).toStringAsFixed(2)} ${Durt.i.network.symbol}',
            defaultWallet.name ?? 'defaultWallet'.tr(),
          ],
        );
      } else {
        confirmationMessage = 'areYouSureToForgetWallet'.tr(args: [wallet.name!]);
      }

      final answer = await showConfirmationDialog(
        // ignore: use_build_context_synchronously
        context: context,
        message: confirmationMessage,
        type: ConfirmationDialogType.warning,
      );

      if (!answer) {
        container.dispose();
        return 2; // User cancelled
      }

      // If wallet has balance, transfer funds first
      if (walletBalance.transferableBalance > BigInt.zero) {
        if (!await PinCodeService.askPinCode()) {
          container.dispose();
          return 2; // PIN cancelled
        }

        final transferResult = await _transferWalletBalance(
          // ignore: use_build_context_synchronously
          context,
          container,
          wallet,
          defaultWallet,
          PinCodeService.pinCode,
        );

        if (transferResult != 0) {
          container.dispose();
          return transferResult;
        }
      }

      // Delete wallet files and data
      await _cleanupWalletFiles(wallet);
      await container.read(walletServiceProvider).deleteWallet(wallet.address);

      // Navigate back
      if (context.mounted) {
        Navigator.pop(context);
      }

      container.dispose();
      return 0; // Success
    } catch (e) {
      container.dispose();
      rethrow;
    }
  }

  /// Transfer wallet balance to default wallet
  static Future<int> _transferWalletBalance(
    BuildContext context,
    riverpod.ProviderContainer container,
    WalletEntity wallet,
    WalletEntity defaultWallet,
    String pinCode,
  ) async {
    // Show loading dialog while transaction is processing
    showConfirmationDialog(
      context: context,
      message: 'transferringFundsToDefaultWallet'.tr(args: [defaultWallet.name ?? 'defaultWallet'.tr()]),
      type: ConfirmationDialogType.info,
      customIcon: const CircularProgressIndicator(),
      barrierDismissible: false,
      hideCancelButton: true,
      hideConfirmButton: true,
    );

    try {
      final keypair = await container
          .read(walletServiceProvider)
          .getKeyPairFromAddress(address: wallet.address, pinCode: pinCode);

      // Get display mode for transaction
      final displayContainer = riverpod.ProviderContainer();
      final displayMode = displayContainer.read(currencyDisplayModeProvider);
      final isUdUnit = displayMode == CurrencyDisplayMode.du;
      displayContainer.dispose();

      final transactionStatus = container
          .read(duniterServiceProvider)
          .pay(
            keypair: keypair,
            destAddress: defaultWallet.address,
            amount: -1, // Send all balance
            comment: 'ĞECKO:DELETEWALLET',
            isUd: isUdUnit,
          );

      // Wait for transaction completion and check if successful
      bool transactionSuccessful = false;
      String? errorMessage;

      await for (final status in transactionStatus) {
        switch (status.state) {
          case TransactionState.finalized || TransactionState.inBlock:
            transactionSuccessful = true;
            break;
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
