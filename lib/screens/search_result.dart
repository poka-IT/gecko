import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:provider/provider.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SearchProvider searchProvider =
        Provider.of<SearchProvider>(context, listen: false);
    CesiumPlusProvider cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    WalletsProfilesProvider walletsProfilesClass =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    HomeProvider homeProvider =
        Provider.of<HomeProvider>(context, listen: false);
    DuniterIndexer duniterIndexer =
        Provider.of<DuniterIndexer>(context, listen: false);

    double avatarSize = 55;

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
      bottomNavigationBar: homeProvider.bottomAppBar(context),
      body: SafeArea(
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 30),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "resultsFor".tr(),
                        ),
                        TextSpan(
                          text: '"${searchProvider.searchController.text}"',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'inBlockchainResult'.tr(args: [currencyName]),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder(
                    future: searchProvider.searchAddress(),
                    builder: (context, AsyncSnapshot<List?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.data?.isEmpty ?? true) {
                          return duniterIndexer.searchIdentity(
                              context, searchProvider.searchController.text);

                          // const Text('Aucun résultat');
                        } else {
                          return Expanded(
                            child: ListView(children: <Widget>[
                              for (G1WalletsList g1Wallet
                                  in snapshot.data ?? [])
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: ListTile(
                                      key: keySearchResult(g1Wallet.pubkey!),
                                      horizontalTitleGap: 40,
                                      contentPadding: const EdgeInsets.all(5),
                                      leading: cesiumPlusProvider
                                          .defaultAvatar(avatarSize),
                                      title: Row(children: <Widget>[
                                        Text(getShortPubkey(g1Wallet.pubkey!),
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Monospace',
                                                fontWeight: FontWeight.w500),
                                            textAlign: TextAlign.center),
                                      ]),
                                      trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 110,
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          balance(
                                                              context,
                                                              g1Wallet.pubkey!,
                                                              16),
                                                        ]),
                                                  ]),
                                            ),
                                          ]),
                                      subtitle: Row(children: <Widget>[
                                        duniterIndexer.getNameByAddress(
                                            context, g1Wallet.pubkey!)
                                      ]),
                                      dense: false,
                                      isThreeLine: false,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) {
                                            walletsProfilesClass.address =
                                                g1Wallet.pubkey;
                                            return WalletViewScreen(
                                              address: g1Wallet.pubkey,
                                              username: g1WalletsBox
                                                  .get(g1Wallet.pubkey)
                                                  ?.id
                                                  ?.username,
                                              avatar: g1WalletsBox
                                                  .get(g1Wallet.pubkey)
                                                  ?.avatar,
                                            );
                                          }),
                                        );
                                      }),
                                ),
                            ]),
                          );
                        }
                      }
                      return Center(
                        heightFactor: 5,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          backgroundColor: yellowC,
                          color: orangeC,
                        ),
                      );
                    },
                  ),
                  // Text(
                  //   _searchProvider.searchResult.toString(),
                  // )
                ]),
          ),
          CommonElements().offlineInfo(context),
        ]),
      ),
    );
  }
}
