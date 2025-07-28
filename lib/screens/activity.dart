// ignore_for_file: must_be_immutable

import 'package:durt2/durt2.dart' show IdtyStatusExtension;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gecko/providers.dart';

import 'package:gecko/widgets/history_query.dart';

import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/widgets/compact_wallet_header.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({required this.address, this.username, this.transactionData}) : super(key: keyActivityScreen);

  final String address;
  final String? username;
  final TransactionInProgressData? transactionData;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> with TickerProviderStateMixin {
  late Future<WalletHeaderData> _headerDataFuture;

  @override
  void initState() {
    super.initState();
    ref.read(storageServiceProvider).getOldOwnerKey(widget.address);
    _headerDataFuture = _loadWalletData();

    // Clear filters when opening a new activity screen
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Multiple safety checks to prevent lifecycle errors
      if (!mounted) return;

      try {
        // Use a future to ensure we're in a stable state
        Future.delayed(Duration.zero, () {
          if (mounted) {
            ref.read(transactionFiltersProvider.notifier).reset();
          }
        });
      } catch (e) {
        // Silently handle any errors during filter reset
        debugPrint('Filter reset error: $e');
      }
    });
  }

  Future<WalletHeaderData> _loadWalletData() async {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    final (idtyStatusValue, balanceResult, certData) = await (
      ref.read(storageServiceProvider).getIdtyStatus(widget.address),
      ref.read(storageServiceProvider).getBalance(widget.address),
      ref.read(storageServiceProvider).getCertsCounter(widget.address),
    ).wait;

    final data = WalletHeaderData(
      hasIdentity: idtyStatusValue.hasIdentity,
      isOwner: myWalletProvider.isOwner(widget.address),
      walletName: ref.read(squidServiceProvider).walletNameIndexer[widget.address],
      balance: balanceResult.transferableBalance,
      certsReceived: certData.receivedCount,
      certsSent: certData.sentCount,
    );

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WalletHeaderData>(
      future: _headerDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Column(
              children: [
                _buildFixedHeader(),
                const Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Column(
              children: [
                _buildFixedHeader(),
                Expanded(child: Center(child: Text('errorLoadingWalletData'.tr()))),
              ],
            ),
          );
        }

        return _buildScaffold(snapshot.data!);
      },
    );
  }

  Widget _buildScaffold(WalletHeaderData headerData) {
    return Scaffold(
      body: Column(
        children: [
          // Fixed compact header - never moves
          _buildFixedHeader(),

          // Transaction history takes remaining space
          Expanded(
            child: HistoryQuery(address: widget.address, transactionData: widget.transactionData),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader() {
    final balanceAsync = ref.watch(smartBalanceStreamProvider(widget.address));
    final balance = balanceAsync.hasValue ? balanceAsync.value?.transferableBalance : null;
    final isEmptyWallet = balance == null || balance == BigInt.zero;

    // Determine background color based on wallet state
    final backgroundColor = isEmptyWallet
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;

    return Container(
      color: backgroundColor,
      child: CompactWalletHeader(address: widget.address, showBackButton: true),
    );
  }
}
