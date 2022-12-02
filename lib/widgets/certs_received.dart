import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class CertsReceived extends StatelessWidget {
  const CertsReceived({Key? key, required this.address}) : super(key: key);
  final String address;

  @override
  Widget build(BuildContext context) {
    final httpLink = HttpLink(
      '$indexerEndpoint/v1/graphql',
    );

    final client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(store: HiveStore()),
        link: httpLink,
      ),
    );
    return GraphQLProvider(
      client: client,
      child: Query(
        options: QueryOptions(
          document: gql(getCertsReceived),
          variables: <String, dynamic>{
            'address': address,
          },
        ),
        builder: (QueryResult result, {fetchMore, refetch}) {
          if (result.isLoading && result.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (result.hasException || result.data == null) {
            log.e('Error Indexer: ${result.exception}');
            return Column(children: <Widget>[
              const SizedBox(height: 50),
              Text(
                "noNetworkNoHistory".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              )
            ]);
          } else if (result.data?['certification']?.isEmpty) {
            return Column(children: <Widget>[
              const SizedBox(height: 50),
              Text(
                "noDataToDisplay".tr(),
                style: const TextStyle(fontSize: 18),
              )
            ]);
          }

          // Build history list
          return Expanded(
            child: ListView(
              key: keyListTransactions,
              children: <Widget>[certsView(result)],
            ),
          );
          //   ListView(
          //     key: keyCertsReceived,
          //     children: <Widget>[
          //       certsView(result),
          //     ],
          //   );
        },
      ),
    );
  }

  Widget certsView(QueryResult result) {
    List listCerts = [];
    final List certsData = result.data!['certification'];

    for (final cert in certsData) {
      log.d(cert);
      final String issuerAddress = cert['issuer']['pubkey'];
      final String issuerName = cert['issuer']['name'];
      final date = cert['created_at'];

      listCerts
          .add({'address': issuerAddress, 'name': issuerName, 'date': date});
    }

    return result.data == null
        ? Column(children: <Widget>[
            const SizedBox(height: 50),
            Text(
              "noTransactionToDisplay".tr(),
              style: const TextStyle(fontSize: 18),
            )
          ])
        : Column(children: <Widget>[
            getCertsTile(listCerts),
          ]);
  }

  Widget getCertsTile(List listCerts) {
    int keyID = 0;
    const double avatarSize = 200;

    return Column(
        children: listCerts.map((repository) {
      // log.d('bbbbbbbbbbbbbbbbbbbbbb: ' + repository.toString());

      return Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child:
              // Row(children: [Column(children: [],)],)
              ListTile(
                  key: keyTransaction(keyID++),
                  contentPadding: const EdgeInsets.only(
                      left: 20, right: 30, top: 15, bottom: 15),
                  leading: ClipOval(
                    child: defaultAvatar(avatarSize),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(getShortPubkey(repository['address']),
                        style: const TextStyle(
                            fontSize: 18, fontFamily: 'Monospace')),
                  ),
                  subtitle: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'dateForm',
                        ),
                        if (repository[2] != '')
                          TextSpan(
                            text: '  ·  ',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[550],
                            ),
                          ),
                        TextSpan(
                          text: repository['name'],
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  dense: false,
                  isThreeLine: false,
                  onTap: () {
                    Navigator.push(
                      homeContext,
                      MaterialPageRoute(builder: (context) {
                        return WalletViewScreen(address: repository['address']);
                      }),
                    );
                  }),
        ),
      ]);
    }).toList());
  }
}
