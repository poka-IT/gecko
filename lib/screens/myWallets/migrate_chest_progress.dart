// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/onBoarding/7.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';

class MigrateChestProgressScreen extends StatefulWidget {
  final String newMnemonic;
  final List<WalletData> walletsToMigrate;
  final String oldChestPin;

  const MigrateChestProgressScreen({
    super.key,
    required this.newMnemonic,
    required this.walletsToMigrate,
    required this.oldChestPin,
  });

  @override
  State<MigrateChestProgressScreen> createState() => _MigrateChestProgressScreenState();
}

class _MigrateChestProgressScreenState extends State<MigrateChestProgressScreen> {
  final List<String> _logs = [];
  int _currentStep = 0;
  bool _migrationCompleted = false;
  bool _migrationSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMigration();
    });
  }

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }

  Future<void> _startMigration() async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    _addLog('startingMigration'.tr(args: [widget.walletsToMigrate.length.toString()]));

    for (final wallet in widget.walletsToMigrate) {
      setState(() {
        _currentStep++;
      });
      _addLog('---');
      _addLog('migratingWallet'.tr(args: [wallet.name ?? wallet.address]));

      try {
        final transactionId = await sub.migrateWalletToNewMnemonic(
          sourceWallet: wallet,
          newMnemonic: widget.newMnemonic,
          sourcePassword: widget.oldChestPin,
        );

        if (transactionId.isNotEmpty) {
          _addLog('migrationTransactionSent'.tr(args: [transactionId]));
          // Here we could poll for transaction status, but for now we assume it will succeed.
          await Future.delayed(const Duration(seconds: 12)); // Wait for block
        } else {
          _addLog('walletIsEmptyNoMigrationNeeded'.tr());
        }
      } catch (e) {
        _addLog('migrationFailed'.tr(args: [e.toString()]));
        setState(() {
          _migrationCompleted = true;
          _migrationSuccess = false;
        });
        return;
      }
    }

    _addLog('---');
    _addLog('migrationSuccessfullyCompleted'.tr());

    setState(() {
      _migrationCompleted = true;
      _migrationSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    LinearProgressIndicator(
                      value: _currentStep > 0 ? (_currentStep - 1) / widget.walletsToMigrate.length : 0,
                    ),
                    const SizedBox(height: 16),
                    Text('migratingWalletNofM'.tr(args: [_currentStep.toString(), widget.walletsToMigrate.length.toString()])),
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
              child: Container(
                color: Colors.black.withValues(alpha: 0.05),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Text(_logs[index]),
                    );
                  },
                ),
              ),
            ),
            if (_migrationCompleted)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_migrationSuccess) {
                      final genW = Provider.of<GenerateWalletsProvider>(context, listen: false);
                      genW.generatedMnemonic = widget.newMnemonic;
                      genW.resetImportView(); // Good practice from restore_chest

                      _addLog('deletingOldChest'.tr());

                      final myWallets = Provider.of<MyWalletsProvider>(context, listen: false);
                      final currentChestNumber = configBox.get('currentChest');
                      final currentChest = chestBox.get(currentChestNumber)!;

                      // Manually delete the old chest's contents
                      await myWallets.clearWallets(currentChest);

                      _addLog('oldChestDeleted'.tr());

                      await Navigator.pushAndRemoveUntil(
                        context,
                        FaderTransition(page: const OnboardingStepSeven(scanDerivation: true, fromRestore: true), isFast: true),
                        (route) => false,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(_migrationSuccess ? 'setupNewChest'.tr() : 'close'.tr()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
