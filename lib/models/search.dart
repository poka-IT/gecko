import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/g1_wallets_list_live.dart';
import 'package:http/http.dart' as http;

class SearchProvider with ChangeNotifier {
  TextEditingController searchController = TextEditingController();
  List searchResult = [];
  final cacheDuring = 0 * 60 * 1000; //First number is minutes
  int cacheTime = 0;

  void rebuildWidget() {
    notifyListeners();
  }

  Future<List> searchBlockchain() async {
    searchResult.clear();
    int searchTime = DateTime.now().millisecondsSinceEpoch;

    if (cacheTime + cacheDuring <= searchTime) {
      g1WalletsBox.clear();
      final url = Uri.parse('https://g1-stats.axiom-team.fr/data/forbes.json');
      final response = await http.get(url);

      List<G1WalletsList> _listWallets = _parseG1Wallets(response.body);

      await g1WalletsBox.addAll(_listWallets);
      cacheTime = DateTime.now().millisecondsSinceEpoch;
    }

    g1WalletsBox.toMap().forEach((key, value) {
      if ((value.id != null &&
              value.id.username != null &&
              value.id.username.contains(searchController.text)) ||
          value.pubkey.contains(searchController.text)) {
        searchResult.add(value);
        return;
      }
    });

    return searchResult;
  }

  Future<List> searchBlockchainLive() async {
    searchResult.clear();
    int searchTime = DateTime.now().millisecondsSinceEpoch;

    if (cacheTime + cacheDuring <= searchTime) {
      g1WalletsBox.clear();
      final url = Uri.parse(
          'https://g1.librelois.fr/gva?query={%20wallets(pagination:%20{%20ord:%20ASC,%20pageSize:%20999%20})%20{%20pageInfo%20{%20hasNextPage%20endCursor%20}%20edges%20{%20node%20{%20script%20balance%20{%20amount%20base%20}%20idty%20{%20isMember%20username%20}%20}%20}%20}%20}');
      final response = await http.get(url);
      // log.d(response.body);

      G1WalletsListLive _jsonResponse =
          G1WalletsListLive.fromJson(json.decode(response.body));

      while (_jsonResponse.data.wallets.pageInfo.hasNextPage) {
        var cursor = _jsonResponse.data.wallets.pageInfo.endCursor;
        final url = Uri.parse(
            'https://g1.librelois.fr/gva?query={%20wallets(pagination:%20{%20ord:%20ASC,%20pageSize:%20999%20})%20{%20pageInfo%20{%20hasNextPage%20endCursor%20}%20edges%20{%20node%20{%20script%20balance%20{%20amount%20base%20}%20idty%20{%20isMember%20username%20}%20}%20}%20}%20}');
        final response = await http.get(url);
      }

      await configBox.put('g1WalletCache', _jsonResponse);
      cacheTime = DateTime.now().millisecondsSinceEpoch;
    }

    for (var value in configBox.get('g1WalletCache').data.wallets.edges) {
      if ((value.node.idty != null &&
              value.node.idty.username != null &&
              value.node.idty.username.contains(searchController.text)) ||
          value.node.script.contains(searchController.text)) {
        searchResult.add(value);
      }
    }

    // log.d(configBox.get('g1WalletCache').data.wallets.edges.toString());

    return searchResult;
  }
}

List<G1WalletsList> _parseG1Wallets(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed
      .map<G1WalletsList>((json) => G1WalletsList.fromJson(json))
      .toList();
}
