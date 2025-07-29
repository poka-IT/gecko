import 'dart:async';
import 'package:durt2/durt2.dart' show SafeEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart' as old_provider;

class SafeProvider with ChangeNotifier {
  late ProviderContainer _container;

  SafeProvider() {
    _container = ProviderContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  Future forgetSafe(BuildContext context, SafeEntity safe) async {
    final bool? answer = await (_confirmDeletingSafe(context, safe.name));
    // ignore: use_build_context_synchronously
    if (answer ?? false) {
      // Get the wallet provider
      final myWalletProvider =
          // ignore: use_build_context_synchronously
          old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

      // Note: PIN/biometric authentication is already done by the caller (safe_options.dart)
      // so we don't need to call askPinCode() again here
      // Also, deleteSafe() doesn't actually require a PIN - it just deletes the safe data

      try {
        // Now delete the safe (this also clears biometric data)
        await _container.read(walletServiceProvider).deleteSafe(safe.number);

        // Clear the PIN for security after successful deletion
        myWalletProvider.pinCode = '';

        // Handle navigation based on whether safes remain
        final walletService = _container.read(walletServiceProvider);
        if (walletService.safeBox.isEmpty()) {
          walletService.setDefaultSafeBoxNumber(-1);
          // Clear the wallet list when no safes remain
          myWalletProvider.listWallets = [];

          // Force refresh of biometric provider after safe state changes
          await _container.read(biometricProvider.notifier).refresh();

          // Navigate to home since no safes exist
          Navigator.pushNamedAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            RouteNames.home,
            (route) => false,
          );
        } else {
          // Update to the new default safe
          final remainingSafes = walletService.safeBox.getAll();
          if (remainingSafes.isEmpty) {
            // Edge case: no safes left after deletion (race condition)
            log.w('No remaining safes found after deletion');
            walletService.setDefaultSafeBoxNumber(-1);
            myWalletProvider.listWallets = [];

            // Force refresh of biometric provider after safe state changes
            await _container.read(biometricProvider.notifier).refresh();

            // Navigate to home since no safes exist
            Navigator.pushNamedAndRemoveUntil(
              // ignore: use_build_context_synchronously
              context,
              RouteNames.home,
              (route) => false,
            );
            return;
          }

          final newDefaultSafe = remainingSafes.first.number;
          walletService.setDefaultSafeBoxNumber(newDefaultSafe);

          // Reload wallets for the new default safe
          try {
            await myWalletProvider.readAllWallets(safeBoxNumber: newDefaultSafe);
          } catch (e) {
            log.e('Failed to reload wallets for safe $newDefaultSafe: $e');
            // If we can't reload wallets, at least clear the list to prevent stale data
            myWalletProvider.listWallets = [];
          }

          // Force refresh of biometric provider after safe state changes
          await _container.read(biometricProvider.notifier).refresh();

          // Navigate back to wallets home
          Navigator.popUntil(
            // ignore: use_build_context_synchronously
            context,
            ModalRoute.withName(RouteNames.home),
          );
        }

        // Add a small delay to ensure all async operations complete before notifying listeners
        await Future.delayed(const Duration(milliseconds: 50));

        // Only notify listeners if the context is still valid
        if (context.mounted) {
          myWalletProvider.notifyListeners();
          notifyListeners();
        }
      } catch (e) {
        log.e('Failed to delete safe: $e');
        // Clear PIN on error for security
        myWalletProvider.pinCode = '';

        // Show error message to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete safe: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<bool?> _confirmDeletingSafe(BuildContext context, String walletName) async {
    return showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.warning,
      message: 'areYouSureToForgetSafe'.tr(args: [walletName]),
    );
  }
}
