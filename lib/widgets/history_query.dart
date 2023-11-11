import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/widgets/history_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class HistoryQuery extends StatelessWidget {
  const HistoryQuery({Key? key, required this.address}) : super(key: key);
  final String address;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    final ScrollController scrollController = ScrollController();
    FetchMoreOptions? opts;

    int nPage = 1;
    int nRepositories = 20;

    if (indexerEndpoint == '') {
      return Column(children: <Widget>[
        const SizedBox(height: 50),
        Text(
          "noNetworkNoHistory".tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        )
      ]);
    }

    final httpLink = HttpLink(
      '$indexerEndpoint/v1beta1/relay',
    );

    final client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(),
        link: httpLink,
      ),
    );

    return GraphQLProvider(
      client: client,
      child: Expanded(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Query(
            options: QueryOptions(
              document: gql(getHistoryByAddressQ),
              variables: <String, dynamic>{
                'address': address,
                'number': 20,
                'cursor': null
              },
            ),
            builder: (QueryResult result, {fetchMore, refetch}) {
              if (result.isLoading && result.data == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: orangeC,
                  ),
                );
              }

              if (result.hasException) {
                log.e('Error Indexer: ${result.exception}');
                return Column(children: <Widget>[
                  const SizedBox(height: 50),
                  Text(
                    "noNetworkNoHistory".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  )
                ]);
              } else if (result
                  .data?['transaction_connection']?['edges'].isEmpty) {
                return Column(children: <Widget>[
                  const SizedBox(height: 50),
                  Text(
                    "noDataToDisplay".tr(),
                    style: const TextStyle(fontSize: 18),
                  )
                ]);
              }

              if (result.isNotLoading) {
                if (duniterIndexer.fetchMoreCursor == null) nPage = 1;

                // log.d('nPage: $nPage');

                if (nPage <= 3) {
                  nRepositories = 20;
                } else if (nPage <= 6) {
                  nRepositories = 40;
                } else if (nPage <= 12) {
                  nRepositories = 80;
                } else {
                  nRepositories = 120;
                }
                nPage++;
                opts = duniterIndexer.mergeQueryResult(
                    result, opts, address, nRepositories);
              }

              // Build history list
              return NotificationListener(
                  child: Builder(
                    builder: (context) => Expanded(
                      child: ListView(
                        key: keyListTransactions,
                        controller: scrollController,
                        children: <Widget>[
                          HistoryView(
                            result: result,
                            address: address,
                          )
                        ],
                      ),
                    ),
                  ),
                  onNotification: (dynamic t) {
                    if (duniterIndexer.pageInfo == null) {
                      duniterIndexer.reload();
                    }
                    if (t is ScrollEndNotification &&
                        scrollController.position.pixels >=
                            scrollController.position.maxScrollExtent * 0.7 &&
                        duniterIndexer.pageInfo!['hasNextPage'] &&
                        result.isNotLoading) {
                      fetchMore!(opts!);
                    }
                    return true;
                  });
            },
          ),
        ],
      )),
    );
  }
}
