// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:flutter/material.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/header_profile.dart';
import 'package:gecko/widgets/transaction_tile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityScreen extends ConsumerWidget {
  ActivityScreen({required this.address, required this.avatar, this.username})
      : super(key: keyActivityScreen);
  final String address;
  final String? username;
  final Image avatar;

  // @override
  final ScrollController scrollController = ScrollController();

  final double avatarsSize = 80;

  FetchMore? fetchMore;

  FetchMoreOptions? opts;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 60 * ratio,
          title: SizedBox(
            height: 22,
            child: Text('accountActivity'.tr()),
          ),
        ),
        bottomNavigationBar: const GeckoBottomAppBar(),
        body: Column(children: <Widget>[
          HeaderProfile(address: address, username: username),
          historyQuery(ref),
        ]));
  }

  Widget historyQuery(WidgetRef ref) {
    final duniterIndexerW = ref.read(duniterIndexer);

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
                if (duniterIndexerW.fetchMoreCursor == null) nPage = 1;

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
                opts = duniterIndexerW.mergeQueryResult(
                    result, opts, address, nRepositories);
              }

              // Build history list
              return NotificationListener(
                  child: Builder(
                    builder: (context) => Expanded(
                      child: ListView(
                        key: keyListTransactions,
                        controller: scrollController,
                        children: <Widget>[historyView(ref, result)],
                      ),
                    ),
                  ),
                  onNotification: (dynamic t) {
                    if (t is ScrollEndNotification &&
                        scrollController.position.pixels >=
                            scrollController.position.maxScrollExtent * 0.7 &&
                        duniterIndexerW.pageInfo!['hasNextPage'] &&
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

  Widget historyView(WidgetRef ref, result) {
    final duniterIndexerW = ref.read(duniterIndexer);
    int keyID = 0;
    const double avatarSize = 200;
    String? lastDateDelimiter;
    bool? isDouble;
    bool isMigrationPassed = false;

    return duniterIndexerW.transBC == null
        ? Column(children: <Widget>[
            const SizedBox(height: 50),
            Text(
              "noTransactionToDisplay".tr(),
              style: const TextStyle(fontSize: 18),
            )
          ])
        : Column(children: <Widget>[
            Column(
                children: duniterIndexerW.transBC!.map((repository) {
              final answer =
                  computeHistoryView(repository, lastDateDelimiter, isDouble);
              isDouble = lastDateDelimiter == answer['dateDelimiter'] ||
                  answer['dateDelimiter'] == '';
              lastDateDelimiter = answer['dateDelimiter'];
              bool isMigrationTime = false;
              if (answer['isMigrationTime'] && !isMigrationPassed) {
                isMigrationPassed = true;
                isMigrationTime = true;
              }

              return Column(children: <Widget>[
                if (isMigrationTime)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'Début de la ĞDev',
                      style: TextStyle(
                          fontSize: 25,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                if (!isDouble!)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      answer['dateDelimiter'],
                      style: const TextStyle(
                          fontSize: 23,
                          color: orangeC,
                          fontWeight: FontWeight.w300),
                    ),
                  ),
                TransactionTile(
                    username: username ?? '',
                    keyID: keyID,
                    avatarSize: avatarSize,
                    repository: repository,
                    dateForm: answer['dateForm'],
                    finalAmount: answer['finalAmount'],
                    duniterIndexer: duniterIndexerW),
              ]);
            }).toList()),
            if (result.isLoading &&
                duniterIndexerW.pageInfo!['hasPreviousPage'])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  CircularProgressIndicator(),
                ],
              ),
            if (!duniterIndexerW.pageInfo!['hasNextPage'])
              Column(
                children: const <Widget>[
                  SizedBox(height: 15),
                  Text("Début de l'historique.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20)),
                  SizedBox(height: 15)
                ],
              )
          ]);
  }
}
