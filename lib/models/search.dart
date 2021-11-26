import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:http/http.dart' as http;

class SearchProvider with ChangeNotifier {
  TextEditingController searchController = TextEditingController();
  List searchResult = [];
  final cacheDuring = 60 * 60 * 1000; //First number is minutes
  int cacheTime = 0;

  void rebuildWidget() {
    notifyListeners();
  }

  Future<List> searchBlockchain() async {
    searchResult.clear();
    int searchTime = DateTime.now().millisecondsSinceEpoch;

    if (cacheTime + cacheDuring <= searchTime) {
      var url = Uri.parse('https://g1-stats.axiom-team.fr/data/forbes.json');
      var response = await http.get(url);
      // print('Response body: ${response.body}');
      List<G1WalletsList> _listWallets =
          await compute(_parseG1Wallets, response.body);

      for (G1WalletsList element in _listWallets) {
        await g1WalletsBox.put(element.pubkey, element);
      }
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

    // notifyListeners();

    // log.i(g1WalletsBox
    //     .get('1N18iwCfzLYd7u6DTKafVrzs9bPyeYTGHoc5SsLMcfv')
    //     .balance);
  }
}

List<G1WalletsList> _parseG1Wallets(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed
      .map<G1WalletsList>((json) => G1WalletsList.fromJson(json))
      .toList();
}
