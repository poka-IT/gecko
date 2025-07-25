// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show WalletEntity, KeyPairType, WalletService, SafeEntity;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:provider/provider.dart' as old_provider;

/// Test wallet configuration
class TestWalletConfig {
  final String derivation;
  final int number;
  final String name;
  final String imagePath;

  const TestWalletConfig({required this.derivation, required this.number, required this.name, required this.imagePath});
}

/// Debug service for creating test wallets
class DebugTestWalletService {
  static const String testMnemonic = "bottom drive obey lake curtain smoke basket hold race lonely fit walk";
  static const int defaultPinCode = 1234;

  /// Check if the current app is using the test/development safe
  /// Returns true if the first wallet address is the known development address
  static bool isUsingTestSafe(ProviderContainer container) {
    try {
      final walletService = container.read(walletServiceProvider);

      // Check if any wallets exist
      if (walletService.walletBox.isEmpty()) {
        return false;
      }

      // Get all wallets and find the first one (lowest derivation number)
      final allWallets = walletService.walletBox.getAll();
      if (allWallets.isEmpty) {
        return false;
      }

      // Sort by derivation number to get the first wallet
      allWallets.sort((a, b) => a.number.compareTo(b.number));
      final firstWallet = allWallets.first;

      // Check if the first wallet address matches the known test address
      return firstWallet.address == '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY';
    } catch (e) {
      log.e('Error checking test safe: $e');
      return false;
    }
  }

  // Configuration for all test wallets
  static const List<TestWalletConfig> walletConfigs = [
    TestWalletConfig(derivation: '//Alice', number: 0, name: 'Alice (//Alice)', imagePath: 'assets/avatars/0.png'),
    TestWalletConfig(derivation: '//Bob', number: 1, name: 'Bob (//Bob)', imagePath: 'assets/avatars/1.png'),
    TestWalletConfig(
      derivation: '//Charlie',
      number: 2,
      name: 'Charlie (//Charlie)',
      imagePath: 'assets/avatars/2.png',
    ),
    TestWalletConfig(derivation: '//Dave', number: 3, name: 'Dave (//Dave)', imagePath: 'assets/avatars/3.png'),
    TestWalletConfig(derivation: '//Eve', number: 4, name: 'Eve (//Eve)', imagePath: 'assets/avatars/0.png'),
    TestWalletConfig(derivation: '//Ferdie', number: 5, name: 'Ferdie (//Ferdie)', imagePath: 'assets/avatars/1.png'),
  ];

  /// Import test wallet with multiple derivations (debug mode + local network only)
  static Future<void> importTestWallet(BuildContext context) async {
    try {
      // Get the required providers
      final container = ProviderContainer();
      final walletService = container.read(walletServiceProvider);
      final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

      // Show loading dialog
      _showLoadingDialog(context);

      // 1. Create a safe with test mnemonic first
      await walletService.createSafe(
        mnemonic: testMnemonic,
        pinCode: defaultPinCode.toString(),
        safeName: 'Test Safe (Development)',
      );

      // 2. Get the safe reference
      final safe = walletService.getSafeBox(myWalletProvider.getCurrentSafe);

      // 3. Create all wallets
      final List<WalletEntity> wallets = [];
      for (final config in walletConfigs) {
        final wallet = await _createTestWallet(
          walletService: walletService,
          safe: safe,
          mnemonic: testMnemonic,
          config: config,
        );
        wallets.add(wallet);
      }

      // 4. Save all wallets
      for (final wallet in wallets) {
        await walletService.walletBox.putAsync(wallet);
      }

      // 5. Set Alice as default wallet (first wallet)
      await walletService.setDefaultAddress(wallets.first.address);

      // 6. Reload wallets list
      await myWalletProvider.readAllWallets();
      myWalletProvider.reload();

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      _showSuccessMessage(context, wallets);
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      _showErrorMessage(context, e);
    }
  }

  /// Helper function to create a single test wallet
  static Future<WalletEntity> _createTestWallet({
    required WalletService walletService,
    required SafeEntity safe,
    required String mnemonic,
    required TestWalletConfig config,
  }) async {
    final keypair = await walletService.getKeyPairFromMnemonic(
      '$mnemonic${config.derivation}',
      keyPairType: KeyPairType.sr25519,
    );

    final wallet = WalletEntity.create(
      address: keypair.address,
      number: config.number,
      derivation: config.number,
      name: config.name,
      imagePath: config.imagePath,
      keyPairType: KeyPairType.sr25519,
    );

    wallet.safe.target = safe;
    return wallet;
  }

  /// Show loading dialog
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              ScaledSizedBox(height: 16),
              Text("Creating test wallets...", textAlign: TextAlign.center, style: scaledTextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  /// Show success message
  static void _showSuccessMessage(BuildContext context, List<WalletEntity> wallets) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Test wallets created successfully!\n'
          '${wallets.length} accounts generated\n'
          'Alice address: ${wallets.first.address}\n'
          'PIN: $defaultPinCode',
          style: scaledTextStyle(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show error message
  static void _showErrorMessage(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error creating test wallets: $error', style: scaledTextStyle(fontSize: 14, color: Colors.white)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    log.e('Error creating test wallets: $error');
  }
}
