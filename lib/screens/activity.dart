// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/header_profile.dart';
import 'package:gecko/widgets/history_query.dart';
import 'package:provider/provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({required this.address, this.username, this.transactionId})
      : super(key: keyActivityScreen);
  final String address;
  final String? username;
  final String? transactionId;
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
          appBar: AppBar(
            elevation: 0,
            toolbarHeight: scaleSize(57),
            title: Text(
              'accountActivity'.tr(),
              style: scaledTextStyle(fontSize: 17),
            ),
          ),
          bottomNavigationBar: const GeckoBottomAppBar(),
          body: Column(children: <Widget>[
            HeaderProfile(address: widget.address, username: widget.username),
            HistoryQuery(address: widget.address, transactionId: widget.transactionId),
          ])),
    );
  }
}
