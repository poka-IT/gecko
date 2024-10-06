import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class DuniterIndexer with ChangeNotifier {
  Map<String, String?> walletNameIndexer = {};
  String? fetchMoreCursor;
  Map? pageInfo;
  List? transBC;
  List listIndexerEndpoints = [];
  bool isLoadingIndexer = false;
  Future<QueryResult<Object?>?> Function()? refetch;
  late GraphQLClient indexerClient;

  void reload() {
    notifyListeners();
  }

  Future<bool> checkIndexerEndpoint(String endpoint) async {
    isLoadingIndexer = true;
    notifyListeners();
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 4000);
    try {
      final request = await client.postUrl(Uri.parse('https://$endpoint/v1beta1/relay'));
      final response = await request.close();
      if (response.statusCode != 200) {
        log.w('Indexer $endpoint is offline');
        indexerEndpoint = '';
        isLoadingIndexer = false;
        notifyListeners();
        return false;
      } else {
        final isSynced = await isIndexerSynced('https://$endpoint/v1/graphql');
        if (!isSynced) {
          log.e('This endpoint is not synced, next');
          return false;
        }

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
      log.w('Indexer $endpoint is offline');
      indexerEndpoint = '';
      isLoadingIndexer = false;
      notifyListeners();
      return false;
    }
  }

  Future<String> getValidIndexerEndpoint() async {
    // await configBox.delete('indexerEndpoint');

    listIndexerEndpoints = await rootBundle.loadString('config/indexer_endpoints.json').then((jsonStr) => jsonDecode(jsonStr));
    // _listEndpoints.shuffle();

    listIndexerEndpoints.add('Personnalisé');

    if (configBox.containsKey('customIndexer')) {
      return configBox.get('customIndexer');
    }

    if (configBox.containsKey('indexerEndpoint') && listIndexerEndpoints.contains(configBox.get('indexerEndpoint'))) {
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
      final listLenght = listIndexerEndpoints.length - 1;
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
        final endpointPath = 'https://${listIndexerEndpoints[i]}/v1beta1/relay';

        final request = await client.postUrl(Uri.parse(endpointPath));
        final response = await request.close();

        final isSynced = await isIndexerSynced('https://${listIndexerEndpoints[i]}/v1/graphql');

        if (!isSynced) {
          log.e('This endpoint is not synced, next');
          statusCode = 40;
          i++;
          continue;
        }

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

    log.i('Indexer: $indexerEndpoint');
    return indexerEndpoint;
  }

  Future<bool> isIndexerSynced(String endpoint) async {
    try {
      final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
      var duniterFinilizedHash = await sub.getLastFinilizedHash();
      final duniterFinilizedNumber = await sub.getBlockNumberByHash(duniterFinilizedHash);
      duniterFinilizedHash = "\\x${duniterFinilizedHash.substring(2)}";

      final indexerLink = HttpLink(endpoint);
      final iClient = GraphQLClient(
        cache: GraphQLCache(),
        link: indexerLink,
      );
      final result = await iClient.query(QueryOptions(document: gql(getBlockByHash), variables: <String, dynamic>{'hash': duniterFinilizedHash}));

      if (result.hasException || result.data == null || result.data!['block'].isEmpty) {
        log.e('Indexer is not synced: ${result.exception} -- ${result.data}');
        return false;
      }

      final indexerFinilizedNumber = result.data!['block'][0]['height'] as int;
      if (duniterFinilizedNumber != indexerFinilizedNumber) {
        log.e('Indexer is not synced');
        return false;
      }
      return true;
    } catch (e) {
      log.e('An error occured while checking indexer sync: $e');
      return false;
    }
  }

  List parseHistory(List blockchainTX, String address) {
    List transBC = [];
    int i = 0;

    for (final transactionNode in blockchainTX) {
      final transaction = transactionNode['node'];
      final direction = transaction['fromId'] != address ? 'RECEIVED' : 'SENT';

      transBC.add(i);
      transBC[i] = [];
      transBC[i].add(DateTime.parse(transaction['timestamp']));
      final amountBrut = transaction['amount'];
      final amount = removeDecimalZero(amountBrut / 100);
      if (direction == "RECEIVED") {
        transBC[i].add(transaction['fromId']);
        transBC[i].add(transaction['from']['identity']?['name'] ?? '');
      } else if (direction == "SENT") {
        transBC[i].add(transaction['toId']);
        transBC[i].add(transaction['to']['identity']?['name'] ?? '');
      }
      transBC[i].add(amount);
      transBC[i].add(direction);

      i++;
    }
    return transBC;
  }

  FetchMoreOptions? mergeQueryResult(QueryResult result, FetchMoreOptions? opts, String address, int nRepositories) {
    final List<dynamic> blockchainTX = (result.data!['transferConnection']['edges'] as List<dynamic>);

    pageInfo = result.data!['transferConnection']['pageInfo'];
    fetchMoreCursor = pageInfo!['endCursor'];
    // final hasNextPage = pageInfo!['hasNextPage'];
    // log.d('endCursor: $fetchMoreCursor $hasNextPage');

    if (fetchMoreCursor != null) {
      opts = FetchMoreOptions(
        variables: {'after': fetchMoreCursor, 'first': nRepositories},
        updateQuery: (previousResultData, fetchMoreResultData) {
          final List<dynamic> repos = [
            ...previousResultData!['transferConnection']['edges'] as List<dynamic>,
            ...fetchMoreResultData!['transferConnection']['edges'] as List<dynamic>
          ];

          fetchMoreResultData['transferConnection']['edges'] = repos;
          return fetchMoreResultData;
        },
      );
    }

    if (fetchMoreCursor != null) {
      transBC = parseHistory(blockchainTX, address);
    } else {
      log.d("Activity start of $address");
    }
    return opts;
  }

  double removeDecimalZero(double n) {
    String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
    return double.parse(result);
  }

//// Manuals queries

  Future<bool> isIdtyExist(String name) async {
    final variables = <String, dynamic>{
      'name': name,
    };
    final result = await _execQuery(isIdtyExistQ, variables);
    log.d(result.data);
    return result.data?['identity']?.isNotEmpty ?? false;
  }

  Future<DateTime> getBlockStart() async {
    final result = await _execQuery(getBlockchainStartQ, {});
    if (!result.hasException) {
      startBlockchainTime = DateTime.parse(result.data!['blockConnection']['edges'][0]['node']['timestamp']);
      startBlockchainInitialized = true;
      return startBlockchainTime;
    }
    return DateTime(0, 0, 0, 0, 0);
  }

  Future<QueryResult> _execQuery(String query, Map<String, dynamic> variables) async {
    final options = QueryOptions(document: gql(query), variables: variables);

    // 5GMyvKsTNk9wDBy9jwKaX6mhSzmFFtpdK9KNnmrLoSTSuJHv

    return await indexerClient.query(options);
  }

  Stream<QueryResult> subscribeHistoryIssued(String address) {
    final variables = <String, dynamic>{
      'address': address,
    };

    final options = SubscriptionOptions(
      document: gql(subscribeHistoryIssuedQ),
      variables: variables,
    );

    return indexerClient.subscribe(options);
  }

  Map computeHistoryView(repository, String address) {
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    late double amount;
    late String finalAmount;
    final DateTime date = repository[0];

    final dateForm = "${date.day} ${monthsInYear[date.month]!.substring(0, {1, 2, 7, 9}.contains(date.month) ? 4 : 3)}";

    DateTime normalizeDate(DateTime inputDate) {
      return DateTime(inputDate.year, inputDate.month, inputDate.day);
    }

    String getDateDelimiter() {
      DateTime now = DateTime.now();
      final transactionDate = normalizeDate(date.toLocal());
      final todayDate = normalizeDate(now);
      final yesterdayDate = normalizeDate(now.subtract(const Duration(days: 1)));
      final isSameWeek = weekNumber(transactionDate) == weekNumber(now) && transactionDate.year == now.year;
      final isTodayOrYesterday = transactionDate == todayDate || transactionDate == yesterdayDate;

      if (transactionDate == todayDate) {
        return "today".tr();
      } else if (transactionDate == yesterdayDate) {
        return "yesterday".tr();
      } else if (isSameWeek && !isTodayOrYesterday) {
        return "thisWeek".tr();
      } else if (!isSameWeek && !isTodayOrYesterday) {
        if (transactionDate.year == now.year) {
          return monthsInYear[transactionDate.month]!;
        } else {
          return "${monthsInYear[transactionDate.month]} ${transactionDate.year}";
        }
      } else {
        return '';
      }
    }

    final dateDelimiter = getDateDelimiter();

    amount = repository[4] == 'RECEIVED' ? repository[3] : repository[3] * -1;

    if (isUdUnit) {
      amount = round(amount / balanceRatio);
      finalAmount = 'ud'.tr(args: ['$amount ']);
    } else {
      finalAmount = '$amount $currencyName';
    }

    bool isMigrationTime = startBlockchainInitialized && date.compareTo(startBlockchainTime) < 0;

    return {
      'finalAmount': finalAmount,
      'isMigrationTime': isMigrationTime,
      'dateDelimiter': dateDelimiter,
      'dateForm': dateForm,
    };
  }

  int weekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
