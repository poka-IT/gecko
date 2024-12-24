// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/history_query.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:provider/provider.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({required this.address, this.username, this.transactionId, this.comment}) : super(key: keyActivityScreen);
  final String address;
  final String? username;
  final String? transactionId;
  final String? comment;
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    sub.getOldOwnerKey(widget.address);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: true);

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        duniterIndexer.refetch = duniterIndexer.transBC = null;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
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
                  child: HistoryQuery(
                    address: widget.address,
                    transactionId: widget.transactionId,
                    comment: widget.comment,
                  ),
                ),
              ],
            ),
            const OfflineInfo(),
          ],
        ),
        bottomNavigationBar: const GeckoBottomAppBar(),
      ),
    );
  }
}
