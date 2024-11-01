import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/history_view.dart';
import 'package:gecko/widgets/transaction_in_progress_tile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class HistoryQuery extends StatelessWidget {
  const HistoryQuery({super.key, required this.address, this.transactionId});
  final String address;
  final String? transactionId;

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

    return FutureBuilder<bool>(
      future: _waitForTransaction(transactionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loading();
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        return _buildTransactionContent();
      },
    );
  }

  Future<bool> _waitForTransaction(String? transactionId) async {
    if (transactionId == null) return false;
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    final completer = Completer<bool>();

    final timer = Timer.periodic(const Duration(milliseconds: 5), (timer) {
      if (sub.transactionStatus.containsKey(transactionId)) {
        timer.cancel();
        completer.complete(true);
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        timer.cancel();
        completer.complete(false);
        throw TimeoutException('The transaction has not been found after 5 seconds');
      },
    );
  }

  Widget _buildTransactionContent() {
    final duniterIndexer = Provider.of<DuniterIndexer>(homeContext, listen: false);
    final scrollController = ScrollController();
    FetchMoreOptions? opts;
    int nRepositories = 20;
    return GraphQLProvider(
      client: ValueNotifier(duniterIndexer.indexerClient),
      child: Expanded(
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
                return const Center(
                  child: CircularProgressIndicator(
                    color: orangeC,
                  ),
                );
              }
              final List transactions = result.data?["transferConnection"]["edges"];

              if (result.hasException) {
                log.e('Error Indexer: ${result.exception}');
                return Column(children: <Widget>[
                  Column(
                    children: [
                      if (transactionId != null) TransactionInProgressTule(address: address, transactionId: transactionId),
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
                      if (transactionId != null) TransactionInProgressTule(address: address, transactionId: transactionId),
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

              // Build history list
              return NotificationListener(
                  child: Builder(
                    builder: (context) => Expanded(
                      child: RefreshIndicator(
                        color: orangeC,
                        onRefresh: () async => refetch!.call(),
                        child: ListView(
                          key: keyListTransactions,
                          controller: scrollController,
                          children: <Widget>[
                            if (transactionId != null) TransactionInProgressTule(address: address, transactionId: transactionId),
                            HistoryView(
                              result: result,
                              address: address,
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
      )),
    );
  }
}
