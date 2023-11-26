import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class SearchIdentityQuery extends StatelessWidget {
  const SearchIdentityQuery({Key? key, required this.name}) : super(key: key);
  final String name;

  @override
  Widget build(BuildContext context) {
    WalletsProfilesProvider walletsProfiles =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    if (indexerEndpoint == '') {
      return Text('noResult'.tr());
    }

    log.d(indexerEndpoint);
    final httpLink = HttpLink(
      '$indexerEndpoint/v1/graphql',
    );

    final client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(
            store: HiveStore()), // GraphQLCache(store: HiveStore())
        link: httpLink,
      ),
    );
    return GraphQLProvider(
      client: client,
      child: Query(
          options: QueryOptions(
            document: gql(
                searchAddressByNameQ), // this is the query string you just created
            variables: {
              'name': name,
            },
            // pollInterval: const Duration(seconds: 10),
          ),
          builder: (QueryResult result,
              {VoidCallback? refetch, FetchMore? fetchMore}) {
            if (kDebugMode) {
              if (result.hasException) {
                return Text(result.exception.toString());
              }
            }

            if (result.isLoading) {
              return Text('loading'.tr());
            }

            final List identities = result.data?['search_identity'] ?? [];

            if (identities.isEmpty) {
              return Text('noResult'.tr());
            }

            for (Map profile in identities) {
              duniterIndexer.walletNameIndexer
                  .putIfAbsent(profile['pubkey'], () => profile['name']);
            }

            searchProvider.resultLenght = identities.length;

            double avatarSize = 55;
            return Expanded(
              child: ListView(children: <Widget>[
                for (Map profile in identities)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ListTile(
                        key: keySearchResult(profile['pubkey']),
                        horizontalTitleGap: 40,
                        contentPadding: const EdgeInsets.all(5),
                        leading: defaultAvatar(avatarSize),
                        title: Row(children: <Widget>[
                          Text(getShortPubkey(profile['pubkey']),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Monospace',
                                  fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center),
                        ]),
                        trailing: SizedBox(
                          width: 110,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Balance(
                                          address: profile['pubkey'], size: 16),
                                    ]),
                              ]),
                        ),
                        subtitle: Row(children: <Widget>[
                          Text(profile['name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center),
                        ]),
                        dense: false,
                        isThreeLine: false,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              walletsProfiles.address = profile['pubkey'];
                              return WalletViewScreen(
                                address: profile['pubkey'],
                                username: profile['name'],
                                avatar:
                                    g1WalletsBox.get(profile['pubkey'])?.avatar,
                              );
                            }),
                          );
                        }),
                  ),
              ]),
            );
          }),
    );
  }
}
