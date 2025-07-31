// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/buttons/primary_button.dart';
import 'package:gecko/screens/myWallets/switch_safe.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';

enum MigrationStatus { pending, migrating, success, failed, empty }

class MigrationTask {
  final WalletEntity wallet;
  MigrationStatus status;
  String? details; // For TxID or error message
  String? destinationAddress; // Address where funds are being sent

  MigrationTask(this.wallet, {this.status = MigrationStatus.pending});

  bool get isDone =>
      status == MigrationStatus.success || status == MigrationStatus.failed || status == MigrationStatus.empty;
}

class MigrateSafeProgressScreen extends ConsumerStatefulWidget {
  final String newMnemonic;
  final List<WalletEntity> walletsToMigrate;
  final String oldSafePin;

  const MigrateSafeProgressScreen({
    super.key,
    required this.newMnemonic,
    required this.walletsToMigrate,
    required this.oldSafePin,
  });

  @override
  ConsumerState<MigrateSafeProgressScreen> createState() => _MigrateSafeProgressScreenState();
}

class _MigrateSafeProgressScreenState extends ConsumerState<MigrateSafeProgressScreen> {
  late List<MigrationTask> _tasks;
  bool _migrationCompleted = false;
  bool _migrationSuccess = false;
  int? _existingSafeNumber; // Track if safe already exists
  int get _completedSteps => _tasks.where((t) => t.isDone).length;

