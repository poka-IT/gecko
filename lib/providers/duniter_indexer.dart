import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class DuniterIndexer with ChangeNotifier {
  Map<String, String?> walletNameIndexer = {};

  void reload() {
    notifyListeners();
  }

  Future checkIndexerEndpoint() async {
    final oldEndpoint = indexerEndpoint;
    while (true) {
      await Future.delayed(const Duration(seconds: 30));
      final _client = HttpClient();
      _client.connectionTimeout = const Duration(milliseconds: 1000);
      try {
        final request = await _client.postUrl(Uri.parse(oldEndpoint));
        final response = await request.close();
        if (response.statusCode != 200) {
          log.d('INDEXER IS OFFILINE');
          indexerEndpoint = '';
        } else {
          // log.d('Indexer is online');
          indexerEndpoint = oldEndpoint;
        }
      } catch (e) {
        log.d('INDEXER IS OFFILINE');
        indexerEndpoint = '';
      }
    }
  }

  Future<String> getValidIndexerEndpoint() async {
    List _listEndpoints = await rootBundle
        .loadString('config/indexer_endpoints.json')
        .then((jsonStr) => jsonDecode(jsonStr));
    // _listEndpoints.shuffle();

    int i = 0;
    // String _endpoint = '';
    int _statusCode = 0;

    final _client = HttpClient();
    _client.connectionTimeout = const Duration(milliseconds: 1000);

    do {
      int listLenght = _listEndpoints.length;
      if (i >= listLenght) {
        log.e('NO VALID INDEXER ENDPOINT FOUND');
        indexerEndpoint = '';
        break;
      }
      log.d(
          (i + 1).toString() + 'n indexer endpoint try: ${_listEndpoints[i]}');

      if (i != 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      try {
        final request = await _client.postUrl(Uri.parse(_listEndpoints[i]));
        final response = await request.close();

        indexerEndpoint = _listEndpoints[i];
        _statusCode = response.statusCode;
        i++;
      } on TimeoutException catch (_) {
        log.e('This endpoint is timeout, next');
        _statusCode = 50;
        i++;
        continue;
      } on SocketException catch (_) {
        log.e('This endpoint is a bad endpoint, next');
        _statusCode = 70;
        i++;
        continue;
      } on Exception {
        log.e('Unknown error');
        _statusCode = 60;
        i++;
        continue;
      }
    } while (_statusCode != 200);

    log.i('INDEXER: ' + indexerEndpoint);
    return indexerEndpoint;
  }

  Widget getNameByAddress(BuildContext context, String address,
      [WalletData? wallet,
      double size = 20,
      bool canEdit = false,
      Color _color = Colors.black,
      FontWeight fontWeight = FontWeight.w400,
      FontStyle fontStyle = FontStyle.italic]) {
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    log.d('iiiiiiiiiiiiiiiiiiiiiii $indexerEndpoint');
    if (indexerEndpoint == '') {
      if (wallet == null) {
        return const SizedBox();
      } else {
        if (canEdit) {
          return _walletOptions.walletName(context, wallet, size, _color);
        } else {
          return _walletOptions.walletNameController(context, wallet, size);
        }
      }
    }

    return Query(
        options: QueryOptions(
          document: gql(
              getNameByAddressQ), // this is the query string you just created
          variables: {
            'address': address,
          },
          // pollInterval: const Duration(seconds: 10),
        ),
        builder: (QueryResult result,
            {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            return Text(result.exception.toString());
          }

          if (result.isLoading) {
            return const Text('Loading');
          }

          walletNameIndexer[address] =
              result.data?['account_by_pk']?['identity']?['name'];

          if (walletNameIndexer[address] == null) {
            if (wallet == null) {
              return const SizedBox();
            } else {
              if (canEdit) {
                return _walletOptions.walletName(context, wallet, size, _color);
              } else {
                return _walletOptions.walletNameController(
                    context, wallet, size);
              }
            }
          }

          return Text(
            _color == Colors.grey[700]!
                ? '(${walletNameIndexer[address]!})'
                : walletNameIndexer[address]!,
            style: TextStyle(
              fontSize: size,
              color: _color,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
            ),
          );
        });
  }
}
