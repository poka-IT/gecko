import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/widgets/cert_tile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class CertsList extends StatelessWidget {
  const CertsList(
      {Key? key,
      required this.address,
      this.direction = CertDirection.received})
      : super(key: key);
  final String address;
  final CertDirection direction;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final windowHeight = screenHeight - appBarHeight - (isTall ? 170 : 140);

    final httpLink = HttpLink(
      '$indexerEndpoint/v1/graphql',
    );

    late String gertCertsReq;
    late String certFrom;

    if (direction == CertDirection.received) {
      gertCertsReq = getCertsReceived;
      certFrom = 'issuer';
    } else {
      gertCertsReq = getCertsSent;
      certFrom = 'receiver';
    }

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
          document: gql(gertCertsReq),
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
              ScaledSizedBox(height: 50),
              Text(
                "noNetworkNoHistory".tr(),
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 18),
              )
            ]);
          } else if (result.data?['certification']?.isEmpty) {
            return Column(children: <Widget>[
              ScaledSizedBox(height: 50),
              Text(
                "noDataToDisplay".tr(),
                style: scaledTextStyle(fontSize: 18),
              )
            ]);
          }

          final List certsData = result.data!['certification'];
          List listCerts = [];
          for (final cert in certsData) {
            final String issuerAddress = cert[certFrom]['pubkey'];
            final String issuerName = cert[certFrom]['name'];
            final date = DateTime.parse(cert['created_at']);
            final dp = DateTime(date.year, date.month, date.day);
            final dateForm = '${dp.day}-${dp.month}-${dp.year}';

            // Check if we have a more recent certification, we skip
            if (!listCerts.any((cert) => cert['address'] == issuerAddress)) {
              listCerts.add({
                'address': issuerAddress,
                'name': issuerName,
                'date': dateForm
              });
            }
          }

          // Build history list
          return SizedBox(
            height: windowHeight,
            child: RefreshIndicator(
              color: orangeC,
              onRefresh: () async => refetch!.call(),
              child: ListView(
                key: keyListTransactions,
                children: <Widget>[
                  result.data == null
                      ? Column(children: <Widget>[
                          ScaledSizedBox(height: 50),
                          Text(
                            "noTransactionToDisplay".tr(),
                            style: scaledTextStyle(fontSize: 18),
                          )
                        ])
                      : Column(children: <Widget>[
                          CertTile(listCerts: listCerts),
                        ])
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum CertDirection { received, sent }
