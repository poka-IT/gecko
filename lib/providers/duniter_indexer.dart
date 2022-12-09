import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class DuniterIndexer extends ChangeNotifier {
  Map<String, String?> walletNameIndexer = {};
  String? fetchMoreCursor;
  Map? pageInfo;
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

Map computeHistoryView(repository, lastDateDelimiter, isDouble) {
  bool isTody = false;
  bool isYesterday = false;
  bool isThisWeek = false;
  bool isMigrationTime = false;
  String? dateDelimiter;
  DateTime now = DateTime.now();
  final bool isUdUnit = configBox.get('isUdUnit') ?? false;

  late double amount;
  late String finalAmount;
  DateTime date = repository[0];
  String dateForm;
  bool isDelimiter = true;

  if ({4, 10, 11, 12}.contains(date.month)) {
    dateForm = "${date.day} ${monthsInYear[date.month]!.substring(0, 3)}.";
  } else if ({1, 2, 7, 9}.contains(date.month)) {
    dateForm = "${date.day} ${monthsInYear[date.month]!.substring(0, 4)}.";
  } else {
    dateForm = "${date.day} ${monthsInYear[date.month]}";
  }

  final transactionDate = DateTime(date.year, date.month, date.day);
  final todayDate = DateTime(now.year, now.month, now.day);
  final yesterdayDate = DateTime(now.year, now.month, now.day - 1);

  if (transactionDate == todayDate && !isTody) {
    dateDelimiter = lastDateDelimiter = "today".tr();
    isTody = true;
  } else if (transactionDate == yesterdayDate && !isYesterday) {
    dateDelimiter = lastDateDelimiter = "yesterday".tr();
    isYesterday = true;
  } else if (weekNumber(date) == weekNumber(now) &&
      date.year == now.year &&
      transactionDate != yesterdayDate &&
      transactionDate != todayDate &&
      !isThisWeek) {
    dateDelimiter = lastDateDelimiter = "thisWeek".tr();
    isThisWeek = true;
  } else if (lastDateDelimiter != "${monthsInYear[date.month]} ${date.year}" &&
      transactionDate != todayDate &&
      transactionDate != yesterdayDate &&
      !(weekNumber(date) == weekNumber(now) && date.year == now.year)) {
    if (date.year == now.year) {
      dateDelimiter = lastDateDelimiter = monthsInYear[date.month];
    } else {
      dateDelimiter =
          lastDateDelimiter = "${monthsInYear[date.month]} ${date.year}";
    }
  } else {
    isDelimiter = false;
  }

  amount = repository[4] == 'RECEIVED' ? repository[3] : repository[3] * -1;

  if (isUdUnit) {
    amount = round(amount / balanceRatio);
    finalAmount = 'ud'.tr(args: ['$amount ']);
  } else {
    finalAmount = '$amount $currencyName';
  }

  if (date.compareTo(startBlockchainTime) < 0) {
    isMigrationTime = true;
  } else {
    isMigrationTime = false;
  }

  return {
    'finalAmount': finalAmount,
    'isMigrationTime': isMigrationTime,
    'dateDelimiter': dateDelimiter ?? '',
    'isDelimiter': isDelimiter,
    'dateForm': dateForm,
  };
}

int weekNumber(DateTime date) {
  int dayOfYear = int.parse(DateFormat("D").format(date));
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

final duniterIndexer = ChangeNotifierProvider<DuniterIndexer>((ref) {
  return DuniterIndexer();
});