  @override
  void initState() {
    super.initState();
    _tasks = widget.walletsToMigrate.map((w) => MigrationTask(w)).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfSafeExists();
      _startMigration();
    });
  }

  /// Check if a safe with the same mnemonic already exists
  /// Uses the mnemonic fingerprint for fast and reliable detection
  Future<void> _checkIfSafeExists() async {
    try {
      // Generate fingerprint from the new mnemonic
      final fingerprint = SafeEntity.generateFingerprint(widget.newMnemonic);

      // Check if any safe with this fingerprint already exists
      final existingSafe = ref.read(walletServiceProvider).safeBox.getByFingerprint(fingerprint);

      if (existingSafe != null) {
        _existingSafeNumber = existingSafe.number;
      } else {
        _existingSafeNumber = null;
      }
    } catch (e) {
      // If error occurs, assume safe doesn't exist
      _existingSafeNumber = null;
    }
  }

  /// Recreate the migrated wallets in the existing safe
  /// This ensures consistency between the old and new safe
  Future<void> _recreateWalletsInExistingSafe(int safeNumber) async {
    try {
      final walletService = ref.read(walletServiceProvider);

      // Get all existing wallets in the safe
      final existingWallets = walletService.getWalletDataList(safeNumber);

      // Delete all existing wallets in the safe
      for (final wallet in existingWallets) {
        await walletService.deleteWallet(wallet.address);
      }

      // Get the safe entity
      final safe = walletService.getSafeBox(safeNumber);

      // Recreate wallets following correct derivation logic: root, //0, //1, //2, etc.
      for (int i = 0; i < widget.walletsToMigrate.length; i++) {
        final originalWallet = widget.walletsToMigrate[i];

        // Generate keypair: first wallet = root (no derivation), others = derivation //0, //1, //2, etc.
        final keypair = i == 0
            ? await walletService.getKeyPairFromMnemonic(widget.newMnemonic, keyPairType: Durt.defaultKeyPairType)
            : await walletService.getKeyPairFromMnemonic(
                widget.newMnemonic,
                derivation: i - 1, // First derived wallet gets //0, second gets //1, etc.
                keyPairType: Durt.defaultKeyPairType,
              );

        // Create the new wallet entity
        final newWallet = WalletEntity.create(
          address: keypair.address,
          number: i, // Use sequential numbering
          name: originalWallet.name,
          derivation: i == 0 ? null : i - 1, // Root has no derivation, others have derivation //0, //1, etc.
          imagePath: originalWallet.imagePath,
          keyPairType: Durt.defaultKeyPairType,
        );

        // Link to the existing safe
        newWallet.safe.target = safe;

        // Save the wallet
        await walletService.walletBox.putAsync(newWallet);

        // Set the first wallet as default
        if (i == 0) {
          safe.defaultAddress = newWallet.address;
          safe.rootAddress = newWallet.address;
          walletService.safeBox.put(safe);
        }
      }
    } catch (e) {
      // Log error but don't block the migration completion
      // ignore: avoid_print
      print('🚨 Error recreating wallets in existing safe: $e');
    }
  }

  Future<void> _startMigration() async {
    final migrations = _tasks.map((task) {
      return _migrateSingleWallet(task);
    }).toList();

    try {
      await Future.wait(migrations);
      if (!mounted) return;
      setState(() {
        _migrationCompleted = true;
        _migrationSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _migrationCompleted = true;
        _migrationSuccess = false;
      });
    }
  }

  Future<void> _migrateSingleWallet(MigrationTask task) async {
    if (!mounted) return;

    try {
      // Get the index of this wallet in the migration list
      final walletIndex = widget.walletsToMigrate.indexOf(task.wallet);

      // Generate destination keypair: first wallet = root, others = derivation //0, //1, //2, etc.
      final destKeypair = walletIndex == 0
          ? await ref
                .read(walletServiceProvider)
                .getKeyPairFromMnemonic(widget.newMnemonic, keyPairType: Durt.defaultKeyPairType)
          : await ref
                .read(walletServiceProvider)
                .getKeyPairFromMnemonic(
                  widget.newMnemonic,
                  derivation: walletIndex - 1, // First derived wallet gets //0, second gets //1, etc.
                  keyPairType: Durt.defaultKeyPairType,
                );

      // Set destination address for display
      setState(() {
        task.destinationAddress = destKeypair.address;
        task.status = MigrationStatus.migrating;
      });

      // Check if wallet has any balance to migrate
      final balance = await ref.read(durtProvider).storage.getBalance(task.wallet.address);

      if (balance.transferableBalance == BigInt.zero) {
        // Wallet is empty, mark as empty instead of migrating
        if (!mounted) return;
        setState(() {
          task.status = MigrationStatus.empty;
          task.details = "walletIsEmptyNoMigrationNeeded".tr();
        });
        return;
      }

      // Get source wallet keypair
      final sourceKeypair = await ref
          .read(walletServiceProvider)
          .getKeyPairFromAddress(address: task.wallet.address, pinCode: PinCodeService.pinCode);

      // Migrate identity if wallet has one
      final idtyStatus = await ref.read(storageServiceProvider).getIdtyStatus(task.wallet.address);
      if (idtyStatus != IdtyStatus.none && idtyStatus != IdtyStatus.unknown) {
        final transactionStatus = ref
            .read(duniterServiceProvider)
            .migrateIdentity(fromKeypair: sourceKeypair, toKeypair: destKeypair, withBalance: true);

        // Wait for transaction confirmation
        await for (final status in transactionStatus) {
          if (status.state == TransactionState.finalized || status.state == TransactionState.inBlock) {
            if (!mounted) return;
            setState(() {
              task.status = MigrationStatus.success;
              task.details = status.hash ?? "identityMigrationSuccess".tr();
            });
            return;
          } else if (status.state == TransactionState.error) {
            throw Exception("Migration failed: ${status.errorMessage}");
          }
        }
      } else {
        // Simple balance transfer for wallets without identity
        final transactionStatus = ref
            .read(duniterServiceProvider)
            .pay(keypair: sourceKeypair, destAddress: destKeypair.address, amount: -1);

        // Wait for transaction confirmation
        await for (final status in transactionStatus) {
          if (status.state == TransactionState.finalized || status.state == TransactionState.inBlock) {
            if (!mounted) return;
            setState(() {
              task.status = MigrationStatus.success;
              task.details = status.hash ?? "balanceTransferSuccess".tr();
            });
            return;
          } else if (status.state == TransactionState.error) {
            throw Exception("Transfer failed: ${status.errorMessage}");
          }
        }
      }
    } catch (e) {
      if (!mounted) rethrow;

      setState(() {
        task.status = MigrationStatus.failed;
        task.details = e.toString();
      });
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = widget.walletsToMigrate.length;
    return Scaffold(
      appBar: GeckoAppBar('migrationInProgress'.tr()),
      body: SafeArea(
        child: Column(
          children: [
            if (!_migrationCompleted)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: totalTasks > 0 ? _completedSteps / totalTasks : 0),
                    const SizedBox(height: 16),
                    Text('migratedWalletsNofM'.tr(args: [_completedSteps.toString(), totalTasks.toString()])),
                  ],
                ),
              ),
            if (_migrationCompleted)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _migrationSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      color: _migrationSuccess ? Colors.green : Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _migrationSuccess ? 'migrationSuccess'.tr() : 'migrationFailedTitle'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskTile(_tasks[index]);
                },
              ),
            ),
            if (_migrationCompleted)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: PrimaryButton(
                  onPressed: () async {
                    if (_migrationSuccess) {
                      if (_existingSafeNumber != null) {
                        // Safe already exists, clear its wallets and recreate migrated ones
                        await _recreateWalletsInExistingSafe(_existingSafeNumber!);

                        // Switch to the existing safe
                        ref.read(walletServiceProvider).setDefaultSafeBoxNumber(_existingSafeNumber!);

                        // Clean up GlobalKeys before navigating to prevent conflicts
                        cleanupWalletsHomeKeys();

                        // Navigate to switch safe screen
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SwitchSafe()));
                      } else {
                        // Create new safe
                        // Set the mnemonic in the provider for the next screen
                        await ref.read(mnemonicStateProvider.notifier).setMnemonic(widget.newMnemonic);

                        await AppNavigator.pushAndRemoveUntilWithFader(
                          context,
                          RouteNames.onboardingStepSeven,
                          arguments: OnboardingStepsSevenToNineArguments(scanDerivation: true, fromRestore: true),
                          isFast: true,
                          (route) => route.settings.name == RouteNames.home,
                        );
                      }
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  label: _migrationSuccess
                      ? (_existingSafeNumber != null ? 'accessThisSafe'.tr() : 'setupNewSafe'.tr())
                      : 'close'.tr(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(MigrationTask task) {
    Widget leading;
    String statusText;

    switch (task.status) {
      case MigrationStatus.pending:
        leading = const Icon(Icons.hourglass_empty, color: Colors.grey);
        statusText = 'pending'.tr();
        break;
      case MigrationStatus.migrating:
        leading = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
        statusText = 'migratingStatus'.tr();
        break;
      case MigrationStatus.success:
        leading = const Icon(Icons.check_circle, color: Colors.green);
        statusText = 'successStatus'.tr();
        break;
      case MigrationStatus.failed:
        leading = const Icon(Icons.error, color: Colors.red);
        statusText = 'failedStatus'.tr();
        break;
      case MigrationStatus.empty:
        leading = const Icon(Icons.info_outline, color: Colors.blueGrey);
        statusText = 'walletIsEmptyNoMigrationNeeded'.tr();
        break;
    }

    VoidCallback? onTap;
    if (task.status == MigrationStatus.failed && task.details != null) {
      onTap = () async {
        await showConfirmationDialog(
          context: context,
          title: 'migrationFailedTitle'.tr(),
          message: task.details!,
          type: ConfirmationDialogType.error,
          barrierDismissible: false,
          hideCancelButton: true,
        );
      };
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: leading),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(task.wallet.name ?? 'Wallet'),
            Text(
              '${task.wallet.address.substring(0, 8)}...${task.wallet.address.substring(task.wallet.address.length - 8)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'monospace'),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(statusText),
            if (task.destinationAddress != null) ...[
              const SizedBox(height: 4),
              Text(
                '→ ${task.destinationAddress!.substring(0, 8)}...${task.destinationAddress!.substring(task.destinationAddress!.length - 8)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
        onTap: onTap,
        trailing: onTap != null ? const Icon(Icons.info_outline, color: Colors.blueGrey) : null,
      ),
    );
  }
}
