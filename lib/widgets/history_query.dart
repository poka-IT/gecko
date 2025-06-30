import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/widgets/history_view.dart';
import 'package:gecko/widgets/transaction_in_progress_tile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';

class HistoryQuery extends StatelessWidget {
  const HistoryQuery({super.key, required this.address, this.transactionData});
  final String address;
  final TransactionInProgressData? transactionData;

  @override
  Widget build(BuildContext context) {
    if (indexerEndpoint == '') {
      return Column(children: <Widget>[
        ScaledSizedBox(height: 50),
        Text(
          "noNetworkNoHistory".tr(),
          textAlign: TextAlign.center,
          style: scaledTextStyle(fontSize: 17),
        )
      ]);
    }

    final duniterIndexer = Provider.of<DuniterIndexer>(homeContext, listen: false);
    final scrollController = ScrollController();
    FetchMoreOptions? opts;
    int nRepositories = 20;
    return GraphQLProvider(
      client: ValueNotifier(duniterIndexer.indexerClient),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Query(
            options: QueryOptions(
              document: gql(getHistoryByAddressRelayQ),
              variables: <String, dynamic>{'address': address, 'first': nRepositories, 'after': null},
            ),
            builder: (QueryResult result, {fetchMore, refetch}) {
              duniterIndexer.refetch = refetch;
              if (result.isLoading && result.data == null) {
                return Center(
                  child: CircularProgressIndicator(
                    color: homeContext.colorScheme.primary,
                  ),
                );
              }
              final List transactions = result.data?["transferConnection"]["edges"];

              if (result.hasException) {
                log.e('Error Indexer: ${result.exception}');
                return Column(children: <Widget>[
                  Column(
                    children: [
                      if (transactionData != null) TransactionInProgressTule(transactionData: transactionData!),
                      ScaledSizedBox(height: 50),
                      Text(
                        "noNetworkNoHistory".tr(),
                        textAlign: TextAlign.center,
                        style: scaledTextStyle(fontSize: 17),
                      ),
                    ],
                  )
                ]);
              } else if (transactions.isEmpty) {
                return Column(children: <Widget>[
                  Column(
                    children: [
                      if (transactionData != null) TransactionInProgressTule(transactionData: transactionData!),
                      ScaledSizedBox(height: 50),
                      Text(
                        "noDataToDisplay".tr(),
                        style: scaledTextStyle(fontSize: 17),
                      ),
                    ],
                  )
                ]);
              }

              if (result.isNotLoading) {
                opts = duniterIndexer.mergeQueryResult(result, opts, address, nRepositories);
              }

              final identityConnection = result.data?["identityConnection"]["edges"] as List<dynamic>;
              String? previousAddress;

              if (identityConnection.isNotEmpty) {
                final ownerKeyChange = identityConnection[0]["node"]["ownerKeyChange"];
                if (ownerKeyChange != null) {
                  final ownerKeyChangeList = ownerKeyChange as List<dynamic>;
                  if (ownerKeyChangeList.isNotEmpty) {
                    previousAddress = ownerKeyChangeList.first["previousId"];
                  }
                }
              }

              // Build history list
              return NotificationListener(
                  child: Builder(
                    builder: (context) => Expanded(
                      child: RefreshIndicator(
                        color: context.colorScheme.primary,
                        onRefresh: () async => refetch!.call(),
                        child: ListView(
                          key: keyListTransactions,
                          controller: scrollController,
                          children: <Widget>[
                            if (transactionData != null) TransactionInProgressTule(transactionData: transactionData!),
                            HistoryView(
                              result: result,
                              address: address,
                              previousAddress: previousAddress,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  onNotification: (dynamic t) {
                    if (duniterIndexer.pageInfo == null) {
                      duniterIndexer.reload();
                    }

                    if (t is ScrollEndNotification &&
                        scrollController.position.pixels >= scrollController.position.maxScrollExtent * 0.7 &&
                        duniterIndexer.pageInfo!['hasNextPage'] &&
                        result.isNotLoading) {
                      fetchMore!(opts!);
                    }
                    return true;
                  });
            },
          ),
        ],
      ),
    );
  }
}
