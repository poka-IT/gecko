// ignore_for_file: must_be_immutable

import 'package:durt2/durt2.dart' show IdtyStatus, Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/history_query.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:provider/provider.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({required this.address, this.username, this.transactionData}) : super(key: keyActivityScreen);
  final String address;
  final String? username;
  final TransactionInProgressData? transactionData;
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late Future<WalletHeaderData> _headerDataFuture;

  @override
  void initState() {
    super.initState();
    Durt.i.storage.getOldOwnerKey(widget.address);
    _headerDataFuture = _loadWalletData();
  }

  Future<WalletHeaderData> _loadWalletData() async {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    final (idtyStatusValue, balanceResult, certData) = await (
      Durt.i.storage.getIdtyStatus(widget.address),
      Durt.i.storage.getBalance(widget.address),
      Durt.i.storage.getCertsCounter(widget.address),
    ).wait;

    final data = WalletHeaderData(
      hasIdentity: idtyStatusValue != IdtyStatus.none,
      isOwner: myWalletProvider.isOwner(widget.address),
      walletName: duniterIndexer.walletNameIndexer[widget.address],
      balance: balanceResult.transferableBalance,
      certCount: certData,
    );

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: true);

    return FutureBuilder<WalletHeaderData>(
      future: _headerDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('accountActivity'.tr())),
            body: const Center(child: CircularProgressIndicator()),
            bottomNavigationBar: const GeckoBottomAppBar(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text('accountActivity'.tr())),
            body: Center(child: Text('errorLoadingWalletData'.tr())),
            bottomNavigationBar: const GeckoBottomAppBar(),
          );
        }

        final walletData = snapshot.data!;

        return PopScope(
          onPopInvokedWithResult: (_, _) {
            duniterIndexer.refetch = duniterIndexer.transBC = null;
          },
          child: Scaffold(
            appBar: WalletAppBar(
              address: widget.address,
              currentBalance: walletData.balance,
              title: 'accountActivity'.tr(),
            ),
            body: Stack(
              children: [
                Column(
                  children: <Widget>[
                    WalletHeader(address: widget.address),
                    Expanded(
                      child: HistoryQuery(address: widget.address, transactionData: widget.transactionData),
                    ),
                  ],
                ),
                const OfflineInfo(),
              ],
            ),
            bottomNavigationBar: const GeckoBottomAppBar(),
          ),
        );
      },
    );
  }
}
