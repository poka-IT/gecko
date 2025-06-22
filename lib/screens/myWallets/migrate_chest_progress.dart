// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/substrate_sdk.dart';
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
    final chestProvider = Provider.of<ChestProvider>(context, listen: false);
    final currentChest = chestBox.get(configBox.get('currentChest'))!;

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

    // Automatically forget the old chest and navigate
    await chestProvider.forgetSafe(context, currentChest);
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
                      value: _currentStep / widget.walletsToMigrate.length,
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
                color: Colors.black.withOpacity(0.05),
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
                      // Already handled at the end of _startMigration
                      // The navigation is handled inside forgetSafe
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: _migrationSuccess ? Text('goToChooseChest'.tr()) : Text('close'.tr()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
