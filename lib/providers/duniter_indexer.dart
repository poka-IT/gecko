import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class DuniterIndexer with ChangeNotifier {
  Map<String, String?> walletNameIndexer = {};
  String? fetchMoreCursor;
  Map? pageInfo;
  int nPage = 1;
  int nRepositories = 20;
  List? transBC;
  List listIndexerEndpoints = [];
  bool isLoadingIndexer = false;
  Map<String, String> idtyStatusCache = {};

  void reload() {
    notifyListeners();
  }

  Future<bool> checkIndexerEndpoint(String endpoint) async {
    isLoadingIndexer = true;
    notifyListeners();
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 4000);
    try {
      final request = await client.postUrl(Uri.parse('$endpoint/v1/graphql'));
      final response = await request.close();
      if (response.statusCode != 200) {
        log.d('INDEXER IS OFFILINE');
        indexerEndpoint = '';
        isLoadingIndexer = false;
        notifyListeners();
        return false;
      } else {
        indexerEndpoint = endpoint;
        await configBox.put('indexerEndpoint', endpoint);
        // await configBox.put('customEndpoint', endpoint);
        isLoadingIndexer = false;
        notifyListeners();
        final cache = HiveStore();
        cache.reset();
        return true;
      }
    } catch (e) {
      log.d('INDEXER IS OFFILINE');
      indexerEndpoint = '';
      isLoadingIndexer = false;
      notifyListeners();
      return false;
    }
  }

  // Future checkIndexerEndpointBackground() async {
  //   final oldEndpoint = indexerEndpoint;
  //   while (true) {
  //     await Future.delayed(const Duration(seconds: 30));
  //     final isValid = await checkIndexerEndpoint(oldEndpoint);
  //     if (!isValid) {
  //       log.d('INDEXER IS OFFILINE');
  //       indexerEndpoint = '';
  //     } else {
  //       // log.d('Indexer is online');
  //       indexerEndpoint = oldEndpoint;
  //     }
  //   }
  // }

  Future<String> getValidIndexerEndpoint() async {
    // await configBox.delete('indexerEndpoint');

    listIndexerEndpoints = await rootBundle
        .loadString('config/indexer_endpoints.json')
        .then((jsonStr) => jsonDecode(jsonStr));
    // _listEndpoints.shuffle();

    log.d(listIndexerEndpoints);
    listIndexerEndpoints.add('Personnalisé');

    if (configBox.containsKey('customIndexer')) {
      return configBox.get('customIndexer');
      // listIndexerEndpoints.insert(0, configBox.get('customIndexer'));
    }

    if (configBox.containsKey('indexerEndpoint')) {
      if (await checkIndexerEndpoint(configBox.get('indexerEndpoint'))) {
        return configBox.get('indexerEndpoint');
      }
    }

    int i = 0;
    // String _endpoint = '';
    int statusCode = 0;

    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 3000);

    do {
      int listLenght = listIndexerEndpoints.length - 1;
      if (i >= listLenght) {
        log.e('NO VALID INDEXER ENDPOINT FOUND');
        indexerEndpoint = '';
        break;
      }
      log.d('${i + 1}n indexer endpoint try: ${listIndexerEndpoints[i]}');

      if (i != 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      try {
        String endpointPath = '${listIndexerEndpoints[i]}/v1/graphql';

        final request = await client.postUrl(Uri.parse(endpointPath));
        final response = await request.close();

        indexerEndpoint = listIndexerEndpoints[i];
        await configBox.put('indexerEndpoint', listIndexerEndpoints[i]);

        statusCode = response.statusCode;
        i++;
      } on TimeoutException catch (_) {
        log.e('This endpoint is timeout, next');
        statusCode = 50;
        i++;
        continue;
      } on SocketException catch (_) {
        log.e('This endpoint is a bad endpoint, next');
        statusCode = 70;
        i++;
        continue;
      } on Exception {
        log.e('Unknown error');
        statusCode = 60;
        i++;
        continue;
      }
    } while (statusCode != 200);

    log.i('INDEXER: $indexerEndpoint');
    return indexerEndpoint;
  }

  Widget searchIdentity(BuildContext context, String name) {
    // WalletOptionsProvider _walletOptions =
    //     Provider.of<WalletOptionsProvider>(context, listen: false);
    WalletsProfilesProvider walletsProfiles =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    if (indexerEndpoint == '') {
      return const Text('Aucun résultat');
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
            if (result.hasException) {
              return Text(result.exception.toString());
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              walletsProfiles.address = profile['pubkey'];
                              return WalletViewScreen(
                                address: profile['pubkey'],
                                username: name,
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

  List parseHistory(blockchainTX, pubkey) {
    var transBC = [];
    int i = 0;

    for (final trans in blockchainTX) {
      final transaction = trans['node'];
      final direction =
          transaction['issuer_pubkey'] != pubkey ? 'RECEIVED' : 'SENT';

      transBC.add(i);
      transBC[i] = [];
      transBC[i].add(DateTime.parse(transaction['created_at']));
      final amountBrut = transaction['amount'];
      final amount = removeDecimalZero(amountBrut / 100);
      if (direction == "RECEIVED") {
        transBC[i].add(transaction['issuer_pubkey']);
        transBC[i].add(transaction['issuer']['identity']?['name'] ?? '');
      } else if (direction == "SENT") {
        transBC[i].add(transaction['receiver_pubkey']);
        transBC[i].add(transaction['receiver']['identity']?['name'] ?? '');
      }
      transBC[i].add(amount);
      transBC[i].add(direction);
      // transBC[i].add(''); //transaction comment

      i++;
    }
    return transBC;
  }

  FetchMoreOptions? checkQueryResult(result, opts, pubkey) {
    final List<dynamic>? blockchainTX =
        (result.data['transaction_connection']['edges'] as List<dynamic>?);
    // final List<dynamic> mempoolTX =
    //     (result.data['txsHistoryMp']['receiving'] as List<dynamic>);

    pageInfo = result.data['transaction_connection']['pageInfo'];
    fetchMoreCursor = pageInfo!['endCursor'];
    final hasNextPage = pageInfo!['hasNextPage'];
    final hasPreviousPage = pageInfo!['hasPreviousPage'];
    if (fetchMoreCursor == null) nPage = 1;

    log.d('endCursor: $fetchMoreCursor $hasNextPage $hasPreviousPage');

    // if (nPage == 1) {
    //   nRepositories = 20;
    // } else if (nPage == 4) {
    //   nRepositories = 40;
    // }
    // // nRepositories = 10;
    nPage++;

    if (fetchMoreCursor != null) {
      opts = FetchMoreOptions(
        variables: {'cursor': fetchMoreCursor, 'number': nRepositories},
        updateQuery: (previousResultData, fetchMoreResultData) {
          final List<dynamic> repos = [
            ...previousResultData!['transaction_connection']['edges']
                as List<dynamic>,
            ...fetchMoreResultData!['transaction_connection']['edges']
                as List<dynamic>
          ];

          log.d('repos:  $previousResultData');
          log.d('repos:  $fetchMoreResultData');
          log.d('repos:  $repos');

          fetchMoreResultData['transaction_connection']['edges'] = repos;
          return fetchMoreResultData;
        },
      );
    }

    log.d(
        "###### DEBUG H Parse blockchainTX list. Cursor: $fetchMoreCursor ######");
    if (fetchMoreCursor != null) {
      transBC = parseHistory(blockchainTX, pubkey);
    } else {
      log.i("###### DEBUG H - Début de l'historique");
    }

    return opts;
  }

  double removeDecimalZero(double n) {
    String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
    return double.parse(result);
  }
}

//// Manuals queries

Future<bool> isIdtyExist(String name) async {
  final variables = <String, dynamic>{
    'name': name,
  };
  final result = await _execQuery(isIdtyExistQ, variables);
  return result.data!['identity']?.isEmpty ?? false ? false : true;
}

Future<DateTime> getBlockStart() async {
  final result = await _execQuery(getBlockchainStartQ, {});
  startBlockchainTime = DateTime.parse(result.data!['block'][0]['created_at']);
  return startBlockchainTime;
}

Future<QueryResult> _execQuery(
    String query, Map<String, dynamic> variables) async {
  final httpLink = HttpLink(
    '$indexerEndpoint/v1/graphql',
  );

  final GraphQLClient client = GraphQLClient(
    cache: GraphQLCache(),
    link: httpLink,
  );

  final QueryOptions options =
      QueryOptions(document: gql(query), variables: variables);

  return await client.query(options);
}
