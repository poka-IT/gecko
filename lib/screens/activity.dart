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
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
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

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
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

        return Scaffold(
          appBar: WalletAppBar(
            address: widget.address,
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
        );
      },
    );
  }
}
