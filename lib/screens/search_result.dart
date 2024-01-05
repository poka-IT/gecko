import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/search_result_list.dart';
import 'package:provider/provider.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final walletsProfilesClass =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    final avatarSize = scaleSize(37);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('researchResults'.tr()),
      bottomNavigationBar: const GeckoBottomAppBar(),
      body: SafeArea(
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ScaledSizedBox(height: 20),
                  Center(
                    child: Column(
                      children: <Widget>[
                        Text(
                          "resultsFor".tr(),
                          style: scaledTextStyle(
                              color: Colors.grey[600], fontSize: 16),
                        ),
                        Text(
                          '"${searchProvider.searchController.text}"',
                          style: scaledTextStyle(
                              fontStyle: FontStyle.italic, fontSize: 18),
                        )
                      ],
                    ),
                  ),
                  // ScaledSizedBox(height: 40),
                  // Text(
                  //   'Dans mes contacts'.tr(args: [currencyName]),
                  //   style: scaledTextStyle(fontSize: 20),
                  // ),
                  // ContactsList(
                  //     myContacts: myContacts,
                  //     avatarSize: avatarSize,
                  //     walletsProfilesClass: walletsProfilesClass,
                  //     duniterIndexer: duniterIndexer),
                  ScaledSizedBox(height: 22),
                  Text(
                    'inBlockchainResult'.tr(args: [currencyName]),
                    style: scaledTextStyle(fontSize: 16),
                  ),
                  ScaledSizedBox(height: 13),
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
