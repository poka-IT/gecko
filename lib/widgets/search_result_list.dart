import 'package:durt2/durt2.dart' show WalletEntity, Durt;
import 'package:flutter/material.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';

import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/widgets/search_identity_query.dart';

class SearchResult extends StatelessWidget {
  const SearchResult({
    super.key,
    required this.searchProvider,
    required this.avatarSize,
    required this.walletsProfilesClass,
  });

  final SearchProvider searchProvider;
  final double avatarSize;
  final WalletsProfilesProvider walletsProfilesClass;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: searchProvider.searchAddress(),
      builder: (context, AsyncSnapshot<List?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data?.isEmpty ?? true) {
            return SearchIdentityQuery(name: searchProvider.searchController.text);
          } else {
            return Expanded(
              child: ListView(
                children: <Widget>[
                  for (G1WalletsList g1Wallet in snapshot.data ?? []) resultTileAddressSearch(g1Wallet, context),
                ],
              ),
            );
          }
        }
        return const Center(child: Loading(stroke: 3, size: 30));
      },
    );
  }

  Widget resultTileAddressSearch(G1WalletsList g1Wallet, BuildContext context) {
    return ListTile(
      key: keySearchResult(g1Wallet.address),
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.all(5),
      leading: DatapodAvatar(address: g1Wallet.address, size: avatarSize, name: g1Wallet.username),
      title: Row(
        children: <Widget>[
          Text(
            getShortPubkey(g1Wallet.address),
            style: scaledTextStyle(fontSize: 14, fontFamily: 'Monospace', fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaledSizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Balance(address: g1Wallet.address, size: 14)],
                ),
              ],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: <Widget>[
          NameByAddress(
            wallet: WalletEntity.create(address: g1Wallet.address, keyPairType: Durt.defaultKeyPairType),
            size: 14,
          ),
        ],
      ),
      dense: false,
      isThreeLine: false,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              // Remove the provider address assignment to prevent rebuilds
              // This will be handled in WalletViewScreen's initState
              return WalletViewScreen(address: g1Wallet.address, username: g1Wallet.username);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Fast fade transition to reduce visual jarring
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      },
    );
  }
}
