import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/search_result_list.dart';
import 'package:provider/provider.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    WalletsProfilesProvider walletsProfilesClass =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    double avatarSize = 55;
    // List<G1WalletsList> myContacts = contactsBox.toMap().values.toList();
    // myContacts = myContacts
    //     .where((map) =>
    //         (map.username ?? '').contains(searchProvider.searchController.text))
    //     .toList();

    // final  searchProvider.resultLenght.toString();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 1,
        toolbarHeight: 60 * ratio,
        title: SizedBox(
          height: 22,
          child: Text('researchResults'.tr()),
        ),
      ),
      bottomNavigationBar: const GeckoBottomAppBar(),
      body: SafeArea(
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: <Widget>[
                        Text(
                          "resultsFor".tr(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          '"${searchProvider.searchController.text}"',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 21),
                        )
                      ],
                    ),
                  ),
                  // const SizedBox(height: 40),
                  // Text(
                  //   'Dans mes contacts'.tr(args: [currencyName]),
                  //   style: const TextStyle(fontSize: 20),
                  // ),
                  // ContactsList(
                  //     myContacts: myContacts,
                  //     avatarSize: avatarSize,
                  //     walletsProfilesClass: walletsProfilesClass,
                  //     duniterIndexer: duniterIndexer),
                  const SizedBox(height: 40),
                  Text(
                    'inBlockchainResult'.tr(args: [currencyName]),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  SearchResult(
                      searchProvider: searchProvider,
                      duniterIndexer: duniterIndexer,
                      avatarSize: avatarSize,
                      walletsProfilesClass: walletsProfilesClass),
                ]),
          ),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}
