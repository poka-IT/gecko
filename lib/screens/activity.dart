// ignore_for_file: must_be_immutable

import 'package:durt2/durt2.dart' show IdtyStatusExtension;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers.dart';

import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/history_query.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/widgets/compact_wallet_header.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';

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
            body: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return [_buildCollapsibleHeader()]; // Show CompactWalletHeader immediately
              },
              body: const Center(child: CircularProgressIndicator()),
            ),
            bottomNavigationBar: const GeckoBottomAppBar(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return [_buildCollapsibleHeader()]; // Show CompactWalletHeader even on error
              },
              body: Center(child: Text('errorLoadingWalletData'.tr())),
            ),
            bottomNavigationBar: const GeckoBottomAppBar(),
          );
        }

        return _buildScaffold(snapshot.data!);
      },
    );
  }

  Widget _buildScaffold(WalletHeaderData headerData) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [_buildCollapsibleHeader()];
        },
        body: Stack(
          children: [
            // Remove the top padding of the HistoryQuery widget
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: HistoryQuery(address: widget.address, transactionData: widget.transactionData),
            ),
            const OfflineInfo(),
          ],
        ),
      ),
      bottomNavigationBar: const GeckoBottomAppBar(),
    );
  }

  Widget _buildCollapsibleHeader() {
    final balanceAsync = ref.watch(smartBalanceStreamProvider(widget.address));

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final balance = balanceAsync.hasValue ? balanceAsync.value?.transferableBalance : null;
        final isEmptyWallet = balance == null || balance == BigInt.zero;

        // Determine background color based on wallet state
        final backgroundColor = isEmptyWallet
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.tertiary;

        return SliverAppBar(
          expandedHeight: 70, // Increased height for better visibility
          collapsedHeight: 70, // Same height so no expansion/collapse
          pinned: true,
          backgroundColor: backgroundColor,
          surfaceTintColor: backgroundColor,
          // Remove app bar completely - no title, no leading
          automaticallyImplyLeading: false,
          toolbarHeight: 0, // Remove the toolbar space completely
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.only(top: 4),
              child: CompactWalletHeader(address: widget.address, showBackButton: true),
            ),
          ),
        );
      },
    );
  }
}
