import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/widgets/cert_tile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class CertsSent extends StatelessWidget {
  const CertsSent({Key? key, required this.address}) : super(key: key);
  final String address;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    log.d(appBarHeight);
    final windowHeight = screenHeight - appBarHeight - 200;

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
          document: gql(getCertsSent),
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
          return SizedBox(
            height: windowHeight,
            child: Expanded(
              child: ListView(
                key: keyListTransactions,
                children: <Widget>[certsView(result)],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget certsView(QueryResult result) {
    List listCerts = [];
    final List certsData = result.data!['certification'];

    for (final cert in certsData) {
      final String issuerAddress = cert['receiver']['pubkey'];
      final String issuerName = cert['receiver']['name'];
      final date = DateTime.parse(cert['created_at']);
      final dp = DateTime(date.year, date.month, date.day);
      final dateForm = '${dp.day}-${dp.month}-${dp.year}';

      listCerts.add(
          {'address': issuerAddress, 'name': issuerName, 'date': dateForm});
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
            CertTile(listCerts: listCerts),
          ]);
  }
}
