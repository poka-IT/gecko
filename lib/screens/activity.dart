// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/header_profile.dart';
import 'package:gecko/widgets/history_query.dart';
import 'package:provider/provider.dart';

class ActivityScreen extends StatelessWidget with ChangeNotifier {
  ActivityScreen({required this.address, required this.avatar, this.username})
      : super(key: keyActivityScreen);
  final String address;
  final String? username;
  final Image avatar;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: true);

    return WillPopScope(
      onWillPop: () {
        duniterIndexer.fetchMoreCursor =
            duniterIndexer.pageInfo = duniterIndexer.transBC = null;
        return Future<bool>.value(true);
      },
      child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            toolbarHeight: 60 * ratio,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  duniterIndexer.fetchMoreCursor =
                      duniterIndexer.pageInfo = duniterIndexer.transBC = null;
                  Navigator.of(context).pop();
                }),
            title: SizedBox(
              height: 22,
              child: Text('accountActivity'.tr()),
            ),
          ),
          bottomNavigationBar: const GeckoBottomAppBar(),
          body: Column(children: <Widget>[
            HeaderProfile(address: address, username: username),
            HistoryQuery(address: address),
          ])),
    );
  }
}
