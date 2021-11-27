import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
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
}

List<G1WalletsList> _parseG1Wallets(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed
      .map<G1WalletsList>((json) => G1WalletsList.fromJson(json))
      .toList();
}
