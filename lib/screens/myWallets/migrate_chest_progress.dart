// ignore_for_file: use_build_context_synchronously

import 'dart:async';

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
import 'package:gecko/widgets/buttons/primary_button.dart';
import 'package:provider/provider.dart';

enum MigrationStatus { pending, migrating, success, failed, empty }

class MigrationTask {
  final WalletData wallet;
  MigrationStatus status;
  String? details; // For TxID or error message

  MigrationTask(this.wallet, {this.status = MigrationStatus.pending});

  bool get isDone => status == MigrationStatus.success || status == MigrationStatus.failed || status == MigrationStatus.empty;
}

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
  late List<MigrationTask> _tasks;
  bool _migrationCompleted = false;
  bool _migrationSuccess = false;
  int get _completedSteps => _tasks.where((t) => t.isDone).length;

  @override
  void initState() {
    super.initState();
    _tasks = widget.walletsToMigrate.map((w) => MigrationTask(w)).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMigration();
    });
  }

  Future<void> _startMigration() async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    final migrations = _tasks.map((task) {
      return _migrateSingleWallet(task, sub);
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

  Future<void> _migrateSingleWallet(MigrationTask task, SubstrateSdk sub) async {
    if (!mounted) return;
    setState(() => task.status = MigrationStatus.migrating);

    try {
      final transactionId = await sub.migrateWalletToNewMnemonic(
        sourceWallet: task.wallet,
        newMnemonic: widget.newMnemonic,
        sourcePassword: widget.oldChestPin,
      );

      if (transactionId.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 12)); // Wait for block
        if (!mounted) return;
        setState(() {
          task.status = MigrationStatus.success;
          task.details = transactionId;
        });
      } else {
        if (!mounted) return;
        setState(() => task.status = MigrationStatus.empty);
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
                    LinearProgressIndicator(
                      value: totalTasks > 0 ? _completedSteps / totalTasks : 0,
                    ),
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
                      final genW = Provider.of<GenerateWalletsProvider>(context, listen: false);
                      genW.generatedMnemonic = widget.newMnemonic;
                      genW.resetImportView();

                      final myWallets = Provider.of<MyWalletsProvider>(context, listen: false);
                      final currentChestNumber = configBox.get('currentChest');
                      final currentChest = chestBox.get(currentChestNumber)!;

                      await myWallets.clearWallets(currentChest);

                      await Navigator.pushAndRemoveUntil(
                        context,
                        FaderTransition(page: const OnboardingStepSeven(scanDerivation: true, fromRestore: true), isFast: true),
                        (route) => false,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  label: _migrationSuccess ? 'setupNewChest'.tr() : 'close'.tr(),
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
        leading = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
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
      onTap = () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('migrationFailedTitle'.tr()),
            content: SingleChildScrollView(child: SelectableText(task.details!)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('close'.tr()),
              ),
            ],
          ),
        );
      };
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: leading,
        ),
        title: Text(task.wallet.name ?? task.wallet.address),
        subtitle: Text(statusText),
        onTap: onTap,
        trailing: onTap != null ? const Icon(Icons.info_outline, color: Colors.blueGrey) : null,
      ),
    );
  }
}
