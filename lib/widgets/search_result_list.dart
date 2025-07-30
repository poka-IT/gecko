import 'package:durt2/durt2.dart' show WalletEntity, Durt;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';

import 'package:gecko/providers/search_provider.dart';
import 'package:gecko/screens/profile_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/widgets/search_identity_query.dart';

class SearchResult extends ConsumerWidget {
  const SearchResult({super.key, required this.avatarSize});

  final double avatarSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchText = ref.watch(searchTextProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return searchResultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return SearchIdentityQuery(name: searchText);
        } else {
          return Expanded(
            child: ListView(
              children: <Widget>[for (G1WalletsList g1Wallet in results) resultTileAddressSearch(g1Wallet, context)],
            ),
          );
        }
      },
      loading: () => const Center(child: Loading(stroke: 3, size: 30)),
      error: (error, stack) => SearchIdentityQuery(name: searchText),
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
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return ProfileViewScreen(address: g1Wallet.address, username: g1Wallet.username);
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
