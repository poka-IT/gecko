import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/widgets/cert_tile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class CertsList extends StatelessWidget {
  const CertsList({super.key, required this.address, this.direction = CertDirection.received});
  final String address;
  final CertDirection direction;

  String formatNumber(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  @override
  Widget build(BuildContext context) {
    final indexerProvider = Provider.of<DuniterIndexer>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final windowHeight = screenHeight - appBarHeight - (isTall ? 170 : 140);

    late String gertCertsReq;
    late String certFrom;

    if (direction == CertDirection.received) {
      gertCertsReq = getCertsReceived;
      certFrom = 'issuer';
    } else {
      gertCertsReq = getCertsSent;
      certFrom = 'receiver';
    }

    return GraphQLProvider(
      client: ValueNotifier(indexerProvider.indexerClient),
      child: Query(
        options: QueryOptions(
          document: gql(gertCertsReq),
          variables: <String, dynamic>{
            'address': address,
          },
        ),
        builder: (QueryResult result, {fetchMore, refetch}) {
          if (result.isLoading || result.data == null) {
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
                style: scaledTextStyle(fontSize: 17),
              )
            ]);
          } else if (result.data?['certConnection']['edges']?.isEmpty) {
            return Column(children: <Widget>[
              ScaledSizedBox(height: 50),
              Text(
                "noDataToDisplay".tr(),
                style: scaledTextStyle(fontSize: 17),
              )
            ]);
          }

          final List certsData = result.data!['certConnection']['edges'];
          List listCerts = [];
          for (final certNode in certsData) {
            final cert = certNode['node'];
            if (!cert['isActive']) {
              continue;
            }
            final String? issuerAddress = cert[certFrom]['accountId'];
            final String? issuerName = cert[certFrom]['name'];
            final date = DateTime.parse(cert['updatedIn']['block']['timestamp']);
            final dp = DateTime(date.year, date.month, date.day);

            final dateForm = '${formatNumber(dp.day)}-${formatNumber(dp.month)}-${dp.year}';

            // Check if we have a more recent certification, we skip
            if (!listCerts.any((cert) => cert['address'] == issuerAddress)) {
              listCerts.add({'address': issuerAddress, 'name': issuerName, 'date': dateForm});
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
                            style: scaledTextStyle(fontSize: 17),
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
