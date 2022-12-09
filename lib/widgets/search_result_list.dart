import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/name_by_address.dart';

class SearchResult extends StatelessWidget {
  const SearchResult({
    Key? key,
    required this.searchProvider,
    required this.duniterIndexer,
    required this.avatarSize,
    required this.walletsProfilesClass,
  }) : super(key: key);

  final SearchProvider searchProvider;
  final DuniterIndexer duniterIndexer;
  final double avatarSize;
  final WalletsProfilesProvider walletsProfilesClass;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
                for (G1WalletsList g1Wallet in snapshot.data ?? [])
                  resultTile(g1Wallet, context),
              ]),
            );
          }
        }
        return const Center(
          heightFactor: 5,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            backgroundColor: yellowC,
            color: orangeC,
          ),
        );
      },
    );
  }

  Padding resultTile(G1WalletsList g1Wallet, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ListTile(
          key: keySearchResult(g1Wallet.address),
          horizontalTitleGap: 40,
          contentPadding: const EdgeInsets.all(5),
          leading: defaultAvatar(avatarSize),
          title: Row(children: <Widget>[
            Text(getShortPubkey(g1Wallet.address),
                style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Monospace',
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ]),
          trailing:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 110,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Balance(address: g1Wallet.address, size: 16),
                ]),
              ]),
            ),
          ]),
          subtitle: Row(children: <Widget>[
            NameByAddress(
              wallet: WalletData(address: g1Wallet.address),
            ),
          ]),
          dense: false,
          isThreeLine: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                walletsProfilesClass.address = g1Wallet.address;
                return WalletViewScreen(
                  address: g1Wallet.address,
                  username:
                      duniterIndexer.walletNameIndexer[g1Wallet.address] ?? '',
                  avatar: g1WalletsBox.get(g1Wallet.address)?.avatar,
                );
              }),
            );
          }),
    );
  }
}
