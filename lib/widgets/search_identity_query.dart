import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class SearchIdentityQuery extends StatelessWidget {
  const SearchIdentityQuery({super.key, required this.name});
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

    return GraphQLProvider(
      client: ValueNotifier(duniterIndexer.indexerClient),
      child: Query(
          options: QueryOptions(
            document: gql(searchAddressByNameQ),
            variables: {
              'name': '%$name%',
            },
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

            final List identities =
                result.data?['identityConnection']['edges'] ?? [];

            if (identities.isEmpty) {
              return Text('noResult'.tr());
            }

            for (Map profile in identities) {
              duniterIndexer.walletNameIndexer.putIfAbsent(
                  profile['node']['accountId'], () => profile['node']['name']);
            }

            searchProvider.resultLenght = identities.length;

            const double avatarSize = 45;
            return Expanded(
              child: ListView(children: <Widget>[
                for (Map profile in identities)
                  ListTile(
                      key: keySearchResult(profile['node']['accountId']),
                      horizontalTitleGap: 10,
                      contentPadding: const EdgeInsets.only(right: 2),
                      leading: DatapodAvatar(
                          address: profile['node']['accountId'],
                          size: avatarSize),
                      title: Row(children: <Widget>[
                        Text(getShortPubkey(profile['node']['accountId']),
                            style: scaledTextStyle(
                                fontSize: 15,
                                fontFamily: 'Monospace',
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      ]),
                      trailing: ScaledSizedBox(
                        width: 120,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Balance(
                                        address: profile['node']['accountId'],
                                        size: 15),
                                  ]),
                            ]),
                      ),
                      subtitle: Row(children: <Widget>[
                        Text(profile['node']['name'] ?? '',
                            style: scaledTextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      ]),
                      dense: !isTall,
                      isThreeLine: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            walletsProfiles.address =
                                profile['node']['accountId'];
                            return WalletViewScreen(
                              address: profile['node']['accountId'],
                              username: profile['node']['name'],
                            );
                          }),
                        );
                      }),
              ]),
            );
          }),
    );
  }
}
