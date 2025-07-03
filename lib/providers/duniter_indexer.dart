import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/home.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/models/transaction.dart';
import 'package:gecko/services/network_config.service.dart';

class DuniterIndexer with ChangeNotifier {
  late ProviderContainer _container;
  Map<String, String?> walletNameIndexer = {};
  String? fetchMoreCursor;
  Map? pageInfo;
  List<Transaction>? transBC;
  List listIndexerEndpoints = [];
  bool isLoadingIndexer = false;
  Future<QueryResult<Object?>?> Function()? refetch;
  late GraphQLClient indexerClient;

  DuniterIndexer() {
    _container = ProviderContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

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

  bool _isValidIndexerList(dynamic endpoints) {
    if (endpoints == null) return false;
    if (endpoints is! List) return false;
    if (endpoints.isEmpty) return false;
    return endpoints.every((e) => e is String);
  }

  Future<List<String>> _fetchRemoteIndexerEndpoints() async {
    try {
      final config = await NetworkConfigService.getNetworkConfig();
      if (config.squid.isEmpty) throw 'No squid endpoints found';

      // Nettoyer les URLs (retirer 'https://' et '/v1/graphql')
      return config.squid.map((url) => url.replaceAll('https://', '').replaceAll('/v1/graphql', '')).toList();
    } catch (e) {
      log.e('Erreur fetch remote indexer endpoints: $e');
      rethrow;
    }
  }

  Future<void> _updateIndexerEndpointsInBackground(List<String> currentEndpoints) async {
    try {
      final remoteEndpoints = await _fetchRemoteIndexerEndpoints();

      // Comparer les listes sans tenir compte de l'ordre
      final currentSet = Set.from(currentEndpoints);
      final remoteSet = Set.from(remoteEndpoints);

      if (!setEquals(currentSet, remoteSet)) {
        listIndexerEndpoints = remoteEndpoints;
        log.i('Indexer endpoints mis à jour en background');
      }
    } catch (e) {
      log.e('Erreur update background indexer: $e');
    }
  }

  Future<List<String>> _getBootstrapIndexerEndpoints() async {
    // 1. Vérification rapide de la configBox
    final existingEndpoints = configBox.get('squidNodes');
    if (_isValidIndexerList(existingEndpoints)) {
      // Lancer la mise à jour en background
      unawaited(_updateIndexerEndpointsInBackground(List<String>.from(existingEndpoints)));
      return List<String>.from(existingEndpoints);
    }

    try {
      // 2. Tentative de fetch distant
      final endpoints = await _fetchRemoteIndexerEndpoints();
      await configBox.put('squidNodes', endpoints);
      return endpoints;
    } catch (e) {
      // 3. Fallback sur le fichier local
      try {
        final localEndpoints = await rootBundle
            .loadString('config/indexer_endpoints.json')
            .then((jsonStr) => List<String>.from(jsonDecode(jsonStr)));

        await configBox.put('squidNodes', localEndpoints);
        return localEndpoints;
      } catch (e) {
        log.e('Erreur critique indexer endpoints: $e');
        return configBox.get('squidNodes') ?? [];
      }
    }
  }

  Future<String> getValidIndexerEndpoint() async {
    final homeProvider = old_provider.Provider.of<HomeProvider>(homeContext, listen: false);

    // Récupérer la liste des endpoints bootstrap
    listIndexerEndpoints = await _getBootstrapIndexerEndpoints();
    listIndexerEndpoints.add('Personnalisé');

    if (configBox.containsKey('customIndexer')) {
      if (await checkIndexerEndpoint(configBox.get('customIndexer'))) {
        succesConnection(indexerEndpoint);
        return indexerEndpoint;
      }
    }

    if (configBox.containsKey('indexerEndpoint') && listIndexerEndpoints.contains(configBox.get('indexerEndpoint'))) {
      if (await checkIndexerEndpoint(configBox.get('indexerEndpoint'))) {
        succesConnection(indexerEndpoint);
        return indexerEndpoint;
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

    if (indexerEndpoint == '') {
      log.e('NO VALID INDEXER ENDPOINT FOUND');
      homeProvider.changeMessage("No valid indexer found =(".tr());
      return '';
    }
    succesConnection(indexerEndpoint);

    return indexerEndpoint;
  }

  void succesConnection(String endpoint) {
    final homeProvider = old_provider.Provider.of<HomeProvider>(homeContext, listen: false);

    final wsLinkIndexer = WebSocketLink('wss://$endpoint/v1beta1/relay');

    indexerClient = GraphQLClient(cache: GraphQLCache(), link: wsLinkIndexer);

    // Indexer Blockchain start
    getBlockStart();

    homeProvider.changeMessage("Node and indexer synced !".tr(), true);
    log.i('Indexer: $indexerEndpoint');
  }

  Future<bool> isIndexerSynced(String endpoint) async {
    try {
      var duniterFinilizedHash = await _container.read(storageServiceProvider).getLastFinalizedHash();
      final duniterFinilizedNumber = await _container
          .read(storageServiceProvider)
          .getBlockNumberByHash(duniterFinilizedHash);
      duniterFinilizedHash = "\\x${duniterFinilizedHash.substring(2)}";

      final indexerLink = HttpLink(endpoint);
      final iClient = GraphQLClient(cache: GraphQLCache(), link: indexerLink);
      final result = await iClient.query(
        QueryOptions(document: gql(getBlockByHash), variables: <String, dynamic>{'hash': duniterFinilizedHash}),
      );

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

  List<Transaction> parseHistory(List blockchainTX, String address) {
    // Create a list to store Transaction objects
    List<Transaction> transactions = [];

    for (final transactionNode in blockchainTX) {
      final transaction = transactionNode['node'];
      final isReceived = transaction['fromId'] != address;

      // Calculate amount
      final amount = transaction['amount'] as int;
      final comment = transaction['comment']?['remark'] ?? '';
      final commentType = transaction['comment']?['type'] ?? '';

      // Determine counterparty based on direction
      final String counterPartyId;
      final String counterPartyName;
      if (isReceived) {
        counterPartyId = transaction['fromId'];
        counterPartyName = transaction['from']['identity']?['name'] ?? '';
      } else {
        counterPartyId = transaction['toId'];
        counterPartyName = transaction['to']['identity']?['name'] ?? '';
      }

      // Create and add new Transaction object
      transactions.add(
        Transaction(
          timestamp: DateTime.parse(transaction['timestamp']),
          address: counterPartyId,
          username: counterPartyName,
          amount: amount,
          comment: commentType == 'ASCII' || commentType == 'UNICODE' ? comment : '',
          isReceived: isReceived,
        ),
      );
    }
    return transactions;
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
            ...fetchMoreResultData!['transferConnection']['edges'] as List<dynamic>,
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

  //// Manuals queries

  Future<bool> isIdtyExist(String name) async {
    final variables = <String, dynamic>{'name': name};
    final result = await _execQuery(isIdtyExistQ, variables);
    return result.data?['identityConnection']['edges']?.isNotEmpty ?? false;
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
    final variables = <String, dynamic>{'address': address};

    final options = SubscriptionOptions(document: gql(subscribeHistoryIssuedQ), variables: variables);

    return indexerClient.subscribe(options);
  }

  Map computeHistoryView(Transaction transaction, String address) {
    final DateTime date = transaction.timestamp;

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

    final amount = BigInt.from(transaction.isReceived ? transaction.amount : transaction.amount * -1);

    bool isMigrationTime = startBlockchainInitialized && date.compareTo(startBlockchainTime) < 0;

    return {
      'finalAmount': amount,
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
