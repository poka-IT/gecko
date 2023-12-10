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

class DuniterIndexer with ChangeNotifier {
  Map<String, String?> walletNameIndexer = {};
  String? fetchMoreCursor;
  Map? pageInfo;
  List? transBC;
  List listIndexerEndpoints = [];
  bool isLoadingIndexer = false;

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
        log.w('INDEXER IS OFFLINE');
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
      log.w('INDEXER IS OFFLINE');
      indexerEndpoint = '';
      isLoadingIndexer = false;
      notifyListeners();
      return false;
    }
  }

  Future<String> getValidIndexerEndpoint() async {
    // await configBox.delete('indexerEndpoint');

    listIndexerEndpoints = await rootBundle
        .loadString('config/indexer_endpoints.json')
        .then((jsonStr) => jsonDecode(jsonStr));
    // _listEndpoints.shuffle();

    listIndexerEndpoints.add('Personnalisé');

    if (configBox.containsKey('customIndexer')) {
      return configBox.get('customIndexer');
    }

    if (configBox.containsKey('indexerEndpoint') &&
        listIndexerEndpoints.contains(configBox.get('indexerEndpoint'))) {
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
        final endpointPath = '${listIndexerEndpoints[i]}/v1/graphql';

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

    log.i('Indexer: $indexerEndpoint');
    return indexerEndpoint;
  }

  List parseHistory(blockchainTX, pubkey) {
    List transBC = [];
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

      i++;
    }
    return transBC;
  }

  FetchMoreOptions? mergeQueryResult(result, opts, pubkey, nRepositories) {
    final List<dynamic>? blockchainTX =
        (result.data['transaction_connection']['edges'] as List<dynamic>?);

    pageInfo = result.data['transaction_connection']['pageInfo'];
    fetchMoreCursor = pageInfo!['endCursor'];
    final hasNextPage = pageInfo!['hasNextPage'];
    final hasPreviousPage = pageInfo!['hasPreviousPage'];
    log.d('endCursor: $fetchMoreCursor $hasNextPage $hasPreviousPage');

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

          fetchMoreResultData['transaction_connection']['edges'] = repos;
          return fetchMoreResultData;
        },
      );
    }

    if (fetchMoreCursor != null) {
      transBC = parseHistory(blockchainTX, pubkey);
    } else {
      log.d("Activity start of $pubkey");
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
  return result.data!['identity']?.isNotEmpty ?? false;
}

Future<DateTime> getBlockStart() async {
  final result = await _execQuery(getBlockchainStartQ, {});
  if (!result.hasException) {
    startBlockchainTime =
        DateTime.parse(result.data!['block'][0]['created_at']);
    startBlockchainInitialized = true;
    return startBlockchainTime;
  }
  return DateTime(0, 0, 0, 0, 0);
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

Map computeHistoryView(repository, String address) {
  final bool isUdUnit = configBox.get('isUdUnit') ?? false;
  late double amount;
  late String finalAmount;
  final DateTime date = repository[0];

  final dateForm = "${date.day} ${monthsInYear[date.month]!.substring(0, {
        1,
        2,
        7,
        9
      }.contains(date.month) ? 4 : 3)}";

  DateTime normalizeDate(DateTime inputDate) {
    return DateTime(inputDate.year, inputDate.month, inputDate.day);
  }

  String getDateDelimiter() {
    DateTime now = DateTime.now();
    final transactionDate = normalizeDate(date.toLocal());
    final todayDate = normalizeDate(now);
    final yesterdayDate = normalizeDate(now.subtract(const Duration(days: 1)));
    final isSameWeek = weekNumber(transactionDate) == weekNumber(now) &&
        transactionDate.year == now.year;
    final isTodayOrYesterday =
        transactionDate == todayDate || transactionDate == yesterdayDate;

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

  bool isMigrationTime =
      startBlockchainInitialized && date.compareTo(startBlockchainTime) < 0;

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
