import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class DuniterIndexer with ChangeNotifier {
  Map<String, String?> walletNameIndexer = {};
  Map? pageInfo;

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

  Widget searchIdentity(BuildContext context, String name) {
    // WalletOptionsProvider _walletOptions =
    //     Provider.of<WalletOptionsProvider>(context, listen: false);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    WalletsProfilesProvider _walletsProfiles =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    if (indexerEndpoint == '') {
      return const Text('Aucun résultat');
    }

    return Query(
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
            return const Text('Loading');
          }

          final List identities = result.data?['search_identity'] ?? [];

          if (identities.isEmpty) {
            return const Text('Aucun résultat');
          }

          int keyID = 0;
          double _avatarSize = 55;
          return Expanded(
            child: ListView(children: <Widget>[
              for (Map profile in identities)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ListTile(
                      key: Key('searchResult${keyID++}'),
                      horizontalTitleGap: 40,
                      contentPadding: const EdgeInsets.all(5),
                      leading: _cesiumPlusProvider.defaultAvatar(_avatarSize),
                      title: Row(children: <Widget>[
                        Text(getShortPubkey(profile['id']),
                            style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Monospace',
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      ]),
                      trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [balance(context, profile['id'], 16)]),
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
                            _walletsProfiles.address = profile['id'];
                            return WalletViewScreen(
                              pubkey: profile['id'],
                              username:
                                  g1WalletsBox.get(profile['id'])?.id?.username,
                              avatar: g1WalletsBox.get(profile['id'])?.avatar,
                            );
                          }),
                        );
                      }),
                ),
            ]),
          );
        });
  }


checkHistoryResult(QueryResult<Object?> result, FetchMoreOptions options, String address) {

}

}
